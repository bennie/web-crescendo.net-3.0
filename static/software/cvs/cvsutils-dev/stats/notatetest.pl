#!/usr/bin/perl -I../lib/

use RCS;
use strict;

my $rcs = new RCS;
$rcs->{debug} = 1;

my $ret = $rcs->load('../dummy-archive/ftp-index.pl,v');
#my $ret = $rcs->load('../dummy-archive/start.txt,v');
my $note = $rcs->notate;

for my $version ( sort { $a <=> $b } keys %$note ) {
  print "\n\nVERSION $version\n\n";
  for my $line ( sort { $a <=> $b } keys %{$note->{$version}->{body}} ) {
    my $text = $note->{$version}->{body}->{$line}->{line};
    chomp $text;

    print "$line : $note->{$version}->{body}->{$line}->{origin} : $text\n";
  }
}
