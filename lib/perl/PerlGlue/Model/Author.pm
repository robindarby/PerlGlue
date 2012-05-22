use MooseX::Declare;

class PerlGlue::Model::Author {

  has id   => ( is => 'rw', isa => 'Int' );
  has name => ( is => 'rw', isa => 'Str' );

  method getTalks( Int :$offset, Int :$limit ) {
  }
}
