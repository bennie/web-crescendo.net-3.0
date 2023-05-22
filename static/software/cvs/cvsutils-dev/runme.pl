#!/usr/bin/perl

use Cwd;
use lib 'lib';
use strict;

# bootstrap

my @errors;

eval { require Term::Query;   } || push @errors, 'Term::Query';

if (@errors) {
  print "\nOOPS! - Required modules not found:\n\n";
  for my $next_trick (@errors) { print "             $next_trick\n"; }
  print "\nYou will need to install these modules.\nFor more information, ",
        "please read the documentation.\n\n";
  exit 1;
} else { 
  @errors = (); 
}

import Term::Query 'query';

# bootstrapping

my $center = sub {
               my $string = shift @_;
               my @chars = split '', $string;  
               my $r = 80 - scalar @chars;
               while ( $r-- > 0 ) {
                 $string = ' ' . $string;
                 $string .= ' ' if $r-- > 0;
               }
               return "$string\n";
             };

my $line = sub {
             my $string = shift @_;
             my @chars = split '', $string;  
             my $r = 78 - scalar @chars;
             while ( $r-- > 0 ) { $string .= '-' }
             return '#'.$string."#\n";
           };

my $return = sub { query(' 'x50,'d','Press RETURN to continue'); };

# run

print &$line, &$center('Welcome to the wonderful world of CVS Utilities'),
      &$center('(Harvesting them thar canned fruits)'), &$line, "\n",
      &$center('Released under GPL'), &$center('This release is version: alpha'),
      &$center('Bugs may exist'), "\n\n";

&$return;

print "\n", &$line(' Boostrapping '), "\n";

my $cwd      = getcwd();
my $cachedir = $cwd.'/cache';
my $htmldir  = $cwd.'/html';
my $libdir   = $cwd.'/lib';
my $rcs      = $libdir . '/RCS.pm';
my $statsdir = $cwd.'/stats';
my $parse    = $statsdir . '/parse.pl';
my $image    = $statsdir . '/image.pl';

print '  Looking for the cache directory ....... ';
if ( -d $cachedir ) { print "ok\n"; } else { die "NO CACHEDIR"; }
print '  Looking for the html directory ........ ';
if ( -d $htmldir  ) { print "ok\n"; } else { die "NO HTMLDIR";  }
print '  Looking for the library directory ..... ';
if ( -d $libdir   ) { print "ok\n"; } else { die "NO LIBDIR";   }
print '  Looking for the RCS.pm module ......... ';
if ( -f $rcs      ) { print "ok\n"; } else { die "NO RCS.PM";   }
print '  Looking for the stats directory ....... ';
if ( -d $statsdir ) { print "ok\n"; } else { die "NO STATSDIR"; }
print '  Looking for the parse.pl module ....... ';
if ( -f $parse    ) { print "ok\n"; } else { die "NO PARSER";   }
print '  Looking for the image.pl module ....... ';
if ( -f $image    ) { print "ok\n"; } else { die "NO IMAGE";    }

print "\n", &$line(' Interview '),
      "\n  It looks like you have a complete kit, now a few questions:\n\n";

my $suffix     = query('  What is your RCS suffix       :  ','d',',v');
my $repository = query('  Where is your CVS Repository  :  ','d','/my/cvs/project');

while ( ! -d $repository ) {
  print "\n  $repository is not a valid directory.\n";
  $repository = query('  Where is your CVS Repository  :  ','d',$repository);
}

my $doit = -f $cachedir . '/stats.txt' 
         ? query('  I see that there is a stats.txt, use it?','N')
         : 'no';

print "\n", &$line(' Running '), "\n",
"  We're now going to build statistics on the directory you pointed me to.\n",
"  Depending on the size of the repository and files, this could take some\n",
"  time. My original sample repository of 21.8 megs (comprised of 390 or\n",
"  so source files) took about 50 minutes to process. So grab a cup of\n",
"  coffee and let things run.\n",
"\n",
"  Once the data is parsed it will be dumped into the cache directory as\n",
"  the file stats.txt. From there, the output data will be produced.\n",
"  With this code being alpha, there will be a whole lot of warnings.\n",
"  Hopefully it will all work anyway. I'm working on chasing down the\n",
"  bugs. :)\n",
"\n",
"  While I have your attention, just a note. I am currently up for\n",
"  employment. Check out my page (http://www.crescendo.net/resume/) if\n",
"  you're interested in an perl hacker and sysadmin for your company.\n",
"\n";

&$return;

if ( $doit eq 'no' ) {
  print "\n  Running parse.pl ...\n\n";
  system("$parse $repository $suffix");
}

print "\n  Running image.pl ...\n\n";
system("$image $cachedir $htmldir");

