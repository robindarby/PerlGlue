use MooseX::Declare;

class PerlGlue::Model::Talk extends PerlGlue::Model::Base {

  has id            => ( is => 'rw', isa => 'Int' );
  has scheduledDate => ( is => 'rw', isa => 'PerlGlue::Model::DateTime' );
  has duration      => ( is => 'rw', isa => 'Int' );
  has location      => ( is => 'rw', isa => 'Str' );
  has title         => ( is => 'rw', isa => 'Str' );
  has overview      => ( is => 'rw', isa => 'Str' );
  has rating        => ( is => 'rw', isa => 'Int' );
  has author        => ( is => 'rw', isa => 'PerlGlue::Model::Author' );
  has talkEnded     => ( is => 'rw', isa => 'Bool' );

  has row           => ( is => 'rw', isa => 'HashRef' );

  method BUILD {
    return unless($self->row);

    $self->id( $row->id );
    $self->scheduledDate( new PerlGlue::Model::DateTime( epoch => $row->{date} ) );
    $self->duration( $row->{duration} );

    # has the talk ended (i.e. duration minutes after start).
    $self->talkEnded( (($self->scheduledDate->epoch + ($self->duration * 60)) < time );
    $self->location( $row->{location} );
    $self->title( $row->{title} );
    $self->overview( $row->{overview} );
    $self->rating( $row->{rating} );
    $self->author( new PerlGlue::Model::Author( id => $row->{author_id}, name => $row->{author_name} ) ); 

    $self->row( undef );
  }

  method comment( Str :$message, Int :$userId ) {
    my $sql = qq{ insert into comments(talk_id, message, user_id) values(?,?,?) };
    $self->dbh->query( $sql, [ $self->id, $message, $userId ] );
    return wantarray ? (1, "Comment saved") : 1;
  }

  method rate( Int :$rating, Int :$userId ) {
    # can't rate until the talk is over.
    return wantarray ? (0, "Can't rate until after the talk") : 0 unless($self->talkEnded);
    # first check that this user hasn't rated this talk before.
    my $sql = qq{select * from ratings where talk_id = ? and user_id = ?);
    my $sth = $self->dbh->runSqlCommand( $sql, [$self->id, $userId] );
    if( my $row = $sth->fetchrow_hashref ) {
      return wantarray ? (0, "You have already rated this talk") : 0;
    }
    $sth->finish;
    # now we can insert the rating.
    $sql = qq{ insert into ratings(talk_id, rating, user_id) values(?,?,?) };
    $self->dbh->query( $sql, [ $self->id, $rating, $user_id );
    return wantarray ? (1, "Rating saved") : 1;
  }

  method getComments( Int :$offset, Int :$limit ) {
    my $sql = qq{select SQL_CALC_FOUND_ROWS * from comments where talk_id = ? and approved = 1};
    my $sth = $self->dbh->runSqlCommand( $sql, [$self->id] );
    my $totalRows = $self->dbh->getTotalRows;
    my $comments = [];
    while( my $row = $sth->fetchrow_hashref ) {
      push @$comments, new PerlGlue::Model::Comment( row => $row );
    }
    $sth->finish;
    return wantarray ? ($comments, $totalRows) : $comments;
  }

  method toHash {
    return  {
      date     => $self->scheduledDate->long,
      duration => $self->duration,
      location => $self->location,
      title    => $self->title,
      overview => $self->overview,
      rating   => ($self->talkEnded) ? $self->rating : 'N/A',
      author   => $self->author->name
    }
  }

}
