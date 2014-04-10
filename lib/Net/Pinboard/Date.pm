# $Id: Date.pm,v 1.14 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Pinboard::Date;
use base qw (Net::Pinboard::Object);

$Net::Pinboard::Date::VERSION = '1.13';

=head1 NAME

Net::Pinboard::Date - OOP for del.icio.us date thingies

=head1 SYNOPSIS

  use Net::Pinboard;
  my $del = Net::Pinboard->new({...});

  foreach my $dt ($del->post_per_date({...})) {

      # $dt is a Net::Pinboard::Date
      # object.

      print "$dt\n";
  }

=head1 DESCRIPTION

OOP for del.icio.us date thingies.

=head1 NOTES

=over 4

=item *

This package overrides the perl builtin I<stringify> operator and returns the value of the object's I<count> method.

=item *

It isn't really expected that you will instantiate these
objects outside of I<Net::Pinboard> itself.

=back

=cut

use overload q("") => sub { shift->count() };

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Returns a I<Net::Pinboard::Date> object. Woot!

=cut

# Defined in Net::Pinboard::Object

=head1 OBJECT METHODS

=cut

=head2 $obj->tag()

Returns a string.

=cut

# Defined in Net::Pinboard::Object

=head2 $obj->date()

Returns a date string, formatted I<YYYY-MM-DD>

=cut

# Defined in Net::Pinboard::Object

=head2 $obj->count()

Returns an int.

=cut

# Defined in Net::Pinboard::Object

=head2 $obj->as_hashref()

Return the object as a hash ref safe for serializing and re-blessing.

=cut

# Defined in Net::Pinboard::Object

=head1 VERSION

1.13

=head1 DATE

$Date: 2008/03/03 16:55:04 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<Net::Pinboard>

=head1 LICENSE

Copyright (c) 2004-2008 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
