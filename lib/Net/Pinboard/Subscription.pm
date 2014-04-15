# $Id: Subscription.pm,v 1.14 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Pinboard::Subscription;
use base qw (Net::Pinboard::Object);

$Net::Pinboard::Subscription::VERSION = '2.0';

=head1 NAME

Net::Pinboard::Subscription - OOP for pinboard.in subscription thingies

=head1 SYNOPSIS

  use Net::Pinboard;
  my $pin = Net::Pinboard->new({...});

  foreach my $sub ($pin->inbox_subscriptions()) {

      # $sub is a Net::Pinboard::Subscription
      # object.

      print "$sub\n";
  }

=head1 DESCRIPTION

OOP for pinboard.in subscription thingies.

=head1 NOTES

=over 4

=item *

This package overrides the perl builtin I<stringify> operator and returns the value of the object's I<user> method.

=item *

It isn't really expected that you will instantiate these
objects outside of I<Net::Pinboard> itself.

=back

=cut

use overload q("") => sub { shift->user() };

use Net::Pinboard::Constants qw (:uri);

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Returns a new I<Net::Pinboard::Subscription> object. Woot!

=cut

# Defined in Net::Pinboard::Object

=head1 OBJECT METHODS

=cut

=head2 $obj->user()

Returns a string.

=cut

# Defined in Net::Pinboard::Object

=head2 $obj->tag()

Returns a string.

=cut

# Defined in Net::Pinboard::Object

=head2 $obj->url()

Returns a string.

=cut

sub url {
    my $self = shift;
    return URI->new_abs(join("/", $self->user(),$self->tag()), URI_PINBOARD); 
}

=head2 $obj->as_hashref()

Return the object as a hash ref safe for serializing and re-blessing.

=cut

# Defined in Net::Pinboard::Object

=head1 VERSION

2.0

=head1 DATE

2014-04-15

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<Net::Pinboard>

=head1 LICENSE

Copyright (c) 2004-2014 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
