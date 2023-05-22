#!/usr/bin/perl

use CGI;
use HTML::Template;
use strict;

### Conf

my $base_cachedir = '/home/httpd/html/robertwsmith.com/gallery/cache';
my $base_filedir  = '/home/httpd/html/robertwsmith.com/gallery/images';

my $base_url = 'http://www.robertwsmith.com/gallery/gallery.cgi';

### Bootstrap

my $cgi  = new CGI;
my $tmpl = new HTML::Template;

print $cgi->header;

### What are we looking for

my @path = split '/', $cgi->path_info;
shift @path; # remove garbage

my @clean;
for my $chunk (@path) {
  next if $chunk eq '.' or $chunk eq '..';
  push @clean, $chunk;
}

my $work_localdir = &path(@clean);
my $work_filedir  = &path($base_filedir,$work_localdir);
my $work_cachedir = &path($base_cachedir,$work_localdir);

die "Not a directory: $work_filedir" unless -d $work_filedir;

print $cgi->start_html,
      $cgi->p($work_filedir),
      $cgi->p($work_cachedir),
      $cgi->end_html;

### Subroutines

sub path {
  my $raw = join '/', @_;
     $raw =~ s/\/\/+/\//g;
  return $raw;
}
