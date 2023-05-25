#!/usr/bin/perl

use strict;

open INFILE, '<wolves.txt';

while ( my $test = <INFILE> ) {
  next if $test =~ /^#/o;
  chomp $test;
  my $match = $test =~ /((v|wh|w)+(0|o|ou|u|y)+(l*(f|ph|(?<!vol)v))+(ei?|ie|in|y)?)/i ?1:0;
  my $caught = $1;
  my $perfect = $test eq $caught ? 1:0;
  print "$match : $perfect : $test : $caught\n";
}

close INFILE;
