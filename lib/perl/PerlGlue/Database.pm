use MooseX::Declare;

class PerlGlue::Database {
  use DBI;
  use Data::Dumper;

  has connectionStr => ( is => 'ro', isa => 'Str', required => 1 );
  has username => ( is => 'ro', isa => 'Maybe[Str]' );
  has password => ( is => 'ro', isa => 'Maybe[Str]' );

  has _dbh => ( is => 'rw' );

  method BUILD {
    my $dbh = DBI->connect($self->connectionStr, $self->username, $self->password) || die("Could not connect to SQL server");
    $self->_dbh( $dbh );
    $self->query(qq{SET character_set_client = utf8});
  }

  method query( Str $sql, $values = [] ) {
    my $sth = $self->runSqlCommand( $sql, $values);
    my $id = $sth->{'mysql_insertid'} if($sql =~/^\s*INSERT/i);
    $sth->finish;
    return $id;
  }

  method runSqlCommand( Str $sql, $values = [] )  {
    my $sth = $self->_dbh->prepare( $sql );
    unless ($sth) {
      die "Can't prepare statement: $DBI::errstr";
    }
    if(@$values) {
      unless ($sth->execute(@$values)) {
        die "Can't execute statement $sql: ".Dumper($values)." : $DBI::errstr";
      }
    }
    else {
      unless ($sth->execute()) {
        die "Can't execute statement $sql: $DBI::errstr";
      }
    }
    return $sth;
  }

  # _getTotalResults
  # Returns the number of rows matched (not returned).
  #
  method getTotalRows {
    my $sth = $self->runSqlCommand(qq{SELECT FOUND_ROWS()});
    my $rowsCnt = 0;
    if ( my $row = $sth -> fetchrow_arrayref() ) {
      $rowsCnt = $row->[0];
    }
    $sth->finish;
    return $rowsCnt;
  }

}
