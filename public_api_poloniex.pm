package public_api_poloniex;

use WWW::Mechanize;
use JSON::PP;
use Digest::SHA qw(hmac_sha512_hex);

my $url='https://poloniex.com/public';

BEGIN
{
}

sub _get_number_attempt
{
   return -1;
}

sub _get_attempt_pause
{
   return 15;
}

sub _print_debug
{
   return;

   my $line=$_[0];
   if (defined($line) == 1) {
      print "[DEBUG] $line,\n\n";
   }
}

sub _send_post
{
   my $url=$_[0];
   my $agent_alias='Windows IE 6';

   my $mech=WWW::Mechanize->new(
      stack_depth     => 10,
      timeout         => 120,
      autocheck       => 0
   );
   $mech->agent_alias($agent_alias);

   _print_debug($url);

   $mech->post($url);

   my $json_text=$mech->content();

   _print_debug($json_text);
   
   my $json_scalar = decode_json($json_text);

   return $json_scalar;
}

sub _safe_send_post
{
   my $i = 1;
   my $rslt;

   do {
      $rslt = eval { _send_post($_[0]); };
      if ($@) {
         print "$@\n";

         if ($i == _get_number_attempt()) {
            die "number of attempts is settled";
         }
         sleep(_get_attempt_pause());
         $i++;
      }
   } while (not defined $rslt);
   return $rslt;
}

sub get_ticker # ( ) : %hash
{
   my $pair=$_[0];
   return _safe_send_post("$url?command=returnTicker")->{$pair};
}

sub get_volume # ( ) : %hash
{
   my $pair=$_[0];
   return _safe_send_post("$url?command=return24hVolume")->{$pair};
}

sub get_order_book # ( $pair ) : %hash
{
   my $pair=$_[0];
   return _safe_send_post("$url?command=returnOrderBook&currencyPair=$pair");
}

sub get_chart_data # ( $pair ) : @array of %hash
{
   my $pair=$_[0];
   my $period=$_[1];
   my $start=$_[2];
   my $end=$_[3];
   return _safe_send_post("$url?command=returnChartData&currencyPair=$pair&start=$start&end=$end&period=$period");
}

sub get_currency # ( $cur ) : %hash
{
   my $cur=$_[0];
   return _safe_send_post("$url?command=returnCurrencies")->{$cur};
}

sub get_loan_orders # ( $cur ) : %hash
{
   my $cur=$_[0];
   return _safe_send_post("$url?command=returnLoanOrders&currency=$cur");
}

sub get_last # ( $pair ) : double
{
   my $pair=$_[0];
   return get_ticker($pair)->{'last'};
}

return 1;

END
{
}

