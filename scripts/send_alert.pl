#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(lib/perl);
use Getopt::Long;
use PerlGlue::APNS;

my ($token, $msg);

GetOptions('token=s' => \$token, 'message=s' => \$msg);

my $apnsCert = "conf/push_cert.pem";
my $apnsKey  = "conf/push_key.pem";

my $apns = new PerlGlue::APNS(
  cert        => $apnsCert,
  key         => $apnsKey,
  devicetoken => $token,
  message     => $msg,
  badge       => 0
);

$apns->write;

