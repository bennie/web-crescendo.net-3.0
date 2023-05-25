#!/usr/bin/perl

use strict;

while ( my $line = <STDIN> ) {
  # next unless $line =~ /(wh?[ou]+[lf](ph|[fv]{0,2})(i?e)?([ei]n)?(e?y)?)/i;
  # next unless $line =~ /([wv]h?[ouy]+(l?f|lv|l?ph)+(i?e)?([ei]n)?(e?y)?)/i;
  # next unless $line =~ /((v[ou]lf|wh?[ouy]+(l?f|lv|l?ph)+(i?e)?)([ei]n)?(e?y)?)/i;
  # next unless $line =~ /((v|wh|w)+(0|o|ou|u|y)+(l*(f|ph|v))+(ei?|ie|in|y)?)/i;
  next unless $line =~ /((v|wh|w)+(0|o|ou|u|y)+(l*(f|ph|(?<!vol)v))+(ei?|ie|in|y)?)/i;
  print lc($1), "\n";
}
