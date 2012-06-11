use MooseX::Declare;

class PerlGlue::Model::UserCollection extends PerlGlue::Model::Base {

  has elements => ( is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { [] } );
  has talkIds  => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

  after BUILD {

    my $talkIn = join(',', @{$self->talkIds );
   
    my $sql = qq{
      SELECT
        u.device_id, u.device_type
      FROM users u
      INNER JOIN user_schedule s on u.id = s.user_id
      WHERE
        u.alerts_enabled = 1 AND s.talk_id IN ($talkIn) and s.alerted = 0
    };

    my $members = [];
    my $sth = $self->readDbh->runSqlCommand( $sql );
    while ( my $row = $sth->fetchrow_hashref() ) {
      push @$members, $row;
    }
    $sth->finish;

    $self->elements( $members );
  }


  method next {
    my $nextTab = shift @{$self->elements};
    return undef unless($nextId);
    my $member = new PerlGlue::User( deviceId => $nextTab->{device_id}, deviceType => $nextTab->{device_type}  );
    return $member;
  }
}
