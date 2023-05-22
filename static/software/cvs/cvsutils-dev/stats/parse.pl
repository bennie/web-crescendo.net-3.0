#!/usr/bin/perl

use lib 'lib';
use RCS;
use strict;

my $dir     = shift @ARGV || die 'No directory given';
my $suffix  = shift @ARGV || ',v';
my $outfile = 'cache/stats.txt';

my %datapile;

&recursive_info_gather($dir);

open STATS, ">$outfile";
for my $handle ( keys %datapile ) {
  print "$handle ($datapile{$handle}{current_version})\n";
  for my $ver ( sort { $a <=> $b } grep !/current_version/, keys %{ $datapile{$handle} } ) {
     for my $author ( sort keys %{ $datapile{$handle}{$ver}{authors} } ) {
       print STATS "$handle:$ver:$datapile{$handle}{$ver}{date}:$author:$datapile{$handle}{$ver}{authors}{$author}\n";
     }
  }
}
close STATS;

# sub routines

sub clean { 
  my $dir = join '/', @_;
     $dir =~ s/\/\/+/\//g;
  return $dir;
}

sub examine_dir {
  my $dir = shift @_;
  opendir INDIR, $dir;

  my @files;
  my @subdirs;

  foreach my $meta (readdir INDIR) {
    next if $meta =~ /^\./;

    my $full = &clean($dir,$meta);
    if (-d $full && -r $full) {
      push @subdirs, $meta;
    } elsif (-r $full) {
      push @files, $meta;
    } elsif (-d $full) {
      warn "Private directory? : $full\n";
    } else {
      warn "Unknown : $full\n";
    }
  }
  closedir INDIR;

  return \@files, \@subdirs;
}

sub load_stats {
  my $file = shift @_;
  my $handle = &trim_file($file);

  my $rcs  = new RCS;
  my $ret  = $rcs->load($file);
  my $note = $rcs->notate;

  $datapile{$handle}{current_version} = $rcs->recent_version;
  
  for my $ver ( keys %$note ) {
    $datapile{$handle}{$ver}{date} = $rcs->date($ver);
    for my $line ( keys %{$note->{$ver}->{body}} ) {
      my $author = $rcs->author($note->{$ver}->{body}->{$line}->{origin});
      my $bytes_in_line = $note->{$ver}->{body}->{$line}->{line};
      $datapile{$handle}{$ver}{authors}{$author} += $bytes_in_line;
    }
  }
}  


sub recursive_info_gather {  
  my $dir = &clean( shift @_ );
  my ($files, $subdirs) = &examine_dir($dir);

  for my $file (@$files) {
    next unless $file =~ /$suffix$/o;
    my $full_file = &clean($dir,$file);
    &load_stats($full_file);
  }

  for my $recursion_trick (@$subdirs) {
    &recursive_info_gather(&clean($dir,$recursion_trick));
  }
}  

sub trim_file {
  my $in = shift @_;
  $in = $1 if $in =~ /^$dir(.+)$/o;
  $in = $1 if $in =~ /^(.+)$suffix$/o;
  $in = $1 if $in =~ /^\/(.+)/o;
  return $in;
}
