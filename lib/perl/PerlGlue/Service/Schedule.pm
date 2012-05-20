use MooseX::Declare;

class PerlGlue::Service::Schedule {

  use JSON::XS qw( encode_json );

  use PerlGlue::Model::DateTime;
  use PerlGlue::Model::Schedule;
  use PerlGlue::Model::User;

  method getSchedule( Int :$epochDay, Int :$offset, Int $limit ) {

    my $day = new PerlGlue::Model::DateTime( epoch => $epochDay );
    my $schedule = new PerlGlue::Model::Schedule( day => $day );
    my ($talks, $totalTalks) = $schedule->getTalks( offset => $offset, limit => $limit );
    my $json = {
      total => $totalTalks,
      results => []
    };

    foreach my $talk (@$talks) {
      push @{$json->results}, $talk->toHash;
    }

    return encode_json( $json );
  }

  method getUserSchedule( Str :$deviceId!, Str :$deviceType!, int :$epochDay, Int :$offset, Int $limit ) {

    my $user = new PerlGlue::Model::User( deviceId => $deviceId, deviceType => $deviceType );
    my ($talks, $totalTalks) = $user->getSchedule( $epochDay )->getTalks( offset => $offset, limit => $limit );
    my $json = {
      total => $totalTalks,
      results => []
    };

    foreach my $talk (@$talks) {
      push @{$json->results}, $talk->toHash;
    }

    return encode_json( $json );
  }

  method addTalkToUserSchedule( Str :$deviceId!, Str :$deviceType!, Int :$talkId! ) {

    my $user = new PerlGlue::Model::User( deviceId => $deviceId, deviceType => $deviceType );
    my $status = $user->addTalk( $talkId );
    my $json = {
      status => $status,
      message => "Talk Added to schedule"
    };

    return encode_json( $json );
  }

  method removeTalkFromUserSchedule( Str :$deviceId!, Str :$deviceType!, Int :$talkId! ) {

    my $user = new PerlGlue::Model::User( deviceId => $deviceId, deviceType => $deviceType );
    my $status = $user->removeTalk( $talkId );
    my $json = {
      status => $status,
      message => "Talk Added to schedule"
    };

    return encode_json( $json );
  }

}
