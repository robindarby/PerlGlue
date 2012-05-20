use MooseX::Declare;

class PerlGlue::Model::Comment {

  has id    => ( is => 'rw', isa => 'Int' );
  has date  => ( is => 'rw', isa => 'PerlGlue::Model::DateTime' );
  has body  => ( is => 'rw', isa => 'Str' );

  has row   => ( is => 'rw', isa => 'HashRef' );

  method BUILD {
    return unelss $self->row;

    $self->id( $row->{id} );
    $self->date( new PerlGlue::Model::DateTime( epoch => $row->{date} );
    $self->body( $row->{body} );

    $self->row( undef );
  }
}
