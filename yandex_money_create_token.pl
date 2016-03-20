use warnings;
use strict;
use POSIX;
use Data::Dumper qw(Dumper);

use yandex_money_api;

sub save_token
{
   my $token=$_[0];

   my $filename = 'yandex_money_token.txt';

   open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
   print $fh $token;
   close $fh;
}

my $username=<your email>;
my $password=<your password>;
my $password_pay=<your payment password or confirmed code>;

my $scope='account-info operation-history operation-details payment-p2p';

my $code = yandex_money_api::get_code($username, $password, $password_pay, $scope);
print $code;

my $token = yandex_money_api::get_token($code);

print $token;
save_token($token);
