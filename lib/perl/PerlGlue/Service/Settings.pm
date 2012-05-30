use MooseX::Declare;

class PerlGlue::Service::Settings {

  use JSON::XS qw( encode_json );

  use PerlGlue::Model::User;

  method enableAlerts( Str :$deviceId!, Str :$deviceType!, Str :$deviceToken! ) {

    my $user = new PerlGlue::Model::User( deviceId => $deviceId, deviceType => $deviceType );
    my $status = $user->enableAlerts( $deviceToken );
    my $json = {
      status => $status,
      message => "Alerts enabled"
    };

    return encode_json( $json );
  }

  method disableAlerts( Str :$deviceId!, Str :$deviceType! ) {

    my $user = new PerlGlue::Model::User( deviceId => $deviceId, deviceType => $deviceType );
    my $status = $user->disableAlerts();
    my $json = {
      status => $status,
      message => "You will no longer receive alerts"
    };

    return encode_json( $json );
  }

}
