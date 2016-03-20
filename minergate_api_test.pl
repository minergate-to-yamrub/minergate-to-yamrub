use warnings;
use strict;
use POSIX;
use Time::Local;
use Data::Dumper qw(Dumper);

use minergate_api;

print Dumper minergate_api::get_balance();

print Dumper minergate_api::get_transfers();
print Dumper minergate_api::get_transfers('bcn');

print Dumper minergate_api::get_withdrawals();
print Dumper minergate_api::get_withdrawals('xmr');

my $bcn_trans = minergate_api::get_transfers('bcn');
foreach my $trans (@$bcn_trans) {
   my $created = localtime($trans->{'created'} / 1000);
   my $amount = $trans->{'amount'};

   print "$created  - $amount BCN\n";
}
