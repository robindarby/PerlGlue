package PerlGlue::Handler::Settings;

  use Apache::Constants qw(OK NOT_FOUND);
  use Switch;
  use strict;
  use PerlGlue::Service::Settings;

  sub handler {
    my $r        = shift;
    my $arp      = Apache::Request->new($r);

    # grap any params.
    my $deviceId    = $arp->param('device_id');
    my $deviceType  = $arp->param('device_type');
    my $deviceToken = $arp->param('token');

    my $path = $r->uri;
    my $action = "enable";
    if( $path =~ m|/alerts/(\w+)/| ) {
      $action = $1;
    }
    
    # process the action.
    my $content;
    my $service  = new PerlGlue::Service::Settings();

    switch($action) {
      case "enable"   { $content = $service->enableAlerts( deviceId => $deviceId, deviceType => $deviceType, deviceToken => $deviceToken ) or do { return NOT_FOUND; }; }
      case "disable"  { $content = $service->disableAlerts( deviceId => $deviceId, deviceType => $deviceType, deviceToken => $deviceToken ) or do { return NOT_FOUND; }; }
      else            { return NOT_FOUND; };
    }

    # spit something back at the client.
    $r->send_http_header('application/x-javascript');
    print $content;
    return OK;
  }


1;

