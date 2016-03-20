package public_api_hitbtc;

use WWW::Mechanize;
use JSON::PP;
use Digest::SHA qw(hmac_sha512_hex);

my $url='https://api.hitbtc.com/api/1/public';

BEGIN
{
}

sub _send_get
{
   my $url=$_[0];
   my $agent_alias='Windows IE 6';

   my $mech=WWW::Mechanize->new(
      stack_depth     => 10,
      timeout         => 120,
      autocheck       => 0
   );
   $mech->agent_alias($agent_alias);

   $mech->get($url);

   my $json_text=$mech->content();
   
   my $json_scalar = decode_json($json_text);

   return $json_scalar;
}

sub get_ticker
{
   my $pair=$_[0];
   return _send_get("$url/$pair/ticker");
}

sub get_orderbook
{
   my $pair=$_[0];
   return _send_get("$url/$pair/orderbook?format_price=number&format_amount=number");
}

sub get_trades
{
   my $pair=$_[0];
   return _send_get("$url/$pair/trades/recent?max_results=300&format_item=object");
}

return 1;

END
{
}

