use strict;

package Net::Pinboard;

$Net::Pinboard::VERSION = '2.0';

=head1 NAME

Net::Pinboard - OOP for the pinboard.in API

=head1 SYNOPSIS

  use Net::Pinboard;
  use Log::Dispatch::Screen;

  my $del = Net::Pinboard->new({user => "foo",
				 pswd => "bar"});

  foreach my $p ($del->recent_posts()) {
      print $p->description()."\n";
  } 

=head1 DESCRIPTION

OOP for the pinboard.in API

=cut

use Net::Pinboard::Constants qw (:pause :response :uri);
use Net::Pinboard::Config;

use HTTP::Request;
use LWP::UserAgent;
use URI;

use Log::Dispatch;
use Data::Dumper;

use Time::HiRes;

# All this, just to keep track
# of update/all_posts stuff...

use IO::AtomicFile;
use FileHandle;
use File::Temp;
use File::Spec;
use Date::Parse;
use English;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args || Config::Simple)

Arguments to the Net::Pinboard object may be defined in one of three ways :

=over 4

=item * As a single hash reference 

=item * As a reference to a I<Config::Simple> object

=item * As a path to a file that may be read by the I<Config::Simple>.

=back

The first option isn't going away any time soon but should be considered as
deprecated. Valid hash reference arguments are :

=over 4

=item * B<user> 

String.

Your pinboard.in username.

=item * B<pswd>

String.

=item * B<auth_token>

String.

A valid pinboard.in auth token.

=item * B<updates>

String.

The path to a directory where the timestamp for the last
update to your bookmarks can be recorded. This is used by
the I<all_posts> method to prevent abusive requests.

Default is the current user's home directory; If the home directory
can not be determined Net::Pinboard will use a temporary directory
as determined by File::Temp.

=item * B<debug>

Boolean.

Add a I<Log::Dispatch::Screen> dispatcher to log debug 
(and higher) notices. Notices will be printed to STDERR.

=back

I<Config::Simple> options are expected to be grouped in a "block"
labeled B<pinboard>. Valid options are :

=over 4

=item * B<user> 

String. I<required>

Your pinboard.in username.

=item * B<pswd>

String. I<required>

Your pinboard.in password.

=item * B<updates>

String.

The path to a directory where the timestamp for the last
update to your bookmarks can be recorded. This is used by
the I<all_posts> method to prevent abusive requests.

Default is the current user's home directory, followed by
a temporary directory as determined by File::Temp.

=item * B<xml_parser>

String.

You may specify one of three XML parsers to use to handle response
messages from the pinboard.in servers. You many want to do this if,
instead of Perl-ish objects, you want to access the raw XML and parse
it with XPath or XSLT or some other crazy moon language.

=over 4

=item * B<simple>

This uses L<XML::Simple> to parse messages. If present, all successful
API method calls will return, where applicable,  Net::Pinboard::* objects.

=item * B<libxml>

This uses L<XML::LibXML> to parse messages. If present, all successful
API method calls will return a I<XML::LibXML::Document> object.

Future releases may allow responses parsed with libxml to be returned as
Net::Pinboard::* objects.

=item * B<xpath>

This uses L<XML::XPath> to parse messages. If present, all successful
API method calls will return a I<XML::XPath> object.

Future releases may allow responses parsed with XML::XPath to be returned as
Net::Pinboard::* objects.

=back

The default value is B<simple>.

=item * B<force_xml_objects>

Boolean.

Set to true if you are using L<XML::Simple> to parse response messages
from the pinboard.in servers but want to return the object's original
data structure rather than Net::Pinboard::* objects.

Default is false.

=item * B<endpoint>

String.

Set the endpoint for all API calls.

There's no particular reason you should ever need to set this unless,
say, this module falls horribly out of date with the API itself. Anyway, 
now you can.

Default is B<https://api.pinboard.in/v1/>

=item * B<debug>

Boolean.

Add a I<Log::Dispatch::Screen> dispatcher to log debug 
(and higher) notices. Notices will be printed to STDERR.

=back

Returns a Net::Pinboard object or undef if there was a problem
creating the object.

It is also possible to set additional config options to tweak the
default settings for API call parameters and API response properties.
Please consult the POD for L<Net::Pinboard::Config> for details.

=cut

sub new {
        my $pkg  = shift;
        my $args = shift;

        my $self = {
                    '__wait'    => 0,
                    '__paused'  => 0,
                   };
        
        my $cfg = undef;

        if (ref($args) eq "Config::Simple") {
                $cfg = $args;
        }

        elsif (ref($args->{cfg}) eq "Config::Simple") {
                $cfg = $args->{cfg};
        }

        elsif (-f $args->{cfg}) {
                eval {
                        require Config::Simple;
                        $cfg = Config::Simple->new($args->{cfg});
                };

                if ($@) {
                        warn "Failed to load config $args->{cfg}, $@";
                        return;
                }
        }

        else {

                $cfg = Net::Pinboard::Config->mk_config($args);

                if (! $cfg) {
                        warn "Failed to create internal config object, $!";
                        return;
                }
        }

        Net::Pinboard::Config->merge_configs($cfg);
        $self->{'__cfg'} = $cfg;


        my $parser_cfg = $cfg->param("pinboard.xml_parser");
        my $parser_pkg = undef;

        if ($parser_cfg eq "libxml") {
                $parser_pkg = "XML::LibXML";
        }

        elsif ($parser_cfg eq "xpath") {
                $parser_pkg = "XML::XPath";
        }

        else {
                $parser_pkg = "XML::Simple";
        }
        
        eval "require $parser_pkg";

        if ($@) {
                warn "Failed to load XML parser $parser_pkg, $@";
                return;
        }

        $parser_pkg->import();

        bless $self, $pkg;

        #

        if ($self->config("pinboard.debug")) {
                require Log::Dispatch::Screen;
                $self->logger()->add(Log::Dispatch::Screen->new(name      => "debug",
                                                                min_level => "debug",
                                                                stderr    => 1));
        }

        #
        
        return $self;
}

=head1 UPDATE METHODS

=cut

=head2 $obj->update()

Returns return the time of the last update formatted as 
a W3CDTF string.

=cut

sub update {
        my $self = shift;

        my $res = $self->_execute_method("pinboard.posts.update"); 
        return ($res) ? $res->{time} : undef;
}

=head1 POST METHODS

=cut

=head2 $obj->add_post(\%args)

Makes a post to pinboard.in.

Valid arguments are :

=over 4

=item * B<url>

String. I<required>

Url for post

=item * B<description>

String.

Description for post.

=item * B<extended>

String.

Extended for post.

=item * B<tags>

String.

Space-delimited list of tags.

=item * B<dt>

String.

Datestamp for post, format "CCYY-MM-DDThh:mm:ssZ"

=item * B<shared>

Boolean. (Technically, you need to pass the string "no" but N:D will handle 
1s and 0s.)

Make the post private. Default is true.

=item * B<replace>

Boolean. (Technically, you need to pass the string "no" but N:D will handle 
1s and 0s.)

Don't replace post if given url has already been posted. Default is true.

=back

Returns true or false.

=cut

sub add_post {
    my $self = shift;
    my $args = shift;

    my $res = $self->_execute_method("pinboard.posts.add", $args);

    if (! $self->_use_rsp_parser()) {
            return $res;
    }

    return $self->_isdone($res);
}

=head2 $obj->delete_post(\%args)

Delete a post from pinboard.in.

Valid arguments are :

=over 4

=item * B<url>

String. I<required>

=back

Returns true or false.

=cut

sub delete_post {
    my $self = shift;
    my $args = shift;

    my $res = $self->_execute_method("pinboard.posts.delete", $args);

    if (! $self->_use_rsp_parser()) {
            return $res;
    }

    return $self->_isdone($res);
}

=head2 $obj->posts_per_date(\%args)

Get a list of dates with the number of posts at each date.

Valid arguments are :

=over 4

=item * B<tag>

String.

Filter by this tag.

=back

Returns a list of I<Net::Pinboard::Date> objects
when called in an array context.

Returns a I<Net::Pinboard::Iterator> object when called
in a scalar context.

=cut

sub posts_per_date {
    my $self = shift;
    my $args = shift;

    my $res = $self->_execute_method("pinboard.posts.dates", $args);

    if (! $res) {
            return;
    }

    if (! $self->_use_rsp_parser()) {
            return $res;
    }

    my $dates = $self->_getresults($res, "date");
    return $self->_buildresults("Date", $dates);
}

=head2 $obj->recent_posts(\%args)

Get a list of most recent posts, possibly filtered by tag.

Valid arguments are :

=over 4

=item * B<tag>

String.

Filter by this tag.

=item * B<count>

Int.

Number of posts to return. Default is 20; maximum is 100

=back

Returns a list of I<Net::Pinboard::Post> objects
when called in an array context.

Returns a I<Net::Pinboard::Iterator> object when called
in a scalar context.

=cut

sub recent_posts {
        my $self = shift;
        my $args = shift;
        
        my $res = $self->_execute_method("pinboard.posts.recent", $args);

        if (! $res) {
                return;
        }
        
        if (! $self->_use_rsp_parser()) {
                return $res;
        }
        
        my $posts = $self->_getresults($res, "post");
        return $self->_buildresults("Post", $posts);
}

=head2 $obj->all_posts()

Returns a list of I<Net::Pinboard::Post> objects
when called in an array context.

Returns a I<Net::Pinboard::Iterator> object when called
in a scalar context.

If no posts have been added between calls to this method,
it will return an empty list (or undef if called in a scalar
context.)

=cut

sub all_posts {
        my $self = shift;

        if (! $self->_is_updated()) {
                $self->logger()->info("posts have not changed since last call");
                return;
        }

        my $res = $self->_execute_method("pinboard.posts.all");

        if (! $res) {
                return;
        }

        if (! $self->_use_rsp_parser()) {
                return $res;
        }
        
        my $posts = $self->_getresults($res, "post");
        return $self->_buildresults("Post", $posts);
}

=head2 $obj->posts(\%args)

Get a list of posts on a given date, filtered by tag. If no 
date is supplied, most recent date will be used.

Valid arguments are :

=over 4

=item * B<tag>

String.

Filter by this tag.

=item * B<dt>

String.

Filter by this date.

=back

Returns a list of I<Net::Pinboard::Post> objects
when called in an array context.

Returns a I<Net::Pinboard::Iterator> object when called
in a scalar context.

=cut

sub posts {
        my $self = shift;
        my $args = shift;
        
        #

        my $res = $self->_execute_method("pinboard.posts.get", $args);
        
        if (! $res) {
                return;
        }
    
        if (! $self->_use_rsp_parser()) {
                return $res;
        }
        
        #
        
        my $posts = $self->_getresults($res, "post");
        return $self->_buildresults("Post", $posts);
}

=head1 TAG METHODS

=cut

=head2 $obj->tags()

Returns a list of tags.

=cut

sub tags {
        my $self = shift;

        my $res = $self->_execute_method("pinboard.tags.get");

        if (! $res) {
                return;
        }

        if (! $self->_use_rsp_parser()) {
                return $res;
        }

        #

        my $tags = $self->_getresults($res, "tag");
        return $self->_buildresults("Tag", $tags);
}

=head2 $obj->rename_tag(\%args)

Renames tags across all posts.

Valid arguments are :

=over 4

=item * B<old>

String. I<required>

Old tag

=item * B<new>

String. I<required>

New tag

=back

Returns true or false.

=cut

sub rename_tag {
        my $self = shift;
        my $args = shift;

        my $res = $self->_execute_method("pinboard.tags.rename", $args);

        if (! $self->_use_rsp_parser()) {
                return $res;
        }

        return $self->_isdone($res);
}

=head2 $obj->all_posts_for_tag(\%args)

This is a just a helper method which hides a bunch of API calls behind
a single method.

Valid arguments are :

=over 4

=item * B<tag>

String. I<required>

The tag you want to retrieve posts for.

=back

Returns a list of I<Net::Pinboard::Post> objects
when called in an array context.

Returns a I<Net::Pinboard::Iterator> object when called
in a scalar context.

=cut

sub all_posts_for_tag {
        my $self = shift;
        my $args = shift;

        if (! $self->_use_rsp_parser()) {
                $self->logger()->error("This method does not work with the XML parser settings you have chosen");
                return;
        }
        
        $args ||= {};
        
        if (! $args->{tag}) {
                $self->logger()->error("You must specify a tag");
                return;
        }

        my $it = $self->posts_per_date({tag => $args->{tag}});

        if (! $it) {
                return;
        }

        my @posts = ();

        while (my $dt = $it->next()) {

                my @links = $self->posts({tag => $args->{tag},
                                          dt  => $dt->date()});

                if (wantarray) {
                        push @posts, @links;
                }
                
                else {
                        map {
                                push @posts, $_->as_hashref();
                        } @links;
                }
        }

        if (wantarray) {
                return @posts;
        }

        return $self->_buildresults("Post", \@posts);
}

=head1 BUNDLE METHODS

=cut

=head2 $obj->bundles()

Returns a list of I<Net::Pinboard::Bundle> objects
when called in an array context.

Returns a I<Net::Pinboard::Iterator> object when called
in a scalar context.

=cut

sub bundles {
        my $self = shift;
        
        my $res = $self->_execute_method("pinboard.tags.bundles.all");

        if (! $self->_use_rsp_parser()) {
                return $res;
        }
        
        my $bundles = $self->_getresults($res, "bundle");
        $bundles    = $bundles->[0];
        
        if (ref($bundles) ne "HASH") {
                $self->logger()->error("failed to parse response");
                return;
        }

        # argh....

        my @data = ();

        if (exists($bundles->{name})) {
                @data = $bundles;
        }
        
        else {
                @data = map { 
                        {name => $_,tags => $bundles->{$_}->{'tags'} }
                } keys %$bundles;
        }
        
        #
        
        return $self->_buildresults("Bundle", \@data);
}

=head2 $obj->set_bundle(\%args)

Valid arguments are :

=over 4

=item * B<bundle> 

String. I<required>

The name of the bundle to set.

=item * B<tags>

String. I<required>

A space-separated list of tags.

=back

Returns true or false

=cut

sub set_bundle {
        my $self = shift;
        my $args = shift;
        
        my $res = $self->_execute_method("pinboard.tags.bundles.set", $args);

        if (! $self->_use_rsp_parser()) {
                return $res;
        }

        return $self->_isdone($res);
}

=head2 $obj->delete_bundle(\%args)

Valid arguments are :

=over 4

=item * B<bundle> 

String. I<required>

The name of the bundle to set

=back

Returns true or false

=cut

sub delete_bundle {
        my $self = shift;
        my $args = shift;
        
        my $res = $self->_execute_method("pinboard.tags.bundles.delete", $args); 

        if (! $self->_use_rsp_parser()) {
                return $res;
        }

        return $self->_isdone($res);
}

=head1 HELPER METHODS

=cut

=head2 $obj->logger()

Returns a Log::Dispatch object.

=cut

sub logger {
        my $self = shift;
        
        if (ref($self->{'__logger'}) ne "Log::Dispatch") {
                my $log = Log::Dispatch->new();
                $self->{'__logger'} = $log;
        }
        
        return $self->{'__logger'};    
}

=head2 $obj->config(@args)

This is just a short-cut for calling the current object's internal
Config::Simple I<param> method. You may use to it to get and set 
config parameters although they will not be saved to disk when the object
is destroyed.

=cut

sub config {
        my $self = shift;
        return $self->{'__cfg'}->param(@_);
}

=head2 $obj->username()

Returns the pinboard.in username for the current object.

=cut

sub username {
        my $self = shift;
        return $self->config("pinboard.user");
}

=head2 $obj->password()

Returns the pinboard.in password for the current object.

=cut

sub password {
        my $self = shift;
        return $self->config("pinboard.pswd");
}

=head2 $obj->auth_token()

Returns the pinboard.in authentication token for the current object.

=cut

sub auth_token {
        my $self = shift;
        return $self->config("pinboard.auth_token");
}

=head2 $object->user_agent()

This returns the objects internal LWP::UserAgent in case you need to tweak
timeouts, proxies, etc.

B<By default the UA object enables the I<proxy_env> glue.>

=cut

sub user_agent {
        my $self = shift;
        
        if (ref($self->{'__ua'}) ne "LWP::UserAgent") {
                my $ua = LWP::UserAgent->new();
                $ua->agent(sprintf("%s, %s", __PACKAGE__, $Net::Pinboard::VERSION));
                $ua->env_proxy(1);

                $self->{'__ua'} = $ua;
        }
        
        return $self->{'__ua'};
}

#
# Private methods
#

sub _read_update {
        my $self = shift;
        
        my $path = $self->_path_update();

        if (! -f $path) {
                return time();
        }

        my $fh = FileHandle->new($path);
        
        if (! $fh) {
                $self->logger()->error("unable to open '$path' for reading, $!");
                return 0;
        }
        
        my $time = $fh->getline();
        chomp $time;
        
        $fh->close();
        return $time;
}

sub _write_update {
        my $self = shift;
        my $time = shift;
        
        my $path = $self->_path_update();
        my $fh   = IO::AtomicFile->open($path,"w");
        
        if (! $fh) {
                $self->logger()->error("unable to open '$path' for writing, $!");
                return 0;
        }
        
        $fh->print($time);
        $fh->close();
        
        return 1;
}

sub _is_updated {
        my $self = shift;
        
        my $last    = $self->_read_update();
        my $current = $self->update();
        
        $self->_write_update($current);
        
        return ($last) ? (str2time($current) > str2time($last)) : 1;
}

sub _path_update {
        my $self = shift;
        
        my $file = sprintf(".pinboard.in.%s", $self->config("pinboard.user"));

        if (! $self->{'__updates'}){

                my $user_cfg = $self->config("pinboard.updates");

                if ($user_cfg) {
                        $self->{'__updates'} = $user_cfg;
                }
                
                elsif (-d (getpwuid($EUID))[7]) {
                        $self->{'__updates'} = (getpwuid($EUID))[7];
                }
                
        
                else {
                        $self->{'__updates'} = File::Temp::tempdir();
                }
        }

        my $root = $self->{'__updates'};
        return File::Spec->catfile($root, $file);
}

sub _execute_method {
        my $self = shift;
        my $meth = shift;
        my $args = shift;

        my $params = $self->_validateinput($meth, $args);

        if (! $params) {
                return 0;
        }

        $meth   =~ /[^\.]+\.(.*)$/;
        my $uri = $1;

        $uri =~ s/\./\//g;

        my $req = $self->_buildrequest($uri, $args, $params);
        my $res = $self->_sendrequest($req);

	print $req->as_string();
        return $res;
}

sub _validateinput {
        my $self  = shift;
        my $block = shift;
        my $args  = shift;

        if (! $args) {
                $args = {};
        }

        $block =~ s/\./_/g;

        my $rules = $self->config(-block => $block);

        if (! defined($rules)) {
                $self->logger()->error("Unknown error validating user input; unable to find validation rules for $block");
                return undef;
        }

        my @params = ();

        foreach my $param (keys %$rules) {

                my ($required, $type) = split(";", $rules->{$param});

                if (($required) && (! exists($args->{$param}))) {
                        $self->logger()->error("$param is a required parameter");
                        return undef;
                }

                if (($type) && ($type eq "no")) {
                        $self->_mkno($args, $param);
                }

                push @params, $param;
        }

        return \@params;
}

sub _buildrequest {
        my $self   = shift;
        my $meth   = shift;
        my $args   = shift;
        my $params = shift;

        my %query = map {
                $_ => $args->{$_}
        } grep {
                exists($args->{$_}) && $args->{$_}
        } @$params;

        my $endpoint = $self->config("pinboard.endpoint");
        my $uri      = URI->new_abs($meth, $endpoint);

	# TO DO: move all the token stuff into _authorize?
	# (20140415/straup)

	my $token = $self->auth_token();

	if ($token){
	    $query{'auth_token'} = $token;
	}

        $uri->query_form(%query);

        my $req = HTTP::Request->new(GET => $uri);

	if (! $token){
	    $self->_authorize($req);
	}

        $self->logger()->debug($req->as_string());
        return $req;
}

sub _sendrequest {
        my $self = shift;
        my $req  = shift;
        
        # check to see if we need to take
        # breather (are we pounding or are
        # we not?)
        
        while (time < $self->{'__wait'}) {
                
                my $debug_msg = sprintf("trying not to beat up on service, pause for %.2f seconds\n",
                                        PAUSE_SECONDS_OK);
                
                $self->logger()->debug($debug_msg);
                sleep(PAUSE_SECONDS_OK);
        }

        #
        # send request
        #

        my $res = $self->user_agent()->request($req);
        $self->logger()->debug($res->as_string());
        
        # check for 503 status
        
        if ($res->code() eq PAUSE_ONSTATUS) {
                
                # you are in a dark and twisty corridor
                # where all the errors look the same - 
                # just give up if we hit this ceiling
                
                $self->{'__paused'} ++;
                
                if ($self->{'__paused'} > PAUSE_MAXTRIES) {
                        
                        my $errmsg = sprintf("service returned '%d' status %d times; exiting",
                                             PAUSE_ONSTATUS,PAUSE_MAXTRIES);
                        
                        $self->logger()->error($errmsg);
                        return undef;
                }

                # check to see if the pinboard.in server
                # requests that we hold off for a set amount
                # of time - otherwise wait a little longer
                # than the last time
                
                my $retry_after = $res->header("Retry-After");
                my $debug_msg   = undef;
                
                if ($retry_after ) {
                        $debug_msg = sprintf("service unavailable, requested to retry in %d seconds",
                                             $retry_after);
                } 
                
                else {
                        $retry_after = PAUSE_SECONDS_UNAVAILABLE * $self->{'__paused'};
                        $debug_msg = sprintf("service unavailable, pause for %.2f seconds",
                                             $retry_after);
                }
                
                $self->logger()->debug($debug_msg);
                sleep($retry_after);
                
                # try, try again
                
                return $self->_sendrequest($req);
        }
        
        # (re) set internal timers
        
        $self->{'__wait'}   = time + PAUSE_SECONDS_OK;
        $self->{'__paused'} = 0;
        
        # check for any other HTTP 
        # errors
        
        if ($res->code() ne 200) {
                $self->logger()->error(join(":", $res->code(), $res->message()));
                return undef;
        }
        
        if ($res->content() =~ /^<html/) {
                $self->logger()->error("erp. returned HTML - this is wrong");
                return undef;
        }

        return $self->_parse_xml($res);
}

sub _parse_xml {
        my $self = shift;
        my $res  = shift;

        my $parser = $self->config("pinboard.xml_parser");
        my $xml    = undef;

        eval {
                if ($parser eq "libxml") {
                        my $parser = XML::LibXML->new();
                        $xml = $parser->parse_string($res->content());
                }
                
                elsif ($parser eq "xpath") {
                        $xml = XML::XPath->new(xml => $res->content());
                }
                
                else {
                        $xml = XMLin($res->content());                        
                }
        };

        if ($@) {
                $self->logger()->error("failed to parse response with $parser, $@");
                return undef;
        }

        if ($xml eq RESPONSE_ERROR) {
                $self->logger()->error($xml);
                return undef;
        }

        return $xml;
}

sub _authorize {
        my $self = shift;
        my $req  = shift;

        $req->authorization_basic($self->username(), $self->password());
}

sub _ua {
        my $self = shift;
        
        if (ref($self->{'__ua'}) ne "LWP::UserAgent") {
                my $ua = LWP::UserAgent->new();
                $ua->agent(sprintf("%s, %s", __PACKAGE__, $Net::Pinboard::VERSION));
                
                $self->{'__ua'} = $ua;
        }
        
        return $self->{'__ua'};
}

sub _getresults {
        my $self = shift;
        my $data = shift;
        my $key  = shift;
        
        if (! exists($data->{$key})) {
                return [];
        }
        
        elsif (ref($data->{ $key }) eq "ARRAY") {
                return $data->{ $key };
        }
        
        else {
                return [ $data->{ $key } ];
        }
}

sub _buildresults {
        my $self    = shift;
        my $type    = shift;
        my $results = shift;
        
        #
        
        $type =~ s/:://g;

        if ($self->config("pinboard.use_dev")) {
                # Debugging ... so much hate
                unshift @INC, "./lib";
        }

        my $fclass = join("::", __PACKAGE__, $type);
        eval "require $fclass";
        
        if ($@) {
                $self->logger()->error($@);
                return undef;
        }

        my $count = scalar(@$results);
        
        for (my $i=0; $i < $count; $i++) {
                $results->[$i] = $self->_mk_object_data($type, $results->[$i]);
        }

        if (wantarray) {
                return map { 
                        $fclass->new($_);
                } @$results;
        }
        
        require Net::Pinboard::Iterator;
        return Net::Pinboard::Iterator->new($fclass,
                                             $results);    
}

sub _mk_object_data {
        my $self    = shift;
        my $type    = shift;
        my $results = shift;

        my $block = lc($type);
        my @props = split("," , $self->config("pinboard_properties.$block"));

        my %object_data = map {
                $_ => $results->{$_};
        } @props;

        return \%object_data;
}

sub _use_rsp_parser {
        my $self = shift;

        if ($self->config("pinboard.xml_parser") ne "simple") {
                return 0;
        }

        if ($self->config("pinboard.force_xml_objects")) {
                return 0;
        }

        return 1;
}

sub _isdone {
        my $self = shift;
        my $res  = shift;

        if (! $res) {
                return 0;
        }
        
        elsif ($res eq RESPONSE_DONE) {
                return 1;
        }
        
        elsif ($res eq RESPONSE_OK) {
                return 1;
        }
        
        elsif ((ref($res) eq "HASH") &&
               (exists($res->{code})) &&
               ($res->{code} eq RESPONSE_DONE)) {
                
                return 1;
        }
        
        else {
                $self->logger()->error("Unknown data structure returned.");
                return 0;
        }
}

# This assumes the default is true (as in not "no")

sub _mkno {
        my $self = shift;
        my $args = shift;
        my $key  = shift;

        if (! exists($args->{$key})) {
                return;
        }

        if ($args->{$key}) {
                delete $args->{$key};
                return;
        }

        $args->{$key} = "no";
        return;
}

=head1 ERRORS

Errors are logged via the object's I<logger> method which returns
a I<Log::Dispatch> object. If you want to get at the errors it is
up to you to provide it with a dispatcher.

=head1 VERSION

2.0

=head1 DATE 

2014-04-15

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

https://pinboard.in/api/

=head1 NOTES

This package implements the API in its entirety as of I<DATE>.

=head1 LICENSE

Copyright (c) 2004-2014, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;

__END__
