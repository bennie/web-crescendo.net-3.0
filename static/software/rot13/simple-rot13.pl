#!/usr/bin/perl -w

use strict;

while (my $line = <STDIN>) {
  $line =~ tr/A-Za-z/N-ZA-Mn-za-m/;
  print $line; 
}
