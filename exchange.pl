use warnings;
use strict;
use POSIX;
use Time::Local;
use Data::Dumper qw(Dumper);

use yandex_money_api;
use minergate_api;

use public_api_poloniex;
use public_api_hitbtc;
use public_api_blockchain;

my $my_account = <your email> ;

sub rateToBTC
{
   my $cur = $_[0];

   if ($cur eq 'xmr') {
      return public_api_poloniex::get_ticker('BTC_XMR')->{'last'};
   }
   if ($cur eq 'bcn') {
      return public_api_hitbtc::get_ticker('BCNBTC')->{'last'};
   }
   if ($cur eq 'fcn') {
      return public_api_hitbtc::get_ticker('FCNBTC')->{'last'};
   }

   die "Undefined currency $cur\n";
}

sub rateToRUR
{
   my $cur = $_[0];
   my $rate_btc = rateToBTC($cur);
   my $rate_rur = public_api_blockchain::get_ticker()->{'RUB'}->{'last'};
   return $rate_btc * $rate_rur;
}

sub convertToRUR
{
   my $amount = $_[0];
   my $cur = $_[1];
   my $rate = rateToRUR($cur);
   return $amount * $rate;
}

sub exchangeToRUR
{
   my $cur = $_[0];
   my $fee = $_[1];

   if (not defined $fee) {
      $fee = 1;
   }

   my $transfers = minergate_api::get_transfers($cur);
   foreach my $trans (@$transfers) {
      my $created = localtime($trans->{'created'} / 1000);
      my $agoday = (time() - $trans->{'created'} / 1000) / (3600 * 24);
      my $amount = $trans->{'amount'};
      my $id = $trans->{'id'};
      my $fromUserId = $trans->{'fromUserId'};
      
      if ($fromUserId eq $my_account) {
         next;
      }

      if ($agoday >= 3) {
         next;
      }

      my $agoday_s = sprintf("%.2f", $agoday);
      print "$created   from $fromUserId amount $amount $cur   ago $agoday_s days\n";
      
      my $payments = yandex_money_api::get_payments($id);
      my $size = @$payments;
      
      if ($size == 0) {
         my $amountRUR = convertToRUR($amount, $cur);
         my $feeRUR = $fee / 100 * $amountRUR;
         
         if ($amountRUR - $feeRUR >= 0.1) {
            my $amount_rur = sprintf("%.2f", $amountRUR - $feeRUR);

            print "$amount $cur = $amountRUR RUR  -fee $fee% = $feeRUR RUR = $amount_rur RUR\n";

            yandex_money_api::send_money($fromUserId, $amount_rur, $id, "Payment for $amount $cur");
         }
      }
   }
}

exchangeToRUR('xmr');
exchangeToRUR('bcn');
exchangeToRUR('fcn');
