package PerlGlue::Handler::Talk;

  use Apache2::Const qw(OK NOT_FOUND);
  use Switch;
  use strict;
  use PerlGlue::Service::Schedule;

  sub handler {
    my $r        = shift;
    my $arp      = Apache2::Request->new($r);

    # grap any params.
    my $page       = ($arp->param('page')) ? $arp->param('page') : 0;
    my $deviceId   = $arp->param('device_id');
    my $deviceType = $arp->param('device_type');
    my $message    = $arp->param('message');
    my $rating     = $arp->param('rating');

    # workout talk ID and action based on path.
    my $path = $r->uri;
    my $talkId;
    my $action = "info";
    if( $path =~ m|/talks/(\d+)/(\w+)/| ) {
      $talkId = $1;
      $action = $2;
    }
    
    # bail now if we don't have a talk ID.
    return NOT_FOUND unless( $talkId );
    
    # process the action.
    my $content;
    my $service  = new PerlGlue::Service::Schedule();

    switch($action) {
      case "info"    { $content = $service->getTalkInfo( talkId => $talkId, page => $page ) or do { return NOT_FOUND; }; }
      case "add"     { $content = $service->addTalkToUserSchedule( talkId => $talkId, deviceId => $deviceId, deviceType => $deviceType ) or do { return NOT_FOUND; }; }
      case "remove"  { $content = $service->removeTalkFromUserSchedule( talkId => $talkId, deviceId => $deviceId, deviceType => $deviceType ) or do { return NOT_FOUND; }; }
      case "comment" { $content = $service->commentOnTalk( talkId => $talkId, deviceId => $deviceId, deviceType => $deviceType, message => $message ) or do { return NOT_FOUND; }; }
      case "rate"    { $content = $service->rateTalk( talkId => $talkId, deviceId => $deviceId, deviceType => $deviceType, rating => $rating ) or do { return NOT_FOUND; }; }  
      else           { return NOT_FOUND; };
    }

    # spit something back at the client.
    $r->content_type('application/x-javascript');
    print $content;
    return OK;
  }


1;

