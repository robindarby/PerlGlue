use MooseX::Declare;

class PerlGlue::Model::Talk extends PerlGlue::Model::Base {

  use PerlGlue::Model::Author;
  use PerlGlue::Model::DateTime;
  use PerlGlue::Model::Comment;

  has id            => ( is => 'rw', isa => 'Int' );
  has scheduledDate => ( is => 'rw', isa => 'PerlGlue::Model::DateTime' );
  has duration      => ( is => 'rw', isa => 'Int' );
  has location      => ( is => 'rw', isa => 'Str' );
  has title         => ( is => 'rw', isa => 'Str' );
  has overview      => ( is => 'rw', isa => 'Str' );
  has rating        => ( is => 'rw', isa => 'Int' );
  has author        => ( is => 'rw', isa => 'Maybe[PerlGlue::Model::Author]' );
  has talkEnded     => ( is => 'rw', isa => 'Bool' );

  has row           => ( is => 'rw', isa => 'Maybe[HashRef]' );

  method BUILD {
    # build via db row (hash).
    if($self->row) {
      $self->_buildFromRow( $self->row );
      $self->row( undef );
    }
    # retrieve via talk id.
    elsif( $self->id ) {
      my $sql = qq{
        select t.*, a.name as author_name
        from talks t 
        left join authors a on t.author_id = a.id
        where t.id = ?};
      my $sth = $self->dbh->runSqlCommand( $sql, [$self->id] );
      if( my $row = $sth->fetchrow_hashref ) {
        $self->_buildFromRow( $row );
      }
      else {
        die "Talk not found : ".$self->id;
      }
      $sth->finish;
    }
  }

  method comment( Str :$message, Int :$userId ) {
    my $sql = qq{ insert into comments(talk_id, body, user_id, date) values(?,?,?,?) };
    $self->dbh->query( $sql, [ $self->id, $message, $userId, time ] );
    return wantarray ? (1, "Comment saved, but needs approval") : 1;
  }

  method rate( Int :$rating, Int :$userId ) {
    # can't rate until the talk is over.
    return wantarray ? (0, "Can't rate until after the talk") : 0 unless($self->talkEnded);
    return wantarray ? (0, "That's just not nice") : 0 if( $rating < 1 );
    # first check that this user hasn't rated this talk before.
    my $sql = qq{select * from ratings where talk_id = ? and user_id = ?};
    my $sth = $self->dbh->runSqlCommand( $sql, [$self->id, $userId] );
    if( my $row = $sth->fetchrow_hashref ) {
      return wantarray ? (0, "You have already rated this talk") : 0;
    }
    $sth->finish;
    # now we can insert the rating.
    $sql = qq{ insert into ratings(talk_id, rating, user_id) values(?,?,?) };
    $self->dbh->query( $sql, [ $self->id, $rating, $userId ] );
    return wantarray ? (1, "Rating saved") : 1;
  }

  method getComments( Int :$offset!, Int :$limit! ) {
    my $sql = qq{select SQL_CALC_FOUND_ROWS * from comments where talk_id = ? and approved = 1 order by date limit $offset, $limit};
    my $sth = $self->dbh->runSqlCommand( $sql, [$self->id] );
    my $totalRows = $self->dbh->getTotalRows;
    my $comments = [];
    while( my $row = $sth->fetchrow_hashref ) {
      push @$comments, new PerlGlue::Model::Comment( row => $row );
    }
    $sth->finish;
    return wantarray ? ($comments, $totalRows) : $comments;
  }

  method toHash( Int :$offset = 0, Int :$limit = 5 ) {
    my $comments = $self->getComments( offset => $offset, limit => $limit );
    my $commentHashList = [];
    foreach my $comment (@$comments) {
      push @$commentHashList, $comment->toHash;
    }
    my $author = ( $self->author ) ? $self->author->name : '';
    return  {
      date     => $self->scheduledDate->long,
      duration => $self->duration,
      location => $self->location,
      title    => $self->title,
      overview => $self->overview,
      rating   => ($self->talkEnded) ? $self->rating : 'N/A',
      author   => $author,
      comments => $commentHashList,
    }
  }

  method toJSON( Int :$offset = 0, Int :$limit = 5 ) {
  }

  method _buildFromRow( $row! ) {

    $self->id( $row->{id} );
    $self->scheduledDate( new PerlGlue::Model::DateTime( epoch => $row->{date} ) );
    $self->duration( $row->{duration} );
    # has the talk ended (i.e. duration minutes after start).
    $self->talkEnded( ($self->scheduledDate->epoch + ($self->duration * 60)) < time );
    $self->location( $row->{location} );
    $self->title( $row->{title} );
    $self->overview( $row->{overview} );
    $self->rating( $row->{rating} );
    $self->author( new PerlGlue::Model::Author( id => $row->{author_id}, name => $row->{author_name} ) ) if( $row->{author_name} );
  }

}
