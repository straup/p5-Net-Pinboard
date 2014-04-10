# -*-cperl-*-
# $Id: 01-load.t,v 1.4 2006/10/23 03:44:29 asc Exp $

use strict;
use Test::More;

plan tests => 15;

use_ok("Net::Pinboard");
use_ok("Net::Pinboard::Bundle");
use_ok("Net::Pinboard::Config");
use_ok("Net::Pinboard::Constants");
use_ok("Net::Pinboard::Constants::Config");
use_ok("Net::Pinboard::Constants::Pause");
use_ok("Net::Pinboard::Constants::Response");
use_ok("Net::Pinboard::Constants::Uri");
use_ok("Net::Pinboard::Date");
use_ok("Net::Pinboard::Iterator");
use_ok("Net::Pinboard::Object");
use_ok("Net::Pinboard::Post");
use_ok("Net::Pinboard::Subscription");
use_ok("Net::Pinboard::Tag");
use_ok("Net::Pinboard::User");
