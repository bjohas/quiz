#!/usr/bin/perl
use warnings;
use strict;
use open IO => ':encoding(UTF-8)', ':std';
use utf8;
use feature qw{ say };
use 5.18.2;
#use String::ShellQuote;
#$string = shell_quote(@list);
#use Data::Dumper;
#use JSON qw( decode_json  encode_json to_json from_json);
#use Encode;
my $home = $ENV{HOME};
(my $date = `date +'%Y-%m-%d_%H.%M.%S'`) =~ s/\n//;
my $help = "";
my $string = "";
my $number = "";
use Getopt::Long;
GetOptions (
    "string=s" => \$string, 
    "help" => \$help, 
    "number=f" => \$number, 
    ) or die("Error in command line arguments\n");


chdir("db_trivia");

my %a ;
my @k ;
my $i;
foreach my $file (qw{Trivia1.csv Trivia2.csv Trivia3.csv}) {
    open F,"$file";
    while (<F>) {
	#say $_;
	s/\n//;
	my @a = split /\t/,$_;
	#exit if $i++ > 10;
	next if $a[0] !~ m/\d/;
	@{$a{$a[0]}} = @a;
	push @k, $a[0];
    };
    close F;
};

use Term::ReadKey;

$SIG{'INT'} = sub {
    ReadMode 0;
    close Q;
    print "Bye.\n";
    exit;
};

sub getkey() {
    my $key;
    ReadMode 4; # Turn off controls keys
    while (not defined ($key = ReadKey(-1))) {
	# No key yet
    }
    ReadMode 0;
    if (ord($key) == 3 || $key eq "q") {
	close Q;
	print "Bye!";
	exit;
    };
    return $key;
};


my %q;
open Q, "questions.txt";
my %done;
while (<Q>) {
    if (m/^(d+)\s+(\w+)/) {
	$q{$1} = $2;
    };
};
close Q;

open Q, ">>questions.txt";
$i = 0;
my @index = keys %a;
say "Press any key ('n', enter/return etc) to see the answer / next question.";
say "Press the key 'a' after the answer if you want the question to come up again.";
say "Press the key 'q' to quit.";
say "";
while ($i<=25) {
    my $value = $index[ int(rand(@index)) ];    
    say $value;
    my $q = $a{$value}[1];
    next if $q =~ m/UnScramble this Word/;
    say "\t\t\tQ: ".$q;
    my $key = "";
    $key = &getkey();
    if ($key eq "q")  {
	say "Bye for now!";
	close Q;
	exit;
    };
    say "\t\t\tA: ".$a{$value}[2];
    $key = &getkey();
    if ($key eq "q")  {
	say "Bye for now!";
	close Q;
	exit;
    };
    say Q "$value\t$key";
    #sleep 2;
    $i++;
};
close Q;



__END__


open Q, ">questions.txt";
foreach (@k) {
    say "Q: ".$a{$_}[1];
    say "A: ".$a{$_}[2];
    my $key = &getkey();
    say Q "$_\t$key";
    if ($key eq "q")  {
	close Q;
	exit;
    };
};
close Q;


__END__
if (!@ARGV || $help) {
    print("Need arguments");
    print "Sorry, no help.";
    system("less","$0");
    exit;
};


exit();
