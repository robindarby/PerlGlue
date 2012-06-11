use MooseX::Declare;

class PerlGlue::C2DM {

  use WWW::Curl::Easy;
  use URI::Escape;
  use Data::Dumper;

  has sender_auth_token => ( is => 'rw' );
  has email => ( is => 'ro' );
  has password => ( is => 'ro' );
  has source => ( is => 'ro');
  
  method BUILD {
    # if we have been given sender_auth_token we can just return now.
    return if(defined $self->sender_auth_token);
    
    my $curl = new WWW::Curl::Easy();

    $curl->setopt(CURLOPT_URL, "https://www.google.com/accounts/ClientLogin");
    my $postFields = 
      "accountType=" . uri_escape('HOSTED_OR_GOOGLE')
      . "&Email=" . uri_escape($self->email)
      . "&Passwd=" . uri_escape($self->password)
      . "&source=" . uri_escape($self->source)
      . "&service=" . uri_escape("ac2dm");
    
    $curl->setopt( CURLOPT_HEADER, 1);
    $curl->setopt( CURLOPT_POST, 1);
    $curl->setopt( CURLOPT_POSTFIELDS, $postFields);
    $curl->setopt( CURLOPT_FRESH_CONNECT, 1);
    $curl->setopt( CURLOPT_HTTPAUTH, CURLAUTH_ANY);
    $curl->setopt( CURLOPT_SSL_VERIFYPEER, 0);

    # A filehandle, reference to a scalar or reference to a typeglob can be used here.
    my $response_body;
    $curl->setopt(CURLOPT_WRITEDATA,\$response_body);

    my $retcode = $curl->perform;

    die "An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n" if($retcode);

    warn"\nTransfer went ok";
    my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
    # judge result and next action based on $response_code
    warn"\nReceived response: $response_body";

    die "Unable to locate auth token in response" unless( $response_body =~ /Auth=([\w|-]+)/);
    
    my $authId = $1;

    $self->sender_auth_token( $authId );
  }

  method sendMessage( Str :$token, Str :$type, HashRef :$data) {
    my $curl = new WWW::Curl::Easy();
    $curl->setopt( CURLOPT_URL, "https://android.apis.google.com/c2dm/send");
    my $headers = ['Authorization: GoogleLogin auth=' . $self->sender_auth_token ];
    $curl->setopt( CURLOPT_HTTPHEADER, $headers);
    $curl->setopt( CURLOPT_SSL_VERIFYPEER, 0);
    $curl->setopt( CURLOPT_SSL_VERIFYHOST, 0);
    $curl->setopt( CURLOPT_POST, 1);

    my $postStr = qq{registration_id=$token&collapse_key=$type};
    foreach my $key (keys %$data) {
      $postStr .= "&data.$key=".$data->{$key};
    }

    $curl->setopt( CURLOPT_POSTFIELDS, $postStr);
    my $response_body;
    $curl->setopt(CURLOPT_WRITEDATA,\$response_body);

    my $retcode = $curl->perform;

    return ($retcode, $response_body);
  }

  
}
