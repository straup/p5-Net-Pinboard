package Net::Pinboard::Constants::Uri;
use strict;

# $Id: Uri.pm,v 1.11 2008/03/03 16:55:04 asc Exp $
$Net::Pinboard::Constants::Uri::VERSION = '1.13';

use URI;

=head1 NAME

Net::Pinboard::Constants::Uri - constant variables for pinboard.in URIs

=head1 SYNOPSIS

 use Net::Pinboard::Constants qw (:uri)

=head1 DESCRIPTION

Constant variables for pinboard.in URIs.

cut

=head1 CONSTANTS

=cut

=head2 URI_PINBOARD

String.

=cut

use constant URI_PINBOARD => URI->new("https://pinboard.in");

=head2 URI_API

String.

=cut

use constant URI_API => URI->new("https://api.pinboard.in/v1/"); 

BEGIN {
  use vars qw (@EXPORT_OK);

  @EXPORT_OK = qw (URI_PINBOARD
		   URI_API);
}

=head1 VERSION

2.0

=head1 DATE

2014-04-15

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<Net::Pinboard>

L<Net::Pinboard::Constants>

=head1 LICENSE

Copyright (c) 2004-2014 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
