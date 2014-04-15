# $Id: Bundle.pm,v 1.13 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Pinboard::Bundle;
use base qw (Net::Pinboard::Object);

$Net::Pinboard::Bundle::VERSION = '2.0';

use overload q("") => sub { shift->name(); };

=head1 NAME

Net::Pinboard::Bundle - OOP for pinboard.in bundle thingies

=head1 SYNOPSIS

  use Net::Pinboard;
  my $pin = Net::Pinboard->new({...});

  foreach my $bundle ($pin->bundles()) {

      # $post is a Net::Pinboard::Bundle 
      # object.

      print "$bundle\n";
  }

=head1 DESCRIPTION

OOP for pinboard.in bundle thingies.

=head1 NOTES

=over 4

=item *

This package overrides the perl builtin I<stringify> operator and
returns the value of the object's I<name> method.

=item *

It isn't really expected that you will instantiate these
objects outside of I<Net::Pinboard> itself.

=back

=cut

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Returns a I<Net::Pinboard::Bundle> object. Woot!

=cut

# Defined in Net::Pinboard::Object

=head1 OBJECT METHODS

=cut

=head2 $obj->name()

Returns a string.

=cut

# Defined in Net::Pinboard::Object

=head2 $obj->tags()

Returns a list.

=cut

sub tags {
        my $self = shift;
        my $tags = $self->{tags};
        
        if (wantarray) {
                return (split(" ",$tags));
        }
        
        return $tags;
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
