use warnings;
use strict;
use POSIX;
use Data::Dumper qw(Dumper);

use minergate_api;

sub save_token
{
   my $token=$_[0];
   
   my $filename = 'minergate_token.txt';
   
   open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
   print $fh $token;
   close $fh;
}

my $email = <your email>;
my $passwd = <your minergate password>;

my $token = minergate_api::get_token($email, $passwd);
save_token($token);
