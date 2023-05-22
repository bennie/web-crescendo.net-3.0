#!/usr/bin/perl

=head1 dirindex

=head2 A cron optimized HTML and thumbnail generator

This script is designed for easy use in generating a preview set of 
thumbnails and HTML for directories of images. Handy for allowing folks to 
FTP up and down image while regenerating the indexes with cron.

Currently three parameters are processed:

 -b Background color in hex for the web page
 -t Web page title
 -d Full URL to the directory to index

If not given this information, some rather useless defaults are used.

=head1 (c) 2002 Phillip Pollard, <phil@crescendo.net>

=item http://www.crescendo.net/software/dirindex/

=item Released under GNU puclic license

=cut 

### bootstrap

use strict;

my @errors;
eval { require CGI;           } || push @errors, 'CGI';
eval { require Image::Magick; } || push @errors, 'Image::Magick';
eval { require Getopt::Std;   } || push @errors, 'Getopt::Std';
eval { require Term::Query;   } || push @errors, 'Term::Query';

import CGI ('all','-noDebug');
import Image::Magick;
import Getopt::Std 'getopts';
import Term::Query 'query';

### configure

my %opts;
getopts('b:d:t:',\%opts);

my $bgcolor  = $opts{b} || '#FFFFFF';
my $dir      = $opts{d} || 'images';
my $filename = 'index.html';
my $size     = 250;
my $template = '';
my $thumbdir = '.thumbs';
my $title    = $opts{t} || 'No Title Given';

### beguine

my $cgi = new CGI;

my @months = ('Jan','Feb','Mar','Apr','May','Jun',  # used by dates
              'Jul','Aug','Sep','Oct','Nov','Dec');

### sanity checks

die "Directory \"$dir\" does not exist." unless -d $dir;
mkdir $dir .'/'. $thumbdir               unless -d $dir .'/'. $thumbdir;
die "Unable to create \"$thumbdir\""     unless -d $dir .'/'. $thumbdir;

### slurp it in

my %files;

opendir IMAGES, $dir;
for my $file ( grep !/^\./, readdir IMAGES ) { $files{$file}++; }
closedir IMAGES;

opendir THUMBS, $dir .'/'. $thumbdir;
for my $file ( grep !/^\./, readdir THUMBS ) { 
  $files{$1}-- if $file =~ /^(.*)\.jpg$/; 
}
closedir THUMBS;

### Process

my $changes = 0;
my %image_stats;

for my $file ( keys %files ) {
  if ( $files{$file} == 1 && &is_image($file) ) {
   ( $image_stats{$file}{icon_width}, $image_stats{$file}{icon_height},
      $image_stats{$file}{src_width}, $image_stats{$file}{src_height} )
    = &makethumb(&srcfile($file),&thumbfile($file));
    $changes++;
  } elsif ( $files{file} == -1 ) {
    # remove file?
    #print "$file (bad thumb)\n";
    $changes++;
  } else { 
    #print "$file ($files{$file})\n";
  }
}

# If we have found changes ... rebuild the page

if ( $changes ) {
  &grab_stats;
  &grab_icons;
  
  my $table = &make_table;
  &make_page($table);
}

### Subroutines

sub clean_date {
    my @time = localtime(shift @_);
    my $month = $months[$time[4]];
    my $year  = $time[5] + 1900;
    return "$month $time[3], $year";
}

sub clean_size {
  my $bytes = shift @_;
  my $out;

  if ($bytes < 1024) {
    $out = "$bytes bytes";
  } elsif ($bytes < 1024 * 1024) {
    $out = ( int( ( $bytes * 100 ) / ( 1024               ) ) / 100 ) . ' K';
  } elsif ($bytes < 1024 * 1024 * 1024) {
    $out = ( int( ( $bytes * 100 ) / ( 1024 * 1024        ) ) / 100 ) . ' Mb';
  } else {
    $out = ( int( ( $bytes * 100 ) / ( 1024 * 1024 * 1024 ) ) / 100 ) . ' Gb';
  }

  return $out;
}

sub grab_icons {
  for my $file ( keys %files ) {

    next if $image_stats{$file}{icon_width};
    next unless &is_image($file);
    next unless -f &srcfile($file);

    my $image = Image::Magick->new;
    my $ret   = $image->Read(&thumbfile($file));
                warn "$ret" if $ret;
    $image_stats{$file}{icon_width} = $image->Get('width');
    $image_stats{$file}{icon_height} = $image->Get('height');
  }
}

sub grab_stats {
  for my $file ( keys %files ) {
    next if $files{$file} == -1;

    my @stat = stat &srcfile($file);
    my $size = $image_stats{$file}{size} = $stat[7];
    my $date = $image_stats{$file}{date} = $stat[9];
  }
}

sub is_image {
  my $file = shift @_;
  return 1 if $file =~ /\.gif$/i || $file =~ /\.png$/i  ||
              $file =~ /\.jpg$/i || $file =~ /\.jpeg$/i ||
              $file =~ /\.bmp$/i || $file =~ /\.psd$/i  ||
              $file =~ /\.pic$/i || $file =~ /\.pict$/i;
  return 0;
}

sub make_page {
  my $table = shift @_;
  my $out   = &srcfile($filename); 
  open OUTFILE, ">$out";
  print OUTFILE $cgi->start_html({-title=>$title,-bgcolor=>$bgcolor}),
                $cgi->font({-face=>'Arial',-size=>5},$title),
                $cgi->hr({-noshade=>1}), $cgi->center($table),
                $cgi->end_html;
  close OUTFILE;
  print "Wrote \"$out\"\n";
}

sub make_table {
  my @dirs; my @files; my @images;
  for my $file ( sort { $image_stats{$b}{date} <=> $image_stats{$a}{date} } keys %image_stats ) {
    if ( $image_stats{$file}{icon_width} ) {
      push @images, $file;
    } elsif ( -d &srcfile($file) ) {
      push @dirs, $file;
    } else {
      next if $file eq $filename;
      push @files, $file;
    }
  }

  my @chunks;

  for my $dir ( @dirs ) {
    push @chunks, $cgi->a({-href=>$dir},$dir);
  }

  for my $image ( @images ) {
    push @chunks,
      $cgi->a({-href=>$image},
        $cgi->img({
          -border=>0, -src=>&thumblink($image),
          -width=>$image_stats{$image}{icon_width},
          -height=>$image_stats{$image}{icon_height}
        })
      )
      . $cgi->br
      . $cgi->small(
          &clean_date($image_stats{$image}{date}),'-',
          $image_stats{$image}{src_width},'x',
          $image_stats{$image}{src_height},'-',
          &clean_size($image_stats{$image}{size}),$cgi->br, 
          $cgi->a({-href=>$image},$image)
      );
  }

  for my $file ( @files ) {
    push @chunks, $cgi->a({-href=>$file},$file);
  }

  my $columns = 3;
  my @rows;

  while (@chunks) {
    my @cells;
    for (my $i = 0; $i < $columns; $i++) {
      push @cells, $cgi->td({-align=>'center'},
       ( @chunks ? shift @chunks : '&nbsp;' )
      );
    }
    push @rows, $cgi->Tr(@cells);
  }

  return $cgi->table({-cellpadding=>10},@rows);
}

sub makethumb {
  my $file      = shift @_;
  my $thumbfile = shift @_;
  
  my $image = Image::Magick->new;
  my $ret   = $image->Read($file);
              warn "$ret" if $ret;
 
  my $src_width  = $image->Get('width' );
  my $src_height = $image->Get('height');

  if ( $src_height < $size && $src_width < $size ) {
    # It's a small images. There's no need to resize.
  } elsif ( $src_height > $src_width) {
    my $newwidth = int (($size / $src_height) * $src_width);
    $image->Scale(height=>$size,width=>$newwidth);
  } else {
    my $newheight = int (($size / $src_width) * $src_height);
    $image->Scale(height=>$newheight,width=>$size);
  }

  my $icon_width  = $image->Get('width' );
  my $icon_height = $image->Get('height');

  $image->Write($thumbfile);

  return ($icon_width, $icon_height, $src_width, $src_height);
}

sub srcfile {
  my $file = shift @_;
  return $dir.'/'.$file;
}

sub thumbfile {
  my $file = shift @_;
  return $dir.'/'. &thumblink($file);
}

sub thumblink {
  my $file = shift @_;
  return $thumbdir .'/'. $file .'.jpg';
}
