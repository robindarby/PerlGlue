#!/usr/bin/perl -w
  
use strict;
use warnings;
use lib qw( lib/perl );
use Data::Dumper;
use URI;
use Web::Scraper;
use PerlGlue::Database;
use Date::Parse;

$ENV{TZ} = 'UTC';
  
my $dbh = new PerlGlue::Database( connectionStr => 'DBI:mysql:perlglue;hostname=localhost' , username => 'perlglue', password => '');
my $baseUrl = qq{http://act.yapcna.org/2012/schedule};
  

foreach my $dateStr (qw(2012-06-11 2012-06-12 2012-06-13 2012-06-14 2012-06-15)) {
  &processSchedule( $dateStr );
}
  
sub processSchedule {
  my $dateStr = shift;
  my $schedule = scraper {
    process "thead", "header" => scraper {
      process 'th', 'rooms[]', 'TEXT';
    };
    process "tbody", "talks" =>  scraper {
      process 'tr', 'cols[]' => scraper {
        process 'td', 'cell[]' => scraper {
          process 'td', text => 'TEXT';
          process '//a[contains(@href,"talk")]', link => '@href';
        }
      };
    };
  };
  
  my $url = $baseUrl . "?day=$dateStr";
  my $res = $schedule->scrape( URI->new( $url ) );
  
  my $summaryScraper = scraper {
    process "//p[2]", 'summary' => 'TEXT';
  };
  
  my $talks = [];
  
  my $titles = $res->{header}->{rooms};
  shift @$titles;
  foreach my $rows (@{$res->{talks}->{cols}}) {
    my $cells = $rows->{cell};
    my $timeCell = shift @$cells;
    my $time = $timeCell->{text};
    for(my $i = 0;$i <= $#$titles; $i++) {
      my $text = $cells->[$i]->{text};
      my $link = $cells->[$i]->{link};
      next unless($text);
      $text =~ s/[^[:ascii:]]+//g;
      my ($title, $duration, $author);
      if($text =~ /^(.*?)\s-(.*?)\s\(\s*(\d+)min/ ) {
        $author = $1;
        $title  = $2;
        $duration = $3;
      }
      elsif($text =~ /^(.*?)\s\((\d+)min/ ) {
        $title = $1;
        $duration = $2;
      }
      my $room = (scalar @$cells == 1) ? 'TBA' : $titles->[$i];
      my $summaryText = "";
      if($link) {
        my $summaryRes = $summaryScraper->scrape( $link );
        $summaryText = $summaryRes->{summary};
        $summaryText =~ s/[^[:ascii:]]+//g;
      }

      my $epoch = str2time( "$dateStr $time" );      
      my $epochDay = int($epoch / 86400);
  
      my $authorId = ($author) ? &lookupAuthor( $author ) : undef;
      my $sql = qq{insert into talks (date, day, duration, location, title, overview, author_id) values(?,?,?,?,?,?,?)};      
      $dbh->query( $sql, [ $epoch, $epochDay, $duration, $room, $title, $summaryText, $authorId ] ); 
     
      my $talkHash =  {
        time => $epoch,
        room => $room,
        author => $author,
        duration => $duration,
        title => $title,
        summary => $summaryText
      };
      print Dumper( $talkHash );
    }
  }
}

sub lookupAuthor {
  my $author = shift;

  my $sql = qq{select id from authors where name = ?};
  my $sth = $dbh->runSqlCommand( $sql, [$author] );
  my $authorId;
  if( my $row = $sth->fetchrow_hashref ) {
    $authorId = $row->{id};
  }
  $sth->finish;
  return $authorId if($authorId);

  $sql = qq{insert into authors (name) values(?)};
  $authorId = $dbh->query( $sql, [ $author ] );

  return $authorId;
}

