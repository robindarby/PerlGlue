use MooseX::Declare;

class PerlGlue::Model::User extends PerlGlue::Model::Base {

  use PerlGlue::Model::Talk;
  
  has id          => ( is => 'rw', isa => 'Int' );
  has deviceType  => ( is => 'rw', isa => 'Str', required => 1 );
  has deviceId    => ( is => 'ro', isa => 'Str', required => 1 );
  has deviceToken => ( is => 'rw', isa => 'Str' );

  
  method BUILD {
    # attempt to lookup the user, based on device ID.
    my $sql = qq{select * from users where device_id = ? and device_type = ?};
    my $sth = $self->dbh->runSqlCommand( $sql, [$self->deviceId, $self->deviceType] );
    if( my $row = $sth->fetchrow_hashref ) {
      $self->id( $row->{id} );
      $self->deviceToken( $row->{device_token} ) if( $row->{device_token} );
    }
    $sth->finish;
    # no ID? create a new user.
    unless( $self->id ) {
      $sql = qq{insert into users (device_id, device_type) values(?,?)};
      my $id = $self->dbh->query( $sql, [ $self->deviceId, $self->deviceType ] );
    }
  }



  method getSchedule( Int $epochDay ) {
    my $day = new PerlGlue::Model::DateTime( epoch => $epochDay );
    my $schedule = new PerlGlue::Model::MySchedule( day => $day, userId => $self->id );
    retrun $schedule;
  }

  method addTalk( Int $talkId! ) {
    my $sql = qq{ insert into user_schedule (user_id, talk_id) values(?,?)};
    $self->dbh->query( $sql, [ $self->id, $talkId ] );
    return 1;
  }

  method commentOnTalk( Int :$talkId, Str :$message ) {
    my $talk = new PerlGlue::model::Talk( id => $talkId );
    my ($status, $msg) = $talk->comment( userId => $self->id, message => $message );
    return ($status, $msg);
  }

  method rateTalk( Int :$talkId, Int :$rating ) {
    my $talk = new PerlGlue::model::Talk( id => $talkId );
    my ($status, $msg) = $talk->rate( userId => $self->id, rating => $rating );
    return ($status, $msg);
  }

}

__END__

  method removeTalk( Int $talkId! ) {
    my $sql = qq{delete from user_schedule where user_id = ? and talk_id = ?};
    $self->dbh->query( $sql, [$self->id, $talkId] );
    return 1;
  }


  method enableAlerts( Str $token ) {
    my $sql = qq{update users set device_token = ?, alerts_enabled = ? where id = ?};
    $self->dbh->query( $sql, [$token, 1, $self->id] ); 
    return 1;
  }

  method disableAlerts( Str $token ) {
    my $sql = qq{update users set alerts_enabled = ? where id = ?};
    $self->dbh->query( $sql, [0, $self->id] );
    return 1;
  }

  method sendAlert( Str $message ) {
  }

}
