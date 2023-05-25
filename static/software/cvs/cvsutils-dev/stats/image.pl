#!/usr/bin/perl

use Date::Calc qw(Day_of_Year);
use Image::Magick;
use strict;

my $cachedir = shift @ARGV || die 'no cache dir input';
my $htmldir  = shift @ARGV || die 'no html dir input';

my $infile  = $cachedir . '/stats.txt';
my $outfile = $htmldir  . '/sandwich.png';

# Read in the data file

my %data; my %dates; my %year;

open INFILE, $infile;
while ( my $line = <INFILE> ) {
  my ( $file, $version, $date, $author, $bytes ) = split ':', $line;
  $data{$file}{$version}{authors}{$author} = $bytes;
  
  $date =~ /^(\d\d\d\d)\.(\d\d)\.(\d\d)\./;

  $dates{$file}{$version}{day}  = Day_of_Year($1,$2,$3);
  $dates{$file}{$version}{year} = $1;

  $year{$1}++;
}
close INFILE;

# Note the time

my @time = localtime;
my $current_year = $time[5] + 1900;
my $current_day  = $time[7];

# Reparse

my %stats;

for my $file ( keys %data ) {
  my @versions = sort { $dates{$file}{$a}{year} <=> $dates{$file}{$b}{year} || $dates{$file}{$a}{day} <=> $dates{$file}{$b}{day} } keys %{$data{$file}};
  while ( @versions ) {
    my $version = shift @versions;
    my $start_year = $dates{$file}{$version}{year};
    my $start_day  = $dates{$file}{$version}{day};

    my $end_year = $versions[0] ? $dates{$file}{$versions[0]}{year} : $current_year;
    my $end_day  = $versions[0] ? $dates{$file}{$versions[0]}{day}  : $current_day;

    next if $end_day == $current_day && $file =~ /Attic/; # If it is an attic file it dies

    for my $year ( $start_year .. $end_year ) {
      my $start_loop_day = $year == $start_year ? $start_day : 1;
      my $end_loop_day   = $year == $end_year   ? $end_day   : 365;
      for my $day ( $start_loop_day .. $end_loop_day ) {
        $stats{$year}{$day}{$file} = {}; # Zero in case multiple submits occured in a day .. last is authoritive
        for my $author ( keys %{$data{$file}{$version}{authors}} ) {
          my $bytes = $data{$file}{$version}{authors}{$author};
          chomp $bytes;
          $stats{$year}{$day}{$file}{$author} = $bytes;
        }
      }
    }
  }
}

# load up the points

my $day_limit = 478; # maximum pixels wide
my $count = 0;

my $max_byte = 0;

my %points; my %authors;

for my $year ( sort { $b <=> $a } keys %year ) {
  my $day = $year == $current_year ? $current_day : 365;
  while ( $day > 0 ) {
    last if $count > $day_limit;

    my $total = 0;
    
    for my $file ( keys %{ $stats{$year}{$day} } ) {
      for my $author ( keys %{ $stats{$year}{$day}{$file} } ) {
        $authors{$author}++;
        my $bytes = $stats{$year}{$day}{$file}{$author};
        $points{$count}{$author} += $bytes;
        $total += $bytes;
      }
    }

    print "$year $day is the first date\n" if $count == 1;
    
    $max_byte = $total if $total > $max_byte;

    $day--;
    $count++;
  }
  last if $count > $day_limit;
}

print "Max size = $max_byte\n", scalar(keys %points), " days of data\n";

# Build the image

my $img = new Image::Magick (size=>'600x400');
my $ret;

$ret = $img->ReadImage('xc:white');
warn $ret if $ret;

# place the points

my $y_limit = 280;

my $diff_value = int( $max_byte / $y_limit );
print "Vertical pixels are a difference of $diff_value bytes.\n";

my @colors  = ('red','blue','green','yellow','brown','orange','teal');
my @authors = sort { $authors{$b} <=> $authors{$a} } keys %authors;
my $count = 0;

map { $authors{$_} = $colors[$count++]; } @authors;

for my $x_count ( sort { $a <=> $b } keys %points ) {
  my $x = 100 + $x_count;

  my $y     = 300;
  my $bytes = 0;

  for my $author ( @authors ) {
    next unless $points{$x_count}{$author};
    my $y1 = $y  - int( $bytes / $diff_value );
    my $y2 = $y1 - int( $points{$x_count}{$author} / $diff_value );
    $bytes += $points{$x_count}{$author};
    
    $img->Draw(stroke=>$authors{$author}, primitive=>'line', points=>"$x,$y1 $x,$y2");

  }
  $y -= int( $bytes / $diff_value ) if $bytes > 0;

  print "$x_count : $bytes : $x, $y";
  for my $author ( keys %{$points{$x_count}} ) {
    print " : $author ($points{$x_count}{$author})";
  }
  print "\n"; 
  
  $img->Set("pixel[$x,$y+1]"=>'black');    
}

# Notate

for my $i ( 0 .. 8 ) {
  my $y = 20 + (35*$i);
  $ret = $img->Draw(stroke=>'black', primitive=>'line', points=>"95,$y 100,$y");
  warn $ret if $ret;
  $ret = $img->Draw(stroke=>'grey', primitive=>'line', points=>"100,$y 580,$y");
  warn $ret if $ret;
}

for my $i ( 0 .. 12 ) {
  my $x = 100 + (40*$i);
  $ret = $img->Draw(stroke=>'black', primitive=>'line', points=>"$x,300 $x,305");
  warn $ret if $ret;
  $ret = $img->Draw(stroke=>'grey', primitive=>'line', points=>"$x,20 $x,300");
  warn $ret if $ret;
}

$ret = $img->Draw(stroke=>'black', primitive=>'rectangle', points=>'100,20 580,300');
warn $ret if $ret;

$ret = $img->Annotate( text=>"CVS Utilities", fill=>'black', 'x'=>5, 'y'=>15);
warn $ret if $ret;

$ret = $img->Annotate( text=>"Graph of Daily Code Authorship", fill=>'black', 'x'=>250, 'y'=>15);
warn $ret if $ret;

my $y = 325;
while ( @authors ) {
  my $author1 = shift @authors;
  my $author2 = shift @authors || undef;
  my $author3 = shift @authors || undef;

  my $x = 100;
  for my $author ( $author1, $author2, $author3 ) {
    next unless defined $author;
    $ret = $img->Draw(stroke=>'black',fill=>$authors{$author},primitive=>'rectangle', points=>"$x,$y ".($x+10).','.($y+10));
    warn $ret if $ret;
    $ret = $img->Annotate(text=>$author, fill=>'black', x=>($x+20), y=>($y+10));
    warn $ret if $ret;
    $x+=150;
  }  
  $y+=25;

}

# write the file

$ret = $img->Write($outfile);
warn $ret if $ret;
