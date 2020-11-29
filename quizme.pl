#!/usr/bin/perl
use warnings;
use strict;
use open IO => ':encoding(UTF-8)', ':std';
use utf8;
use feature qw{ say };
use 5.18.2;
#use String::ShellQuote;
#$string = shell_quote(@list);
use Data::Dumper;
use JSON qw( decode_json  encode_json to_json from_json);
use Encode;
my $home = $ENV{HOME};
(my $date = `date +'%Y-%m-%d_%H%M%S'`) =~ s/\n//;
my $help = "";
my $string = "";
my $number = "";
use Getopt::Long;
my $amount = 25;
my $category = 9;          #  https://opentdb.com/api.php?amount=10&category=0..29,31,32
my $difficulty = "medium"; #  &difficulty=easy|medium|hard
my $type = "multiple";     #  &type=multiple|boolean
my $specific = "";
GetOptions (
    "string=s" => \$string, 
    "help" => \$help, 
    "number=f" => \$number, 
    "category=f" => \$category,
    "difficulty=s" => \$difficulty,
    "type=s" => \$type    ,
    "amount=f" => \$amount,
    "specific" => \$specific,
    ) or die("Error in command line arguments\n");

use HTML::Entities;
use Term::ANSIColor;

chdir("quizme");

if ($category < 9 || $category == 30 || $category > 32)  {
    say "
Category value needs to be between 9 and 32, but not 30.
";
    exit;
};

binmode STDOUT, ":encoding(UTF-8)";
binmode STDIN, ":encoding(UTF-8)";

use Term::ReadKey;
$SIG{'INT'} = sub {
    ReadMode 0;
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
	exit;
    };
    return $key;
};

my %q;
open LOG, "questions.txt";
foreach (<LOG>) {
    s/\n//;
    $q{$_} = 1;
};
close LOG;

sub getQuestions() {
    my ($amount, $category, $difficulty, $type) = @_;
    say "Retrieving ($amount, $category, $difficulty, $type)";
    if (!-d "questions") {
	mkdir("questions");
    };
    my $f = "questions/$date-$amount-$category-$difficulty-$type.json";
    my $a = `wget -q -O - "https://opentdb.com/api.php?amount=$amount&category=$category&difficulty=$difficulty&type=$type"`;
    open F, ">$f";
    print F $a;
    close F;
    
    $a = &jq(".results",$a);
    #say "a=$a";
    my $b = decode_json(encode_utf8($a));
    #say "b=$b";
    return @{$b};
};


#my $category = 9;          #  https://opentdb.com/api.php?amount=10&category=0..29,31,32
#my $difficulty = "medium"; #  &difficulty=easy|medium|hard
#my $type = "multiple";     #  &type=multiple|boolean

sub getRandom() {
    my @c = (0..29,31,32);
    # excluding 15 = video games
    # excluding 31 = manga
    @c = (0..14,16..29,32);
    my $category = $c[int(rand($#c+1))];
    #say "c = $category";
    my @d = qw(easy medium hard);
    my $difficulty = $d[int(rand($#d+1))];
    my $type = "multiple";
    return ($category, $difficulty, $type);
};

sub getRandomQuestions() {
    my @b;
    while ($#b == -1) {
	my ($category, $difficulty, $type) = &getRandom();
	say "Getting questions: ($category, $difficulty, $type)";
	@b = &getQuestions($amount, $category, $difficulty, $type);
    };
    return @b;
};

my @b = ();
if ($specific) {
    @b = &getQuestions($amount, $category, $difficulty, $type);
} else {
#    @b = &getRandomQuestions();
};

my $i = 0;
my $j = 0;
open LOG, ">>questions.txt";
while ($j < 10) {
    if (!$specific) {
	@b = &getRandomQuestions();
    };
    foreach (@b) {
	#say Dumper($_);
	say "$_->{'category'}, $_->{'difficulty'}, $_->{'type'} choice\n\n" if $i==0;
	$i++;
	my $q = $_->{'question'};
	decode_entities($q);    
	if ($q{$q}) {
	    #say "Skipping: $q";
	    say "(skip)";
	    next;	
	};
	$j++;
	say "Question";
	print color('bold blue');
	say "\t\t\t".$q;
	print color('reset');
	#system "espeak \"$q\" &";
	my @a ;
	my $ans = $_->{'correct_answer'};
	$ans = decode_entities($ans);
	push @a, $ans;
	my @ians = @{$_->{'incorrect_answers'}};
	foreach (@ians) {
	    decode_entities($_);
	};
	push @a, @ians;
	print "Which answer?\n";
	print color('bold green');
	@a = sort @a;
	my @aorig = @a;
	my $k=0;
	foreach (@a) {
	    $k++;
	    $_ = "[  $k. ".$_."  ]";
	};
	say "\t\t\t". join "", @a;
	print color('reset');
	my $key = &getkey();
	$key =~ s/\D//sg;
	if ($key =~ m/\d/ && $aorig[$key-1] eq $ans) {
	    print color('bold blue');
	    print "THAT'S RIGHT!:\n";
	    say "\t\t\t".$ans;
	    print color('reset');
	    say LOG $q;
	} else {
	    print color('bold red');
	    print "WRONG! ";
	    print color('reset');
	    print "Correct answer:\n";
	    print color('bold blue');
	    say "\t\t\t".$ans;
	    print color('reset');
	};
	say "";
	say "";
	#$key = &getkey();
	sleep 1;
    };
};
close LOG;


sub jq() {
    use IPC::Open2;
    use open IO => ':encoding(UTF-8)', ':std';
    open2(*README, *WRITEME, "jq", "-M", $_[0]);
    binmode(*WRITEME, "encoding(UTF-8)");
    binmode(*README, "encoding(UTF-8)");
    print WRITEME $_[1];
    close(WRITEME);
    my $output = join "",<README>;
    close(README);
    return $output;
}
sub jqs() {
    use IPC::Open2;
    open2(*README, *WRITEME, "jq", "--slurp", "-M", $_[0]);
    binmode(*WRITEME, "encoding(UTF-8)");
    binmode(*README, "encoding(UTF-8)");
    print WRITEME $_[1];
    close(WRITEME);
    my $output = join "",<README>;
    close(README);
    return $output;
}



__END__
if (!@ARGV || $help) {
    print("Need arguments");
    print "Sorry, no help.";
    system("less","$0");
    exit;
};

foreach my $file (@ARGV) {
    open F,"$file";
    my @f =  <F>;
    close F;
    my $f = join "",@f;
    foreach my $_ (@f) {
    };
};

exit();
