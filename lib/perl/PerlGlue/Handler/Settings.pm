package PerlGlue::Handler::Schedule;
  use Apache::Constants qw(OK);
  use strict;
  use PerlGlue::Service::Schedule;

  sub handler {
    my $r        = shift;
    my $arp      = Apache::Request->new($r);

    my $date     = $arp->param('date');

    my $service  = new PerlGlue::Service::Schedule();

    $r->content_type('text/html');
    print $service->getSchedule( epochDay => $date, offset => 0, limit => 100 );
    return OK;
  }

1;

