package yandex_money_api;

use warnings;
use strict;
use URI;
use URI::QueryParam;
use WWW::Mechanize;
use JSON::PP;

my $money_url='https://money.yandex.ru';
my $agent_alias='Windows IE 6';
my $client_id;
my $redirect_uri;
my $token;

sub _print_debug
{
   return;

   my $line=$_[0];
   if (defined($line) == 1) {
      print "DEBUG :",$line,"\n\n";
   }
}

sub _get_file
{
   my $file=$_[0];

   my $filename = "$file.txt";

   open(my $fh, '<', $filename) || die "Could not open file '$filename' $!";
   my $line = <$fh>;
   close $fh;
   
   _print_debug "LOAD $file = $line\n\n";
   
   return $line;
}

sub _get_client_id
{
   return _get_file('yandex_money_client_id');
}

sub _get_redirect_uri
{
   return _get_file('yandex_money_redirect_uri');
}

sub _get_token
{
   return _get_file('yandex_money_token');
}

BEGIN
{
   $client_id = _get_client_id();
   $redirect_uri = _get_redirect_uri();
   $token = _get_token();
}

sub get_code
{
   my $username=$_[0];
   my $password=$_[1];
   my $password_pay=$_[2];
   my $scope=$_[3];

   my $url="$money_url/oauth/authorize";

   my %params_hash = ();
   $params_hash{'client_id'} = $client_id;
   $params_hash{'response_type'} = 'code';
   $params_hash{'redirect_uri'} = $redirect_uri;
   $params_hash{'scope'} = $scope;
   
   my $params=\%params_hash;

   my $mech=WWW::Mechanize->new(
      stack_depth => 10,
      timeout     => 120,
      autocheck   => 0
   );
   $mech->agent_alias($agent_alias);

   my @parms_arr;
   foreach my $k (sort keys %$params) {
      push(@parms_arr, $k);
      push(@parms_arr, $params->{$k});
   }
   
   $mech->post($url, \@parms_arr);

   $mech->field(login => $username);
   $mech->field(passwd => $password);
#   $mech->save_content( "login.html", binary => 1 );
   $mech->submit();

   my @inputs = $mech->find_all_inputs(type => 'password');
   my $inputs_size = @inputs;
   if ($inputs_size != 0) {
      $mech->field(passwd => $password_pay);
   } else {
   $mech->field("emergency-code" => $password_pay);
   }
#   $mech->save_content( "confirm.html", binary => 1 );
   $mech->submit();

   my $json_text=$mech->content();
   _print_debug($json_text);

   my $json_scalar = decode_json($json_text);

   if ($json_scalar->{'status'} ne 'success') {
      die "Not success status json = $json_text";
   }

   $mech->get($json_scalar->{'url'});
   
   my $code_link=$mech->uri();
   my $parse_code_link = URI->new($code_link);
   
   my $code = $parse_code_link->query_param('code');
   return $code;
}

sub get_token
{
   my $code=$_[0];

   my $url="$money_url/oauth/token";

   my $mech=WWW::Mechanize->new(
      stack_depth => 10,
      timeout     => 120,
      autocheck   => 0
   );
   $mech->agent_alias($agent_alias);

   my %params_hash = ();
   $params_hash{'client_id'} = $client_id;
   $params_hash{'code'} = $code;
   $params_hash{'redirect_uri'} = $redirect_uri;
   $params_hash{'grant_type'} = 'authorization_code';
   
   my $params=\%params_hash;

   my $k;
   my @parms_arr;
   foreach $k (sort keys %$params) {
      push(@parms_arr, $k);
      push(@parms_arr, $params->{$k});
   }

   $mech->post($url, \@parms_arr);

   my $json_text=$mech->content();
   _print_debug($json_text);

   my $json_scalar = decode_json($json_text);
   my $token = $json_scalar->{'access_token'};
   
   return $token;
}

sub get_balance
{
   my $url="$money_url/api/account-info";
   
   my $mech=WWW::Mechanize->new(
      stack_depth => 10,
      timeout     => 120,
      autocheck   => 0
   );
   $mech->agent_alias($agent_alias);

   $mech->add_header( Authorization => "Bearer $token" );

   $mech->post($url);

   my $json_text=$mech->content();
   _print_debug($json_text);

   my $json_scalar = decode_json($json_text);
   my $balance = $json_scalar->{'balance'};
   
   return $balance;
}

sub get_payments
{
   my $label=$_[0];
   my $url="$money_url/api/operation-history";
   
   my $mech=WWW::Mechanize->new(
      stack_depth => 10,
      timeout     => 120,
      autocheck   => 0
   );
   $mech->agent_alias($agent_alias);
   
   $mech->add_header( Authorization => "Bearer $token" );
   
   my %params_hash = ();
   if (defined $label) {
      $params_hash{'label'} = $label;
   }
   $params_hash{'type'} = 'payment';
   $params_hash{'details'} = 'true';
   
   my $params=\%params_hash;
   
   my $k;
   my @parms_arr;
   foreach $k (sort keys %$params) {
      push(@parms_arr, $k);
      push(@parms_arr, $params->{$k});
   }

   $mech->post($url, \@parms_arr);

   my $json_text=$mech->content();
   _print_debug($json_text);

   my $json_scalar = decode_json($json_text);
   
   return $json_scalar->{'operations'};
}

sub send_money
{
   my $receiver=$_[0];
   my $amount=$_[1];
   my $label=$_[2];
   my $comment=$_[3];

   my $url="$money_url/api/request-payment";
   
   my %params_hash = ();
   $params_hash{'pattern_id'} = 'p2p';
   $params_hash{'to'} = $receiver;
   $params_hash{'amount_due'} = $amount;
   $params_hash{'label'} = $label;
   $params_hash{'comment'} = $comment;
   $params_hash{'message'} = $comment;
   
   my $params=\%params_hash;
   
   my $mech=WWW::Mechanize->new(
      stack_depth => 10,
      timeout     => 120,
      autocheck   => 0
   );
   $mech->agent_alias($agent_alias);
   $mech->add_header( Authorization => "Bearer $token" );
   
   my @parms_arr;
   foreach my $k (sort keys %$params) {
      push(@parms_arr, $k);
      push(@parms_arr, $params->{$k});
   }

   $mech->post($url, \@parms_arr);

   my $json_text=$mech->content();
   _print_debug($json_text);

   my $json_scalar = decode_json($json_text);

   if ($json_scalar->{'status'} ne 'success') {
      die "Not success status json = $json_text";
   }

   my $request_id = $json_scalar->{'request_id'};

   #confirm
   my $url2="$money_url/api/process-payment";
   
   my %params_hash2 = ();
   $params_hash2{'request_id'} = $request_id;
   
   my $params2=\%params_hash2;
   
   my $mech2=WWW::Mechanize->new(
      stack_depth => 10,
      timeout     => 120,
      autocheck   => 0
   );
   $mech2->agent_alias($agent_alias);
   $mech2->add_header( Authorization => "Bearer $token" );
   
   my @parms_arr2;
   foreach my $k2 (sort keys %$params2) {
      push(@parms_arr2, $k2);
      push(@parms_arr2, $params2->{$k2});
   }

   $mech2->post($url2, \@parms_arr2);

   my $json_text2=$mech2->content();
   _print_debug($json_text2);

   my $json_scalar2 = decode_json($json_text2);

   if ($json_scalar2->{'status'} ne 'success') {
      die "Not success status json = $json_text2";
   }

   my $payment_id = $json_scalar2->{'payment_id'};
   
   return $payment_id;
}

return 1;

END
{
}

