#!/usr/bin/perl 

# thumbnails is a program for the generate of thumbnails and core HTML to
# visually index a directory of images.
# 
# Copyright (C) 1999-2001, Phillip Pollard
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by 
#  the Free Software Foundation, version 2.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#  Mr. Pollard may be written at 112 Roberts Ln, Lansdale, PA  19446 USA
#  or e-mailed at <phil@crescendo.net>.

### Confuscate

my $debug = 1;

my $copy    = '(C) 1999-2001, Phillip Pollard (phil@crescendo.net)';
my $name    = 'thumbnails';
my $version = 'v 1.0.0 (4.11.2001)';

my $default_image = '.';
my $default_size  = 200;
my $default_thumb = 'thumbs';

### Pragmata

use strict;

my @errors;

eval { require CGI;           } || push @errors, 'CGI';
eval { require Image::Magick; } || push @errors, 'Image::Magick';
eval { require Getopt::Std;   } || push @errors, 'Getopt::Std';
eval { require Term::Query;   } || push @errors, 'Term::Query';

if (@errors) {
  print "\nOOPS! - Required modules not found:\n\n";
  for my $next_trick (@errors) { print "             $next_trick\n"; }
  print "\nYou will need to install these modules.\nFor more information, ",
        "please read the documentation.\n\n";
  exit 1;
} else { 
  @errors = (); 
}

import CGI ('all','-noDebug');
import Image::Magick;
import Getopt::Std 'getopts';
import Term::Query 'query';

### Beguine

my %opts;
getopts('v:',\%opts);

if ( $opts{'v'} ) {
  print "$name $version, $copy\n";
  exit 1;
}

$debug && do {
  print "\n $name\n",
        "\n     This program is $copy",
        "\n     and is distributed freely under the terms of the GNU public",
        "\n     lisence. It comes with ABSOLUTETLY NO WARRENTY. For more ",
        "\n     information, please refer to the documentation.\n",
        "\n     $name will make image thumbnails and nice HTML file for",
        "\n     GIFs, JPGs, PNGs, and Photoshop files.",
        "\n\n";
};

# Single character SDOUT output.
select((select(STDOUT),$|=1)[0]);

my $imagedir  = query ('Where are the directory of images:','d',$default_image);

if (! -e $imagedir) { die "ERROR: Image directory $imagedir dosen't exist\n"; }
if (! -d $imagedir) { die "ERROR: $imagedir is not a directory\n"; }
if (! -r $imagedir) { die "ERROR: You do not have permissions to read from $imagedir\n"; }

my $thumbdir  = query ('Where should I put the thumbnails?','d',$default_thumb);

if (! -e $thumbdir) { print "ERROR: Directory $thumbdir dosen't exist, creating.\n"; system("mkdir $thumbdir"); }
if (! -d $thumbdir) { die "ERROR: $thumbdir is not a directory\n"; }
if (! -w $thumbdir) { die "ERROR: You do not have permissions to write to $thumbdir\n"; }

my $thumbsize = query ('What is the max pixel width/height you prefer?','di',$default_size);
my $htmlpage  = query ("Where should I write the HTML?","d","images.html");
my $cleardir  = query ("Should I clear the thumnail directory of any old files?","Y");

if ($cleardir =~ /yes/) { system("rm $thumbdir/*"); }

opendir IMAGES, $imagedir;
my @files = sort grep !/^\.\.?$/, readdir IMAGES;
closedir IMAGES;

$debug && do { 
  print "\nProcessing ", scalar(@files), " files.\n\n";
  print "/---------------------------------------------------------------------\\\n";
  print "|         Filename         |   Start Size   |    End Size    | Status |\n";
  print "|--------------------------|----------------|----------------|--------|\n";
};

sub numerically { $a <=> $b }
@files = sort numerically @files;

my @images;
foreach my $file (@files) {
  if ($file =~ /.gif$/i || $file =~ /.jpg$/i || 
      $file =~ /.png$/i || $file =~ /.psd$/i) {
    my $thumbfile = $file;
    if ($thumbfile =~ /.psd$/i) { $thumbfile .= '.jpg'; }
    my ($width, $height) = &makethumb($file,$thumbfile);

    my $href;
    if ($imagedir eq '.') { 
      $href = $file;
    } else {
      $href = $imagedir.'/'.$file;
    }

    push @images, "<a href=\"$href\"><img width=\"$width\" height=\"$height\" border=\"0\" src=\"$thumbdir/$thumbfile\"></a>\n<br><small>$file</small>\n";
  }
}

&makepage($htmlpage,@images);

### Fine

$debug && do { print "\\---------------------------------------------------------------------/\n\n"; };

### Submarines

sub makethumb {
  my $file = shift @_;
  my $thumbfile = shift @_;

  $debug && do { 
    print  '|'; 
    printf "%25.25s", $file;
    print  ' | '; 
  };
  
  my $image = Image::Magick->new;
  my $ret = $image->Read($imagedir."/".$file);
  warn "$ret" if $ret;
 
  #$debug && do { print "   got it.\n"; };

  my $width  = $image->Get('width' );
  my $height = $image->Get('height');

  $debug && do {
    printf "%14.14s", "$width x $height"; 
    print  ' | ';
  };

  if ($height > $width) {
    my $newwidth = int (($thumbsize / $height) * $width);
    $image->Scale(height=>$thumbsize,width=>$newwidth);
  } else {
    my $newheight = int (($thumbsize / $width) * $height);
    $image->Scale(height=>$newheight,width=>$thumbsize);
  }

  $width  = $image->Get('width' );
  $height = $image->Get('height');

  $debug && do { 
    printf "%14.14s", "$width x $height"; 
    print  ' | '; 
  };

  $image->Write($thumbdir."/".$thumbfile);
  
  $debug && do { print " done! |\n"; };

  return ($width, $height);

}

sub makepage {
  my $outfile = shift @_;
  my @images  = @_;

  $debug && do { 
    print '|';
    printf "%25.25s", $outfile;
    print  ' | ';
    printf "%14.14s", 'N/A'; 
    print  ' | ';
    printf "%14.14s", 'N/A'; 
    print  ' | ';
  };
  open OUTFILE, ">$outfile";

  print OUTFILE "<center><table cellpadding=\"10\">\n";
  while (@images) {
    print OUTFILE "<tr>\n<td align=\"center\">", shift @images, "</td>\n";

    if (@images) {
      print OUTFILE "<td align=\"center\">", shift @images, "</td>\n";
    } else {
      print OUTFILE "<td>&nbsp;</td>\n";  
    }

    if (@images) {
      print OUTFILE "<td align=\"center\">", shift @images, "</td>\n";
    } else {
      print OUTFILE "<td>&nbsp;</td>\n";
    }
    print OUTFILE "</tr>\n\n";
  }

  print OUTFILE "</table>\n";
  close OUTFILE;

  $debug && do { print " done! |\n"; };

  return 1;
}
