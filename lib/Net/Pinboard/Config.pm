# $Id: Config.pm,v 1.18 2008/03/03 16:55:04 asc Exp $

package Net::Pinboard::Config;
$Net::Pinboard::Config::VERSION = '1.13';

=head1 NAME

Net::Pinboard::Config - config handler for Net::Pinboard.

=head2 SYNOPSIS

Config handler for Net::Pinboard.

=head1 DESCRIPTION

Internally, Net::Pinboard uses an "ini" style Config::Simple object to keep track of its
various settings. These include user credentials, endpoints as well as API request and
response parameters.

While there is no expectation that a user will ever need to change anything than their basic
login information, it is possible to override any of the default configuration options. If, you
know, you're in to that kind of thing.

The only caveat is that in order to override default configuaration for request and response
properties you will need to pass the Net::Pinboard object constructor a Config::Simple object
or the path to a valid "ini" style config file. (Arguments passed to the constructor as a hash
reference are assumed to be part of the default B<pinboard> configs.)

It is important to remember that these config options, and definitions, are not meant to be a
complete web services description nor do they play one on TV. They are some bare-bones glue
to allow users the ability to define their own settings in the event that this package falls out
of sync with the API or they've dreampt up some wacky project that uses Net::Pinboard.

=cut

=head1 DEFAULT CONFIGS

These are outlined in the POD for the L<Net::Pinboard> object constructor. They
are basically anything define in the B<[pinboard]> block.

Default API response configs are defined in Net::Pinboard::Constants::Config::PINBOARD_CFG_STD.

=cut

=head1 API CALL CONFIGS

API call configs are the set of allowable parameters that may be sent to pinboard.in
with a given method call along with flags to indicate whether an argument is required
or needs some special magic DWIM munging.

The basic syntax for block names is the string B<pinboard>, the lower-case name of the
API class (posts, user, etc.) followed by the lower-case name of the method all joined by
underbars.

The basic syntax for block arguments is the name of the API parameter followed by a single
string containing multiple options separated by semi-colons. As of this writing, there aren't
very many options. The first is the string B<required> if (drumroll) the parameter is required.
The only other recognized option is the string B<no> which will tell the argument parser to
DWIM if the user passes boolean true or false.

For example :

 [pinboard_posts_add]
 url="required"
 description=""
 extended=""
 tags=""
 dt=""
 shared=";no"
 replace=";no"

If a method class is nested, the syntax requires that all B</> strings be replaced by underbars.
For example B<tags/bundles/set> is defined as :
 
 [pinboard_tags_bundles_set]
 bundle="required"
 tags="required"

Default API response configs are defined in Net::Pinboard::Constants::Config::PINBOARD_CFG_API.

=cut

=head1 API RESPONSE CONFIGS

API response configs define the properties that are expected to be returned in a given
method call and mapped to object methods.

As of this writings, all properites are defined in the B<pinboard_properties> block.

The basic syntax for block arguments is the lower-case name of the Net::Pinboard object class 
followed by a comma-separated list of properties/methods. Unless already defined in their parent
package, "get" methods for each property will be automagically created.

 [pinboard_properties]
 date="tag,date,count,user"
 post="description,extended,href,time,parent,tag,others,shared"
 bundle="name,tag"
 user="name"
 subscriptions="user,tag"
 tag="tag,count"

Default API response configs are defined in Net::Pinboard::Constants::Config::PINBOARD_CFG_PROPERTIES.

=cut

use Config::Simple;
use Net::Pinboard::Constants qw (:config);

sub mk_config {
        my $pkg = shift;
        my $args = shift;

        my $cfg = Config::Simple->new(syntax => "ini");
        $cfg->set_block("pinboard", $args);

        return $cfg;
}

sub merge_configs {
        my $pkg = shift;
        my $cfg = shift;

        $pkg->merge_defaults($cfg, "pinboard", {PINBOARD_CFG_STD});
        $pkg->merge_api_parameters($cfg);
        $pkg->merge_rsp_properties($cfg);

        return 1;
}

sub merge_rsp_properties {
        my $pkg = shift;
        my $cfg = shift;

        my $defaults = {PINBOARD_CFG_PROPERTIES};
        my $block    = "pinboard_properties";

        $pkg->merge_defaults($cfg, $block, $defaults);
        return 1;
}

sub merge_api_parameters {
        my $pkg = shift;
        my $cfg = shift;

        my $defaults = {PINBOARD_CFG_API};

        foreach my $class (keys %$defaults) {

                foreach my $meth (keys %{$defaults->{$class}}) {
                        my $block = join("_", "pinboard", $class, $meth);
                        $pkg->merge_defaults($cfg, $block, $defaults->{$class}->{$meth});
                }
        }

        return 1;
}

sub merge_defaults {
        my $pkg      = shift;
        my $cfg      = shift;
        my $block    = shift;
        my $defaults = shift;

        my $input = $cfg->param(-block => $block);

        foreach my $key (keys %$defaults) {

                my $dkey = join(".", $block, $key);

                if (! exists($input->{$key})) {
                        $cfg->param($dkey, $defaults->{$key});
                }
        }

        return 1;
}

=head1 VERSION

2.0

=head1 DATE

2014-04-15

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2004-2014 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
