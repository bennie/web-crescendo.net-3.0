#!/usr/bin/env perl

# Generic web-site generation engine.
# (c) 2000-2021, Phillip Pollard <phil@crescendo.net>

use HTML::Template;
use strict;

my $force = $ARGV[0] ?1:0;

### Config

my %title;
$title{'index.txt'} = 'Crescendo.net';
$title{'code--index.txt'} = 'Code';
$title{'consulting.txt'} = 'Consulting';
$title{'fun-stuff--index.txt'} = 'Fun Stuff';
$title{'resume--index.txt'} = 'The Resume';
$title{'software-cvs--example.txt'} = 'Software - CVS Utils - Example Output';
$title{'software-cvs--history.txt'} = 'Software - CVS Utils - Project History';
$title{'software-cvs--index.txt'} = 'Software - CVS Utils';
$title{'software-japh.txt'} = 'Software - The JAPH Log';
$title{'software-phpbb-bot-sniffer--index.txt'} = 'Software - phpBB "Bot" Sniffer';
$title{'software-phpbb-bot-sniffer--spambots.txt'} = 'Software - phpBB Spambots';
$title{'software-phpbb-ignore--index.txt'} = 'Software - phpBB User Ignore Mod';


my $tmpl_dir = 'templates';
my $file_dir = 'raw-pages';
my $html_dir = 'www.crescendo.net/';

my $image_prefix = '/images/';
my $html_prefix  = '/';

### Program

print `rm -rfv www.crescendo.net` if -d $html_dir;
mkdir($html_dir);
print `cp -rv static/* www.crescendo.net/`;


opendir FILEDIR, $file_dir;
my @files = sort { $a cmp $b } grep(/\.txt$/, readdir(FILEDIR));;
closedir FILEDIR;

for my $next_trick (@files) {
  my $template = 'index.tmpl';

  $next_trick =~ /(.+)\.txt$/;
  
  my $page = $1;

  my $infile   = $file_dir.'/'.$next_trick;
  my $tmplfile = $tmpl_dir.'/'.$template;

  my $outfile  = $html_dir.'/'.$page.'.html';
  if ( $next_trick =~ /^(.+?)--/ ) {
  	my $newdir = $html_dir .'/'. $1;
	print " -->  mkdir($newdir) ";
	mkdir($newdir);
    $outfile  =~ s/--/\//g;
  }

  next if -f $outfile and not $force and (stat($infile))[9] < (stat($outfile))[9] and (stat($tmplfile))[9] < (stat($outfile))[9];
  print $infile;

  # Open body and process variables

  my $body_tmpl = HTML::Template->new(
                              die_on_bad_params => 0,
                              filename => $file_dir .'/'. $next_trick
                             );

  $body_tmpl->param(
        image_prefix => $image_prefix,
        html_prefix  => $html_prefix,
  );

  my $body = $body_tmpl->output;

  print " --> $tmplfile ";

  my $meta = HTML::Template->new(
                              die_on_bad_params => 0,
                              filename => $tmplfile,
                             );

  my $title;
  if (length $title{$next_trick}) {
    $title = $title{$next_trick}
  } else {
    $title = "No title - $next_trick"; 
  }

  $meta->param(
    body  => $body,

    image_prefix => $image_prefix,
    html_prefix  => $html_prefix,

    title => $title,
    $page.'_active' => 1,
    time  => scalar(localtime),
  );

  print "--> $outfile ";
   
  open OUTFILE, ">$outfile";
  print OUTFILE $meta->output;
  close OUTFILE;

  print "--> done!\n";
}

print `rsync -av --exclude='.git/' --delete www.crescendo.net/ \${MY_WEBUSER}\@\${MY_WEBHOST}:/var/www/crescendo.net/www`;
