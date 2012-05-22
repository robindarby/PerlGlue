use MooseX::Declare;

class PerlGlue::Service::Schedule {

  use JSON::XS qw( encode_json );
  use Readonly;

  use PerlGlue::Model::DateTime;
  use PerlGlue::Model::Schedule;
  use PerlGlue::Model::User;
  use PerlGlue::Model::Talk;

  Readonly my $COMMENTS_PER_PAGE => 5;
  Readonly my $TALKS_PER_PAGE    => 100;

  method getSchedule( Int :$epochDay, Int :$page = 0 ) {
    my $day = new PerlGlue::Model::DateTime( epoch => $epochDay );
    my $schedule = new PerlGlue::Model::Schedule( day => $day );
    
    my $offset = $page * $TALKS_PER_PAGE;
    my ($talks, $totalTalks) = $schedule->getTalks( offset => $offset, limit => $TALKS_PER_PAGE );
    my $json = {
      total => $totalTalks,
      results => []
    };

    foreach my $talk (@$talks) {
      push @{$json->results}, $talk->toHash;
    }

    return encode_json( $json );
  }

  method getTalkInfo( Int :$talkId, Int :$page = 0 ) {
    my $talk = eval { new PerlGlue::Model::Talk( id => $talkId ) };
    return undef unless( $talk );

    my $offset = $page * $COMMENTS_PER_PAGE;

    return encode_json( $talk->toHash( offset => $offset, limit => $COMMENTS_PER_PAGE ) );
  }

  method getUserSchedule( Str :$deviceId!, Str :$deviceType!, Int :$epochDay, Int :$page = 0 ) {
    my $user = new PerlGlue::Model::User( deviceId => $deviceId, deviceType => $deviceType );

    my $offset = $page * $TALKS_PER_PAGE;
    my ($talks, $totalTalks) = $user->getSchedule( $epochDay )->getTalks( offset => $offset, limit => $TALKS_PER_PAGE );
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
    my ($status, $msg) = $user->addTalk( $talkId );
    my $json = {
      status => $status,
      message => $msg
    };

    return encode_json( $json );
  }

  method commentOnTalk( Str :$deviceId!, Str :$deviceType!, Int :$talkId!, Str :$message ) {

    my $user = new PerlGlue::Model::User( deviceId => $deviceId, deviceType => $deviceType );
    my ($status, $msg) = $user->commentOnTalk( talkId => $talkId, message => $message );
    my $json = {
      status => $status,
      message => $msg
    };

    return encode_json( $json );
  }

  method rateTalk( Str :$deviceId!, Str :$deviceType!, Int :$talkId!, Int :$rating ) {

    my $user = new PerlGlue::Model::User( deviceId => $deviceId, deviceType => $deviceType );
    my $status = $user->rateTalk( talkId => $talkId, rating => $rating );
    my $json = {
      status => $status,
      message => "Rating added to talk"
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
