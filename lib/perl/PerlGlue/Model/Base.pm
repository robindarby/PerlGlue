use MooseX::Declare;

#######################################################################################
#
# By Robin Darby - copyright MNC 2012.
#
# REVISON INFORMATION
#
#  Model base class, ensures that every model obj has language & region members.
#
#
#
#######################################################################################


class PerlGlue::Model::Base {

  use MooseX::ClassAttribute;
  use PerlGlue::Database;

  has language => ( is => 'ro', isa => 'Str', default => 'en' );
  has region   => ( is => 'ro', isa => 'Str', default => 'US' );

  has dbh      => ( is => 'rw', isa => 'PerlGlue::Database');

  method BUILD {
    return if( $self->dbh );

    $self->dbh( new PerlGlue::Database( 
      connectionStr => $ENV{DB_CONN_STR}, 
      username      => $ENV{DB_USER},
      password      => $ENV{DB_PASS}
    ));
  }
}
