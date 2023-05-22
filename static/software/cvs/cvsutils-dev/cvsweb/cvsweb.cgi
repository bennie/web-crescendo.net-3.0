#!/usr/bin/perl
#*************************************************************************

=head1 cvsweb.cgi - A web view of your source

$Version$ 
$Date: 2002/02/25 22:50:44 $

A rewrite of the very useful and often neglected cvsweb.cgi started 
2/25/2002.

=cut

#*************************************************************************

# conf

my $code_tree      = 'macro2';
my $cvs_repository = '/home/cvs/repository/';
my $suffix         = ',v';

### bootstrap

=head1 Required Modules

This CGI requires several modules for functionaility:

  CGI        : For all HTML output
  Rcs::Agent : To parse individual CVS files

=cut

use strict;

my @errors;

eval { require CGI;           } || push @errors, 'CGI';
eval { require Rcs::Agent;    } || push @errors, 'Rcs::Agent';

&simple_error_page(
 "<p>The following Perl modules are required:</p>",
 "\n\n<ul>\n", ( map { "<li>$_\n"; } @errors ), "</ul>\n\n"
) if scalar @errors > 0;

import CGI ('all','-noDebug');
import Rcs::Agent;


# main

my $cgi = new CGI;
my @params = grep /./, split '/', $cgi->path_info; 

#'

my $icon_back = $cgi->img({-src=>'/icons/back.gif',-width=>20,height=>22});
my $icon_dir  = $cgi->img({-src=>'/icons/dir.gif',-width=>20,height=>22});
my $icon_text = $cgi->img({-src=>'/icons/text.gif',-width=>20,height=>22});


my $file = &clean( $cvs_repository, $code_tree, @params );

print $cgi->header, $cgi->start_html;

if    ( -d $file ) { &showdir($file);  }
elsif ( -f $file.$suffix ) { &showfile($file); }
else { &error("$file is not a valid parameter."); }

print $cgi->end_html;


# subroutine

sub error {
  print @_;
}

sub scandir {
  my $dir = shift @_;
  opendir INDIR, $dir;
  my @files = sort { lc($a) cmp lc($b) } grep !/^\.+$/, readdir INDIR;
  closedir INDIR;
  return @files;
}

sub showdir {
  my $dir = shift @_;

  my @files = &scandir($dir);

  my ( @dirs, @good, @crap );

  for my $in ( @files ) { 
       if ( $in =~ /$suffix$/ )   { push @good, &strip($in); }
    elsif ( -d &clean($dir,$in) ) { push @dirs, $in; }
    else                          { push @crap, $in; }
  }

  print $cgi->table(
    $cgi->Tr($cgi->td($icon_back),$cgi->td($cgi->a({-href=>&url(-1)},'Parent Dir'))),
    &dirs(@dirs),
    &docs(@good),
  );
  
  map { print "$_\n"; } @crap;
}

sub dirs {
  return map { $cgi->Tr($cgi->td($icon_dir),$cgi->td($cgi->a({-href=>&url($_)},$_))); } @_;
}

sub docs {
  return map { $cgi->Tr($cgi->td($icon_text),$cgi->td($cgi->a({-href=>&url($_)},$_))); } @_;
}

sub showfile {
  my $file = shift @_;

  my $rcs  = new Rcs::Agent (
      file    => $file,
      suffix  => $suffix
  );

  die 'NOT DEFINED!' if not defined $rcs;

  my $current = $rcs->head;
  my $time = scalar localtime $rcs->timestamp;

  print $cgi->p('Current Version:',$current),
        $cgi->p('Last Modified:',$time),
        $cgi->p($file);
}

sub simple_error_page {
  print "Content-type:  text/html\n\n",
        "<html><head><title>KABOOM!</title></head>\n",
        "<body bgcolor=\"#FFFFFF\">\n",
        "<font size=\"5\" face=\"Arial\">KABOOM!</font>\n",
        "<hr noshade />\n";
  map { print "$_\n"; } @_;
  print "\n\n</body></html>\n";
  exit;
}

sub url {
  return $cgi->url . &clean('/',@params,@_);
}

sub strip {
  my $in = shift @_;
  $in =~ /^(.*)$suffix$/;
  return $1;
}

sub clean {
  my $out = join '/', @_;
  $out =~ s/\/+/\//g;
  return $out;
}

=head1 Copyright

Copyright 2002, Phillip Pollard <binky@bears.org>

Released under GNU license.
All other rights reserved.

http://www.yals.net/projects/cvs-utils/

=head2 Based upon "cvsweb.cgi" v 1.28

This cgi is a complete rewrite of cvsweb.cgi. It was originally written 
(in his spare time) by Bill Fenner and extended by numerous others. No 
actual code was used, ony functionailty.

cvsweb.cgi was released under BSD license. Full copyright
and release information is available at:

http://www.FreeBSD.org/cgi/cvsweb.cgi/www/en/cgi/cvsweb.cgi

=cut