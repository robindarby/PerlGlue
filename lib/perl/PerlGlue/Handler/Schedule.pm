package PerlGlue::Handler::Schedule;

  use Apache::Constants qw(OK NOT_FOUND);
  use Switch;
  use strict;
  use PerlGlue::Service::Schedule;

  sub handler {
    my $r        = shift;
    my $arp      = Apache::Request->new($r);

    # grap any params.
    my $page       = ($arp->param('page')) ? $arp->param('page') : 0;
    my $deviceId   = $arp->param('device_id');
    my $deviceType = $arp->param('device_type');
    my $epoch      = $arp->param('epoch');

    my $path = $r->uri;
    my $action = "schedule";
    if( $path =~ m|/talks/(\w+)/| ) {
      $action = $1;
    }
    
    # process the action.
    my $content;
    my $service  = new PerlGlue::Service::Schedule();

    switch($action) {
      case "schedule"   { $content = $service->getSchedule( epoch => $epoch, page => $page ) or do { return NOT_FOUND; }; }
      case "myschedule" { $content = $service->getUserSchedule( epoch => $epoch, page => $page, deviceId => $deviceId, deviceType => $deviceType ) or do { return NOT_FOUND; }; }
      else              { return NOT_FOUND; };
    }

    # spit something back at the client.
    $r->send_http_header('application/x-javascript');
    print $content;
    return OK;
  }


1;

