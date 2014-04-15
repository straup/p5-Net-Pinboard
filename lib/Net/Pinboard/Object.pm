# $Id: Object.pm,v 1.16 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Pinboard::Object;
$Net::Pinboard::Object::VERSION = '2.0';

=head1 NAME 

Net::Pinboard::Object - base class for Net::Pinboard thingies

=head1 SYNOPSIS

 package Net::Pinboard::TunaBlaster;
 use base qw (Net::Pinboard::Object);

=head1 DESCRIPTION

Base class for Net::Pinboard thingies. You should never access this
package directly.

=cut

sub new {
        my $pkg  = shift;
        my $args = shift;

        my @keys = keys %$args;

        my $self = bless \%{$args}, $pkg;
        $self->{'__properties'} = \@keys;

        my $class = ref($self);

        foreach my $meth (@keys) {

                if (! $self->can($meth)) {

                        no strict "refs";

                        *{ $class . "::" . $meth } = sub {
                                my $instance = shift;
                                return $instance->{$meth};
                        };
                }
        }

        return $self;
}

sub as_hashref {
        my $self = shift;
        return {$self->_mk_hash()};
}

sub _mk_hash {
        my $self = shift;

        my %hash = map {
                $_ => $self->{$_};
        } @{$self->{'__properties'}};

        return %hash;
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
