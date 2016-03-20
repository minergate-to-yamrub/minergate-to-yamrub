package public_api_blockchain;

use warnings;
use strict;
use WWW::Mechanize;
use JSON::PP;

my $url='https://blockchain.info';

BEGIN
{
}

sub _send_post
{
   my $url=$_[0];

   my $mech=WWW::Mechanize->new(
      stack_depth     => 10,
      timeout         => 120,
      autocheck       => 0
   );

   $mech->agent_alias('Windows Mozilla');

   $mech->post($url);

   my $json_text=$mech->content();

   my $json_scalar = decode_json($json_text);

   return $json_scalar;
}

sub get_ticker
{
   return _send_post("$url/ticker");
}

return 1;

END
{
}
