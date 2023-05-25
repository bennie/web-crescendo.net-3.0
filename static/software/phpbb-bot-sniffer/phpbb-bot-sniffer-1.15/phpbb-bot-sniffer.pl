#!/usr/bin/perl

use DB_File;
use DBI;
use Term::Activity;
use strict;

### Conf

my $output = 'bots.txt';
my $dbtable = 'phpbb_users';
my $conf = 'conf.db';

my $supress_num_tests = 2.0; # Must have this many tests score to not be supressed
my $supress_min_score = 0.5; # Must have at least this score to not be supressed

### Full Debug - No supression
# Uncoment this and it will dump EVERYONE who has any sort of score.

#my $supress_num_tests = -1;
#my $supress_min_score = -100;

### Bootstrap

my $version = ( split ': ', '$Revision: 1.15 $' )[1];
chop($version); chop($version);

print STDERR "Starting bot-sniffer (v$version)\n";

### Load conf

my %conf;

unless ( -f $conf ) {
  tie %conf, 'DB_File', $conf || die "Can't create configuration file $conf\n";

  print STDERR "Mysql DB name: ";
  $conf{db} = <STDIN>;
  print STDERR "Mysql DB user: ";
  $conf{user} = <STDIN>;
  print STDERR "Mysql DB pass: ";
  $conf{pass} = <STDIN>;

  chomp $conf{db};
  chomp $conf{user};
  chomp $conf{pass};
} else {
  tie %conf, 'DB_File', $conf || die "Can't read configuration file $conf\n";
}

my $dbh = DBI->connect("dbi:mysql:dbname=$conf{db}", $conf{user}, $conf{pass}) || die("Can't load the DB.");

my $ta = new Term::Activity 'sniffing';

my %tests;

### Wordcheck

my @wordtestfields = qw/username user_from user_interests user_occ user_sig user_website user_msnm user_aim user_yim user_icq/;

my $free = qr/\bfree(?!\s?lance)\b/io; # Trimmed below

my %wordtests = (
  qr/^(spe)cialis/io     => 4,
  qr/natharaxanthe/io    => 4,
  qr/phentermine/io      => 4,
  qr/prozac/io           => 4,
  qr/tramadol/io         => 4,
  qr/viagra/io           => 4,

  qr/FREE SEX/io         => 3,
  qr/SEX CHAT/io         => 3,
  qr/SEX FORUM/io        => 3,
  qr/ADULT PERSONALS/io  => 3,

  qr/e-?gold/io          => 3,
  qr/Earn money/io       => 3,
  qr/free.pictures/io    => 3,
  qr/free.gifts?/io      => 3,
  qr/free.xxx.video/io   => 3,
  qr/golden.shower/io    => 3,
  qr/italian.?charms/io  => 3,
  qr/party.poker/io      => 3,
  qr/russian.?brides?/io => 3,
  qr/sexshops?/io        => 3,
  qr/texas.?hold.?em/io  => 3,
  
  qr/\bcash\b/io         => 1,
  qr/\bdiscount\b/io     => 1,
  qr/fuck/io             => 1,
  qr/gang.?bang/io       => 1,       
  qr/incest/io           => 1,
  qr/medication/io       => 1,
  qr/penis/io            => 1,
  qr/\bpoker\b/io        => 1,
  qr/ring-?tone/io       => 1,
  qr/(?=es)sex/io        => 1,
  qr/(?=work)shop\b/io   => 1,
  qr/\btits\b/io         => 1,
  qr/(^a-z)porn/io       => 1,

  qr/money/io                => 0.5,
  qr/\bmp3/io                => 0.5,
  $free                      => 0.5,
  qr/\brape/io               => 0.5,
);

for my $wordtest ( keys %wordtests ) {
  for my $field ( @wordtestfields ) {
    $tests{$field}{$wordtest} = $wordtests{$wordtest};
  }
}

delete $tests{user_sig}{$free}; # "free" is a common FP in user_sig

$tests{username}{qr/^[A-Za-z]+\d\d\d$/io} = 0.25; # Some script always end their username in three numbers
$tests{username}{qr/^\d+$/io}             = 0.25; # Username is all numbers
$tests{username}{qr/^http:\/\//io}        = 1;    # Username looks like a URL!
$tests{username}{qr/\.(com|net|org)$/io}  = 1;    # Username is a website

$tests{user_icq}{qr/123123/o}    = 4; # ICQ of 123123 is FAKE
$tests{user_icq}{qr/111222333/o} = 4; # ditto
$tests{user_icq}{qr/123456789/o} = 4; # ditto

$tests{user_icq}{qr/^[123]+$/o} = 1; # ICQ composed of only 1s, 2s, and 3s is questionable
$tests{user_icq}{qr/^.{1,3}$/}  = 1; # ICQ of 1-3 digits is likely fake
$tests{user_icq}{qr/^(\d)\1+$/} = 1; # 11111 / 22222 / 33333 / etc

$tests{user_icq}{qr/^.*\D.*$/o} = 0.5; # ICQs should be numbers

$tests{user_msnm}{qr/^([A-Za-z0-9])\1+$/} = 0.5;
$tests{user_yim}{qr/^([A-Za-z0-9])\1+$/}  = 0.5;

$tests{user_email}{qr/[\@\.]bluebottle\.com$/io} = 0.5; # Bluebottle is partly suspect
$tests{user_email}{qr/[\@\.]gawab\.com$/io}      = 0.5; # gawab.com is partly suspect
$tests{user_email}{qr/[\@\.]cjb\.net$/io}        = 0.5; # cjb.net is partly suspect

$tests{user_email}{qr/\@mail\.ru$/io}           = 5; # mail.ru is a spammer

$tests{user_email}{qr/\@bk\.ru$/io}             = 5; # same
$tests{user_email}{qr/\@fuckfreetits\.info$/io} = 5; # same
$tests{user_email}{qr/\@temet-nosce\.info$/io}  = 5; # same
$tests{user_email}{qr/\@yandex\.ru$/io}         = 5; # same

$tests{user_email}{qr/\@\[asdf]+.(com|net|org)$/io} = 1; # asdfasdf.com

$tests{user_website}{qr/boom\.ru\/?$/io}      = 5;

$tests{user_website}{qr/aphrodisiac/io}   = 1;
$tests{user_website}{qr/blowjob\b/io}     = 1;
$tests{user_website}{qr/download.*mp3/io} = 1;
$tests{user_website}{qr/dating/io}        = 1;
$tests{user_website}{qr/drugs\b/io}       = 1;
$tests{user_website}{qr/\bdrugs/io}       = 1;
$tests{user_website}{qr/\bjob/io}         = 1;
$tests{user_website}{qr/\blesbian\b/io}   = 1;
$tests{user_website}{qr/\bpregnant\b/io}  = 1;

$tests{user_email}{qr/\.ro$/io} = 0.25;
$tests{user_email}{qr/\.ru$/io} = 0.25;
$tests{user_website}{qr/\.ro\/?/io} = 0.25;
$tests{user_website}{qr/\.ru\/?/io} = 0.25;

my $numtests = 0;
for my $field ( keys %tests ) { $numtests += scalar(keys %{$tests{$field}}); }

$numtests += 3; # Add the number of kicker tests
$numtests += 4; # Add the FP/FN tests

print STDERR "Loaded $numtests bot sniffing tests.\n";

my $sth = $dbh->prepare("select * from $dbtable");
my $ret = $sth->execute;

my %bots;
my $supress_count = 0;

my $weekago  = time - ( 86400 * 7 );
my $monthago = $weekago - ( 86400 * 23 );

while ( my $ref = $sth->fetchrow_hashref ) {
  $ta->tick;

  my $score = 0;
  my %score_fields;

  # Standard tests

  for my $field ( keys %tests ) {
    for my $test ( keys %{$tests{$field}} ) {
      my $count = 0;
      $count++ while $ref->{$field} =~ m/$test/g;
      next unless $count;
      #if ( $field eq 'user_from' ) { print STDERR "\n", $ref->{$field}, ':', "$test\n"; }
      my $subtotal = $tests{$field}{$test} * $count;
      $score += $subtotal;
      $score_fields{$field} += $subtotal;
    }
  }
  
  # Kickers

  my $id = $ref->{user_id}.') '.$ref->{username};

  if ( $ref->{user_active} == 0 and $ref->{user_posts} == 0 and $ref->{user_regdate} < $monthago ) {
    $score += 1;
    $bots{$id}{kicker}{'Kicker - User inactive and more than a month old'} = 1;
  }
   
  if ( $ref->{user_active} == 0 and $ref->{user_posts} == 0 and $ref->{user_regdate} < $weekago ) {
    $score += 1;
    $bots{$id}{kicker}{'Kicker - User inactive and more than a week old'} = 1;
  }

  if (( $ref->{user_website} =~ /\.ru\//io or $ref->{user_website} =~ /\.ru$/io ) and $ref->{user_email} =~ /\@hotmail\.com$/io ) {
    $score += 1;
    $bots{$id}{kicker}{'Kicker - Russian website and hotmail email'} = 1;
  }

  # Determine
  
  next unless $score;

  # False Positive tests

  if ( $ref->{user_posts} > 10 ) {
    $score -= 1;
    $bots{$id}{FPFN}{'FP - User has more than 10 posts'} = -1;
  }
  if ( $ref->{user_posts} > 25 ) {
    $score -= 2;
    $bots{$id}{FPFN}{'FP - User has more than 25 posts'} = -2;
  }
  if ( $ref->{user_posts} > 50 ) {
    $score -= 2;
    $bots{$id}{FPFN}{'FP - User has more than 50 posts'} = -2;
  }

  # False Negative tests
  
  #unless ( $ref->{user_posts} or $ref->{user_lastvisit} ) {
  #  $score += 1;
  #  $bots{$id}{FPFN}{'FN - No posts and never logged in'} = 1;
  #}

  if ( $ref->{user_website} =~/boom\.ru\/?$/io and $ref->{username} =~ /^[A-Za-z]+\d\d\d$/io ) {
    $score += 3.75;
    $bots{$id}{FPFN}{'FN - boom.ru and 3 digit ending username combo'} = 3.75;
  }

  $bots{$id}{tests_scored} = scalar(keys %score_fields) + scalar(keys %{$bots{$id}{FPFN}}) + scalar(keys %{$bots{$id}{kicker}});
  $supress_count++ unless ( $bots{$id}{tests_scored} >= $supress_num_tests && $score >= $supress_min_score );

  $bots{$id}{score} = $score;
  $bots{$id}{info} = { %$ref };
  $bots{$id}{tests} = \%score_fields;
}

$ta = undef;

my $raw = scalar(keys %bots);
my $report = $raw - $supress_count;

print STDERR "\n$raw bot candidates found\n$supress_count are below supression threshold\n$report potential bots determined\n";

open OUTFILE, '>', $output || die "Can't write to output file $output\n";

print STDERR "\nWriting report to: $output\n";

for my $userid ( sort { $bots{$b}{score} <=> $bots{$a}{score} || $b <=> $a } keys %bots ) {
  my @fields = keys %{$bots{$userid}{tests}};
  next unless $bots{$userid}{tests_scored} >= $supress_num_tests && $bots{$userid}{score} >= $supress_min_score;
  print OUTFILE "$userid scored $bots{$userid}{score} - (User has $bots{$userid}{info}{user_posts} posts and",
        ( $bots{$userid}{info}{user_lastvisit} ? " last visited on " . scalar(localtime($bots{$userid}{info}{user_lastvisit})) : " has NEVER logged in" ),
        ")\n";
  for my $field ( keys %{$bots{$userid}{tests}} ) {
    print OUTFILE "  $field ($bots{$userid}{tests}{$field}) - $bots{$userid}{info}{$field}\n";
  }
  unless ($bots{$userid}{tests}{user_email}) {
    print OUTFILE "  user_email (0) - $bots{$userid}{info}{user_email}\n";
  }
  unless ($bots{$userid}{tests}{user_website}) {
    print OUTFILE "  user_website (0) - $bots{$userid}{info}{user_website}\n";
  }
  for my $othertests ( qw/kicker FPFN/ ) {
    for my $field ( sort { lc($a) cmp lc($b) } keys %{$bots{$userid}{$othertests}} ) {
      print OUTFILE "  $field : $bots{$userid}{$othertests}{$field}\n";
    }
  }
  print OUTFILE "\n";
}

close OUTFILE;
