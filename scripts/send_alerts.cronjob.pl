#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(lib/perl);
use Getopt::Long;
use PerlGlue::Model::UserCollection;
use PerlGlie::Model::NextTalks;

my $apnsCert = "conf/push_cert.pem";
my $apnsKey  = "conf/push_key.pem";

my $db = new PerlGlue::Database( connectionStr => 'DBI:mysql:perlglue;hostname=localhost', username => 'root', password => '' );

$ENV{DB_CONN_STR} = "DBI:mysql:perlglue;hostname=localhost";
$ENV{DB_USER}     = "root"; # yea, I know, but this is just a bit of fun :)
$ENV{DB_PASS}     = "";    # yea, I know, but this is just a bit of fun :)


# work out which talks are in 5 minutes.
my $nextTalks = PerlGlie::Model::NextTalks;
my $talks = $nextTalks->getTalks;

my $talkIds = [];
foreach my $talk (@$talks) {
  push @$talkIds, $talk->id;
}

# grab a collection of users who signed up for these talks.
my $collection = new PerlGlue::Model::UserCollection( talkIds => $talkIds );

# alert for talks.
while (my $user = $collection->next ) {
  my $schedule = $user->getSchedule( $nextTalks->day->epoch );
  $talks = $schedule->getTheseTalks( $talkIds );
  foreach my $talk (@$talks) {
    my $msg = $talk->title . " is starting soon in " . $talk->location;
    $user->sendAlert( $msg );
    #$user->flagTalkAsAlerted( $talkId );
  }
}


