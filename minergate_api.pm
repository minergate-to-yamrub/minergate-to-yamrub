package minergate_api;

use warnings;
use strict;
use URI;
use URI::QueryParam;
use WWW::Mechanize;
use JSON::PP;

my $minergate_api_url='https://api.minergate.com/1.0';
my $agent_alias='Windows IE 6';
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

sub _get_token
{
   return _get_file('minergate_token');
}

BEGIN
{
   $token = _get_token();
}

sub get_token
{
   my $email=$_[0];
   my $passwd=$_[1];

   my $url="$minergate_api_url/auth/login";

   my %params_hash = ();
   $params_hash{'email'} = $email;
   $params_hash{'password'} = $passwd;
   $params_hash{'totp'} = 0;

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

   my $json_text=$mech->content();
   _print_debug($json_text);
   
   my $json_scalar = decode_json($json_text);
   
   return $json_scalar->{'token'};
}

sub _auth_get_method
{
   my $url=$_[0];
   
   my $mech=WWW::Mechanize->new(
      stack_depth     => 10,
      timeout         => 120,
      autocheck       => 0
   );
   $mech->agent_alias($agent_alias);
   $mech->add_header('token' => $token);
   $mech->get($url);

   my $json_text=$mech->content();
   _print_debug($json_text);

   my $json_scalar = decode_json($json_text);

   return $json_scalar;
}

sub get_balance
{
   return _auth_get_method("$minergate_api_url/balance");
}

sub get_transfers
{
   my $cur=$_[0];
   if (defined $cur) {
      return _auth_get_method("$minergate_api_url/transfers/$cur");
   }
   return _auth_get_method("$minergate_api_url/transfers");
}

sub get_withdrawals
{
   my $cur=$_[0];
   if (defined $cur) {
      return _auth_get_method("$minergate_api_url/withdrawals/$cur");
   }
   return _auth_get_method("$minergate_api_url/withdrawals");
}

return 1;

END
{
}

