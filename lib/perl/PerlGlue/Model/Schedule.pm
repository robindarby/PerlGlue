use MooseX::Declare;

class PerlGlue::Model::Schedule extends PerlGlue::Model::Base {

  has day   => ( is => 'rw', isa => 'PerlGlue::Model::DateTime' );

  method getTalks( Int :$offset = 0, Int :$limit = 20 ) {
    my $sql = $self->_retrieveTalksQuery( offset => $offset, limit => $limit );
    my $sth = $self->dbh->runSqlCommand( $sql, [$self->day->epochDay] );
    my $totalRows = $self->dbh->getTotalRows;
    my $talks = [];
    while( my $row = $sth->fetchrow_hashref ) {
      push @$talks, new PerlGlue::Model::Talk( row => $row );
    }
    $sth->finish;
    return wantarray ? ($talks, $totalRows) : $talks;
  }

  method _retrieveTalksQuery( Int :$offset!, Int :$limit! ) {
    return qq{ select SQL_CALC_FOUND_ROWS * from talks where day = ? order by date limit $offset, $limit};
  }
}
