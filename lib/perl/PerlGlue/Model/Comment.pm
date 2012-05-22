use MooseX::Declare;

class PerlGlue::Model::Comment {

  use PerlGlue::Model::DateTime;

  has id    => ( is => 'rw', isa => 'Int' );
  has date  => ( is => 'rw', isa => 'PerlGlue::Model::DateTime' );
  has body  => ( is => 'rw', isa => 'Str' );

  has row   => ( is => 'rw', isa => 'HashRef' );

  method BUILD {
    return unless $self->row;

    $self->id( $self->row->{id} );
    $self->date( new PerlGlue::Model::DateTime( epoch => $self->row->{date} ) );
    $self->body( $self->row->{body} );

    $self->row( undef );
  }

  method toHash {
    return {
      date => $self->date->ago,
      body => $self->body
    };
  }
}
