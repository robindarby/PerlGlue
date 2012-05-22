package PerlGlue::Handler::Talk;
  use Apache::Constants qw(OK NOT_FOUND);
  use strict;
  use PerlGlue::Service::Schedule;

  sub handler {
    my $r        = shift;
    my $arp      = Apache::Request->new($r);

    my $page = ($arp->param('page')) ? $arp->param('page') : 0;

    my $path = $r->uri;
    warn"\npath: $path";

    my $talkId;
    if( $path =~ m|/talks/(\d+)/info/| ) {
      $talkId = $1;
    }
    
    return NOT_FOUND unless( $talkId );
    
    my $service  = new PerlGlue::Service::Schedule();
    my $talkJson = $service->getTalkInfo( talkId => $talkId, page => $page ) or do {
      return NOT_FOUND;
    };

    warn"\ntalkJson: $talkJson";

    $r->send_http_header('application/x-javascript');
    #$r->content_type('text/html');
    print $talkJson;
    return OK;
  }

1;

