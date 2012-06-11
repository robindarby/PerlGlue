
use MooseX::Declare;


class PerlGlue::APNS {
  
  use Net::SSLeay qw/die_now die_if_ssl_error/;
  use Socket;
  use Encode qw(decode encode);
  use JSON::XS;
  use Data::Dumper;
  
  has message => ( is => 'rw', isa => 'Str', default => '' );
  has badge   => ( is => 'rw', isa => 'Int', default => 0 );

  has devicetoken => (
      is       => 'rw',
      isa      => 'Str',
      trigger  => sub {
          if (@_ >= 2) {
              my $dt = $_[1];
              $dt =~ s/\s//g;
              $_[0]->{devicetoken} = $dt;
          }
      }
  );

  has cert => (
      is       => 'rw',
      isa      => 'Str',
      required => 1,
  );

  has key => (
      is       => 'rw',
      isa      => 'Str',
      required => 1,
  );

  has passwd => (
      is  => 'rw',
  );

  has port => (
      is       => 'rw',
      isa      => 'Int',
      default  => 2195,
  );
  
  has sandbox => (
      is      => 'rw',
      isa     => 'Bool',
      default => 0,
  );
  
  
  method type_pem { &Net::SSLeay::FILETYPE_PEM }
  
  method _apple_serv_params {
      return sockaddr_in( $self->port, inet_aton( $self->host ) );
  }
  
  method host {
      return 'gateway.' . (($self->sandbox) ? 'sandbox.' : '') . 'push.apple.com';
  }
  
  method _message_encode {
      return encode( 'unicode', decode( 'utf8', $self->message ) );
  }
  
  method _pack_payload {
      my $jsonxs = JSON::XS->new->utf8(1)->encode({
          aps => {
              alert => $self->_message_encode,
              badge => $self->badge,
          }
      });
      $jsonxs =~ s/("badge":)"([^"]+)"/$1$2/;
      return
          chr(0)
        . pack( 'n',  32 )
        . pack( 'H*', $self->devicetoken )
        . pack( 'n',  length($jsonxs) )
        . $jsonxs;
  }
  
  method write( :$devicetoken, :$message, :$badge) {
      if ( $devicetoken ) { $self->devicetoken( $devicetoken ); }
      if ( $message )     { $self->message( $message ); }
      if ( $badge )       { $self->badge( $badge ); }
      $Net::SSLeay::trace       = 4;
      $Net::SSLeay::ssl_version = 10;
  
      Net::SSLeay::load_error_strings();
      Net::SSLeay::SSLeay_add_ssl_algorithms();
      Net::SSLeay::randomize();
  
      my $socket;
      socket( $socket, PF_INET, SOCK_STREAM, getprotobyname('tcp') )
        or die "socket: $!";
      connect( $socket, $self->_apple_serv_params ) or die "Connect: $!";
  
      my $ctx = Net::SSLeay::CTX_new() or die_now("Failed to create SSL_CTX $!.");
      Net::SSLeay::CTX_set_options( $ctx, &Net::SSLeay::OP_ALL );
      die_if_ssl_error("ssl ctx set options");
  
      Net::SSLeay::CTX_set_default_passwd_cb( $ctx, method { $self->passwd } );
      Net::SSLeay::CTX_use_RSAPrivateKey_file( $ctx, $self->key, $self->type_pem );
      die_if_ssl_error("private key");
      
      Net::SSLeay::CTX_use_certificate_file( $ctx, $self->cert, $self->type_pem );
      die_if_ssl_error("certificate");
  
      my $ssl = Net::SSLeay::new($ctx);
      Net::SSLeay::set_fd( $ssl, fileno($socket) );
      Net::SSLeay::connect($ssl) or die_now("Failed SSL connect ($!)");
      Net::SSLeay::write( $ssl, $self->_pack_payload );
      CORE::shutdown( $socket, 1 );
      Net::SSLeay::free($ssl);
      Net::SSLeay::CTX_free($ctx);
      close($socket);
  }
  
}
  
