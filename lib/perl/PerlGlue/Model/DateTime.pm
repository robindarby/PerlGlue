
use MooseX::Declare;

#######################################################################################
#
# By Robin Darby 
#
# REVISON INFORMATION
#
#
#
#
#######################################################################################

class PerlGlue::Model::DateTime extends PerlGlue::Model::Base {

  use MooseX::ClassAttribute;
  use Date::Language;
  use Time::Duration;

  has epoch => ( is => 'rw', isa => 'Int' );

  # class static, map language (ISO) to Date::Language string.
  class_has _dateLangMap => ( is => 'ro', isa => 'HashRef', default => sub {
    {
      en => 'English',
      fr => 'French',
      de => 'German',
      es => 'Spanish',
      ru => 'Russian',
      it => 'Italian',
      nl => 'Dutch',
      no => 'Norwegian',
      se => 'Swedish',
    }
  });

  # Date::Language private mamber.
  has _langDate => ( is => 'rw', isa => 'Date::Language' );

  #
  # BUILD()
  #
  #  Setup language and timezone.
  #
  after BUILD {
    # given an unknown language?
    $self->language( 'en' ) unless($self->_dateLangMap->{$self->language} );

    # setup date format obj.
    $self->_langDate( new Date::Language( $self->_dateLangMap->{ $self->language } ) );

    # set timezone to UTC.
    $ENV{TZ} = 'UTC';
  }
  
  #
  # ago()
  #
  # Returns human readabme string, like "10 minutes ago",
  #   string is in i18n tag format for display.
  #
  method ago {
    my $dateStr = ago(time() - $self->epoch, 1);
    $dateStr =~ s/year(s)? ago/\[! years_ago\]/gi;
    $dateStr =~ s/month(s)? ago/\[! months_ago\]/gi;
    $dateStr =~ s/week(s)? ago/\[! weeks_ago\]/gi;
    $dateStr =~ s/day(s)? ago/\[! days_ago\]/gi;
    $dateStr =~ s/hour(s)? ago/\[! hours_ago\]/gi;
    $dateStr =~ s/minute(s)? ago/\[! minutes_ago\]/gi;
    return $dateStr;
  }

  #
  # short()
  #
  # returns short date format, i.e. 1/20/1978
  #
  method short {
    my $template = ($self->region eq 'US') ? "%m/%d/%Y" : "%d/%m/%Y";
    return $self->_langDate->time2str( $template, $self->epoch );
  }

  #
  # mid()
  #
  # returns mid sized date format, i.e. "1st Aug"
  #
  method mid {
    return $self->_langDate->time2str( "%o %b", $self->epoch );
  }

  #
  # long()
  #
  # returns long formatted date, i.e. 1st August 2012
  #
  method long {
    return $self->_langDate->time2str( "%o %B %Y", $self->epoch );
  }
  
  #
  # time()
  #
  # returns time string, i.e. 1:20 pm
  #
  method time {
    return $self->_langDate->time2str( "%r", $self->epoch );
  }

  #
  # mtime()
  #
  # returns 24h time string, i.e. 1330h
  #
  method mtime {
    return $self->_langDate->time2str( "%T", $self->epoch );
  }

  #
  # epochDay
  #
  # returns 10 digit epoch day.
  #
  method epochDay {
    return int( $self->epoch / 86400 ); 
  }
}
