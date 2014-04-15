package Net::Pinboard::Constants::Pause;
use strict;

# $Id: Pause.pm,v 1.13 2008/03/03 16:55:04 asc Exp $

=head1 NAME

Net::Pinboard::Constants::Pause - 

=head1 SYNOPSIS

 use Net::Pinboard::Constants qw (:pause)

=head1 DESCRIPTION

Constant variables for del.icio.us 

=cut

$Net::Pinboard::Constants::Pause::VERSION = '1.13';

=head1 CONSTANTS

=cut

=head2 PAUSE_ONSTATUS

Int.

=cut

use constant PAUSE_ONSTATUS => 503;

=head2 PAUSE_MAXTRIES

Int.

=cut

use constant PAUSE_MAXTRIES => 10;

=head2 PAUSE_SECONDS_OK

Float.

=cut

use constant PAUSE_SECONDS_OK => 0.75;

=head2 PAUSE_SECONDS_OK

Float.

=cut

use constant PAUSE_SECONDS_UNAVAILABLE => PAUSE_SECONDS_OK * 2;

BEGIN {
  use vars qw (@EXPORT_OK);

  @EXPORT_OK = qw (PAUSE_ONSTATUS
		   PAUSE_MAXTRIES
		   PAUSE_SECONDS_OK
		   PAUSE_SECONDS_UNAVAILABLE);
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
