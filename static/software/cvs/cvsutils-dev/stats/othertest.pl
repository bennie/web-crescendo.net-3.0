#!/usr/bin/perl -I../lib

use RCS;

my $rcs = new RCS;
$rcs->{debug} = 1;
my $ret = $rcs->load('../dummy-archive/start.txt,v');

my $version = '1.1';

my $doc = $rcs->get($version);
print "\n\n$version\n\n$doc";
