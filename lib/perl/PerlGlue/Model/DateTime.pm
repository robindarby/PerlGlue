
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
  use Time::Local;

  has epoch => ( is => 'rw', isa => 'Int', lazy => 1, builder => '_buildEpochTime' );
  has zone  => ( is => 'rw', isa => 'Str', default => 'CDT' );

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
  }
  
  #
  # ago()
  #
  # Returns human readabme string, like "10 minutes ago",
  #   string is in i18n tag format for display.
  #
  method ago {
    return ago(time() - $self->epoch, 1);
  }

  #
  # short()
  #
  # returns short date format, i.e. 1/20/1978
  #
  method short {
    my $template = ($self->region eq 'US') ? "%m/%d/%Y" : "%d/%m/%Y";
    return $self->_langDate->time2str( $template, $self->epoch, $self->zone );
  }

  #
  # mid()
  #
  # returns mid sized date format, i.e. "1st Aug"
  #
  method mid {
    return $self->_langDate->time2str( "%o %b", $self->epoch, $self->zone );
  }

  #
  # long()
  #
  # returns long formatted date, i.e. 1st August 2012
  #
  method long {
    return $self->_langDate->time2str( "%o %B %Y", $self->epoch, $self->zone );
  }
  
  #
  # time()
  #
  # returns time string, i.e. 1:20 pm
  #
  method time {
    return $self->_langDate->time2str( "%r", $self->epoch, $self->zone );
  }

  #
  # mtime()
  #
  # returns 24h time string, i.e. 1330h
  #
  method mtime {
    return $self->_langDate->time2str( "%T", $self->epoch, $self->zone );
  }

  #
  # epochDay
  #
  # returns 10 digit epoch day.
  #
  method epochDay {
    return int( $self->epoch / 86400 ); 
  }

  method fiveMinutesFromNow {
    return $self->epoch + 3000;
  }


  method _buildEpochTime {
    $ENV{TZ} = $self->zone;
    return time;
  }
}
