use MooseX::Declare;

class PerlGlue::Model::MySchedule extends PerlGlue::Model::Schedule {

  has userId => ( is => 'rw', isa => 'Int' );

  override _retrieveTalksQuery( Int :$offset!, Int :$limit! ) {
    my $userId = $self->userId;
    return qq{ 
      select SQL_CALC_FOUND_ROWS t.*, a.name as author_name
      from talks t
      left join authors a on t.author_id = a.id
      inner join user_schedule sch on sch.talk_id = t.id and sch.user_id = $userId
      where t.day = ? 
      order by t.date 
      limit $offset, $limit
    };
  }

  method getTheseTalks( ArrayRef[Int] $talkIds! ) {

    my $talksIn = join(',', @$talkIds);

    my $sql = qq{
      select SQL_CALC_FOUND_ROWS t.*, a.name as author_name
      from talks t
      left join authors a on t.author_id = a.id
      inner join user_schedule sch on sch.talk_id = t.id and sch.user_id = ?
      where t.id in ($talksIn)
      order by t.date
    };

    my $sth = $self->dbh->runSqlCommand( $sql, [$self->userId] );
    my $totalRows = $self->dbh->getTotalRows;
    my $talks = [];
    while( my $row = $sth->fetchrow_hashref ) {
      push @$talks, new PerlGlue::Model::Talk( row => $row );
    }
    $sth->finish;
    return (wantarray) ? ($talks, $totalRows) : $talks;
  }
}
