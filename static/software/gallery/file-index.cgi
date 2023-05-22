#!/usr/bin/perl
#
# file-index.cgi is (c) 2001-2003 by Phillip Pollard
#
# This program is designed to generate a set of web pages to preview an
# FTP site. It creates thumbnails of images and makes them 'purty'.
#
#### Confuscate ################################################################

# This is the configuration section. You should really not edit anything
# else in this file.

my $thisurl  = '/file-index.cgi';

my $icondir  = '/home/httpd/html/macrophile.com/main/code/ftp/icons';
my $iconurl  = '/ftp/icons/';

my $filedir  = '/home/httpd/html/images/';
my $fileurl  = '/images/';

my $cachedir = '/home/httpd/html/cache/';
my $cacheurl = '/cache/';

my $thumbsize = 200;
my $columns   = 4;

my $debug   = 0;
my $rebuild = 1;

### Pragmata ###################################################################

use CGI;
use File::Path;
use HTML::Template;
use Image::Magick;
use Digest::MD5 qw/md5_hex/;
use strict;

### Bootstrap ##################################################################

my $cgi    = new CGI;
my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my $time   = scalar localtime(time);

### MAIN #######################################################################

print $cgi->header;

my $request = $cgi->path_info || '/';
my $work_filedir  = &clean($filedir,$request);
my $work_fileurl  = &clean($fileurl,$request);
my $work_cachedir = &clean($cachedir,$request);
my $work_cacheurl = &clean($cacheurl,$request); 

if ( -d $work_filedir ) {  
  &make_cache unless &check_cache;
  &display_cache;
} else {
  print $cgi->start_html,
        $cgi->p("$request doesn't make sense or doesn't exist" ),
        $cgi->end_html;
}

### Controller subroutines #####################################################

sub check_cache {
  return 0 unless $work_cachedir; # Check if cache dir exists
  return 0 unless &cache_md5;     # Check for a cached md5
  return 0 unless &file_md5;      # Check for a file md5
  return 0 if $rebuild;           # Force rebuilds?
  return &file_md5 eq &cache_md5 ? 1 : 0;
}

sub display_cache {
  open DISPLAY, &clean($work_cachedir,'info.html');
  print <DISPLAY>;
  close DISPLAY;
}

sub make_cache {
  mkpath($work_cachedir);                       # Make the directory
  unlink <&clean($work_cachedir,'checksum.*')>; # Remove old checksums

  # Make the checksum
  open  CHECKSUM, '>'.&clean($work_cachedir,'checksum.'.&file_md5);
  print CHECKSUM $time;
  close CHECKSUM;

  my @dirs = my @files = my @images = ();
  for my $candidate (&file_files) {
    next if $candidate =~ /^\./;
    push @dirs,   $candidate if -d &clean($work_filedir,$candidate);
    push @images, $candidate if -f &clean($work_filedir,$candidate) && &is_image($candidate);
    push @files,  $candidate if -f &clean($work_filedir,$candidate) && ! &is_image($candidate);
  }

  my @thumbs;
  for my $image (@images) {
    my $imagefile = &clean($work_filedir,$image);
    my $thumbfile = &clean($work_cachedir,$image.'.jpg');
    my ($x1,$y1,$x2,$y2) = &make_thumb($imagefile,$thumbfile);
    push @thumbs, [
      $cgi->img({-width=>$x1,-height=>$y1,-src=>&clean($work_cacheurl,$image.'.jpg')}),
      $cgi->a({-href=>&clean($work_fileurl,$image)},$image).$cgi->br.'('.$x2.'x'.$y2.')'
    ];
  }

  my @rows;

  while (@thumbs) {
    my @row1;  my @row2;
    for ( 1 .. $columns ) {
      my $ref = $thumbs[0] ? shift @thumbs : ['&nbsp;','&nbsp;'];
      push @row1, $cgi->td({-align=>'center'},$ref->[0]);
      push @row2, $cgi->td({-align=>'center'},$ref->[1]);
    }
    push @rows, $cgi->Tr(@row1), $cgi->Tr(@row2);
  }

  open  MAINPAGE, '>'.&clean($work_cachedir,'info.html');
  print MAINPAGE
    $cgi->start_html,
    $cgi->p("\&check_cache returned:",&check_cache),
    $cgi->p("MD5 Sum of cache dir:",&cache_md5),
    $cgi->p("MD5 Sum of file dir:",&file_md5),
    $cgi->p({-align=>'center'},$cgi->table({-bgcolor=>'#999999'},@rows)),
    $cgi->p('DIRS:',  (join ', ',(map { $cgi->a({-href=>&clean($thisurl,$request,$_)},$_) } @dirs))),
    $cgi->p('FILES:', (join ', ', @files)),
    $cgi->end_html;
  close MAINPAGE;
}

### Files and MD5s #############################################################

my @cache;

sub cache_files {
  @cache = &readdir($work_cachedir) unless @cache;
  return @cache;
}

my $cache;

sub cache_md5 {
  if ( ! $cache ) {
    map { $cache = $1 if $_ =~ /^checksum\.(.*)$/ } &cache_files;
  }
  return $cache;
}

my @files;

sub file_files {
  @files = &readdir($work_filedir) unless @files;
  return @files;
}

my $files;

sub file_md5 {
  $files = md5_hex(&file_files) unless $files;
  return $files;
}

### Subroutines ################################################################

### clean : Assembles and returns a clean FS handle. (slashes squashed)

sub clean { 
  my $dir = join '/', @_;
     $dir =~ s/\/\/+/\//g;
  return $dir;
}

### clean_date : Returns a preety date from a raw UTC date

sub clean_date {
    my @time = localtime(shift @_);
    my $month = $months[$time[4]];
    my $year  = $time[5] + 1900;
    return "$month $time[3], $year";
}

### clean_size : returns a preety version of size given an input in bytes

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

### image_size : returns an images size via Image Magick routines.

sub image_size {
  my $file   = shift @_;
  my $image  = Image::Magick->new;
  my $ret    = $image->Read($file);
     warn      "$ret\n" if $ret;
  my $width  = $image->Get('width' );
  my $height = $image->Get('height');
     return    ($width, $height);
}

### is_image : is it an image?

sub is_image {
  my $file = shift @_;
  if ( $file =~ /.bmp$/i || $file =~ /.gif$/i || $file =~ /.jpg$/i ||
       $file =~ /.png$/i || $file =~ /.psd$/i ) { return 1 } else { return 0 }
}

### Makes a thumbnail or uses existing. Returns (filex,filey,thumbx,thumby)

sub make_thumb {
  my $file      = shift @_;
  my $thumbfile = shift @_;

  # Faster? (skip routine)
  if (-r $thumbfile) { 
    return &image_size($thumbfile), &image_size($file);
  }

  my $image  = Image::Magick->new;
  my $ret    = $image->Read($file);
  my $width  = $image->Get('width' );
  my $height = $image->Get('height');

  if ($height > $thumbsize || $width > $thumbsize ) {
    if ($height > $width) {
      my $newwidth = int (($thumbsize / $height) * $width);
      $image->Scale(height=>$thumbsize,width=>$newwidth);
    } else {
      my $newheight = int (($thumbsize / $width) * $height);
      $image->Scale(height=>$newheight,width=>$thumbsize);
    }
  }

  my $new_width  = $image->Get('width' );
  my $new_height = $image->Get('height');

  $image->Write($thumbfile);
  
  return ($new_width, $new_height, $height, $width);
}

### readdir : returns an array of files in a dir

sub readdir {
  my $dir = shift @_;
  opendir READDIR, $dir;
  return grep !/^\.$/, grep !/^\.\.$/, readdir READDIR;
  closedir READDIR; 
}

=head1 cut

$debug && do { print "Debug on...\n"; };

### Load up icons
my %icons = &grab_icons($icondir);
$debug && do { print "--> ", scalar(keys %icons), " icons loaded.\n"; };

### Prep the DB
my $start = &db_prep;
$debug && do { print "--> $start rows currently in the table.\n"; };

&make_index('/');

my $end = &db_clean;

sub make_index {
  my $dir     = &clean(shift @_    );
  my $in_dir  = &clean($indir,$dir );
  my $out_dir = &clean($outdir,$dir);

  $debug && do { print "$debug_header| $dir\n|$debug_line|\n"; };

  ### First read the files in the directory
  my ($files, $subdirs) = &grab_dir($in_dir);
  my @subdirs  = sort @{ $subdirs };
  my @files    = sort @{ $files   };

  ### Check the cache directory
  my $mkdir = $out_dir;
  if (! -d $mkdir) {
    $debug && do { print "| Makeing DIR $mkdir\n"; };
    mkdir $mkdir; 
  } else {
    $debug && do { print "| Useing DIR $mkdir\n"; };
  }

  ### Create the thumbnails and HTML
  $debug && do { 
    print '| ';
    printf "%68.68s", &clean($urldir,$dir,'/index.html');
    print " |\n| ";
    printf "%68.68s", scalar(@subdirs).' subdirs';
    print " |\n";
  };

  # Assemble HTML chunks, subdirs first
  push my @subdir_chunks, &chunk_subdirs($dir,@subdirs);

  # Get file info
  my %info = %{ &get_fileinfo($in_dir,$out_dir,$dir,@files) };

  # Create page(s)

  # Sorted by date
  my $line = $cgi->Tr(
               $cgi->td({-colspan=>3,-align=>'right'},
                 '[ sort by date |',
                 $cgi->a({-href=>'alpha.html'},'sort by name'),
                 ']'
               )
             );
  my @keys = sort { # Sort by date, then name 
               $info{$b}{'mtime'} cmp $info{$a}{'mtime'} 
               || $a cmp $b
               || $info{$a}{'size'} cmp $info{$b}{'size'}
             } keys %info;
  my @file_chunks = &chunk_files(\@keys,\%info);
  if (@file_chunks < 1) { $line = ''; }
  my $html = &clean($outdir,$dir,'/index.html');
  &make_page($html,$dir,$line,@subdir_chunks,@file_chunks);

  # Sorted by alpha
  $line = $cgi->Tr(
            $cgi->td({-colspan=>3,-align=>'right'},
              '[',
              $cgi->a({-href=>'index.html'},'sort by date'),
              '| sort by name ]'
            )
          );
  @keys = sort { lc($a) cmp lc($b) } keys %info;
  @file_chunks = &chunk_files(\@keys,\%info);
  if (@file_chunks < 1) { $line = ''; }
  $html = &clean($outdir,$dir,'/alpha.html');
  &make_page($html,$dir,$line,@subdir_chunks,@file_chunks);

  # Undefine outstanding variables to make the recusion less memory
  # intensive

  undef $in_dir, $out_dir, $mkdir;     # Directory info
  undef @files;                        # Sub files
  undef @subdir_chunks, @file_chunks,  # File info and HTML
        %info, @keys, $html;
  
  $debug && do { print "\\$debug_line/\n\n"; };

  # Institute recursion
  for my $recursion_trick (@subdirs) {
    # Go boom here
    &make_index(&clean($dir,$recursion_trick));
  }
}

=cut

=head2 blarg 


### chunk_files : takes information from %info and returns HTML chunks

sub chunk_files {
  my @keys = @{ shift @_ };
  my %info = %{ shift @_ };

  my @chunks;
  for my $file (@keys) {
    my $text = $cgi->a({-href=>$info{$file}{'link'}},
                 $cgi->img({-border => 0,
                           -height  => $info{$file}{'thumb_height'},
                           -width   => $info{$file}{'thumb_width'},
                           -src     => $info{$file}{'thumb'}
                          })
               )
             . $cgi->br;

    # Assemble the tag line with the right data

    my $tag = $info{$file}{'date'};
    if ($info{$file}{'orig_width'} && $info{$file}{'orig_height'}) {
      $tag .= ' - ' 
           .  $info{$file}{'orig_width'}
           .  ' x '
           .  $info{$file}{'orig_height'};
    }
    $tag .= ' - '
         .  $info{$file}{'size'};

    $tag =~ s/ /&nbsp;/g;

    # attach it

    $text .= $cgi->font({-size=>1,-face=>'Arial'},
               $tag,
               $cgi->br,
               $cgi->a({-href=>$info{$file}{'link'}},$file)
             );
          
    push @chunks, $text;
  }

  return @chunks;
}

### chunk_subdirs : returns HTML chunks for subdirectories

sub chunk_subdirs {
  my $dir     = shift @_;
  my @subdirs =       @_;
  my @chunks;

  foreach my $sub (@subdirs) {
    my ($icon,$width,$height) = &iconify('directory');
    my $text = 
        $cgi->a({-href=>&link($urldir,$dir,$sub)},
          $cgi->img({-height=>$height,-width=>$width,-border=>0,
                     -src=>&link($icon)
                   })
        )
      . $cgi->br
      . $cgi->a({-href=>&link($urldir,$dir,$sub)},$sub);
    push @chunks, $text;

  }

  return @chunks;
}

### get_fileinfo : retrieves file information via stat and assembles %info

sub get_fileinfo {
  my $in_dir  = shift @_;
  my $out_dir = shift @_;
  my $dir     = shift @_;
  my @files   =       @_;

  my %info;

  # Now files
  foreach my $file (@files) {
    my $namefile   = $file;

    my $sourcefile = &clean($in_dir,$file);
    my $thumbfile  = &clean($out_dir,$file);

   # Read file size and moified time

    my @fileinfo = stat $sourcefile;

    $info{$file}{'date'}  = &clean_date($fileinfo[9]);
    $info{$file}{'mtime'} = $fileinfo[9];
    $info{$file}{'size'}  = &clean_size($fileinfo[7]);

    $info{$file}{'link'} = &link($linkdir,$dir,$file);

    ### If you can make a thumbnail, do so and record info
    
    if ( $sourcefile =~ /.bmp$/i ||
         $sourcefile =~ /.gif$/i || 
         $sourcefile =~ /.jpg$/i || 
         $sourcefile =~ /.png$/i || 
         $sourcefile =~ /.psd$/i    ) {

      if ($thumbfile =~ /.psd$/i || $thumbfile =~ /.bmp$/i) { 
        $namefile  .= '.jpg'; 
        $thumbfile .= '.jpg'; 
      }

      ($info{$file}{'thumb_width'}, $info{$file}{'thumb_height'},
       $info{$file}{'orig_width'},  $info{$file}{'orig_height'}
      ) = &makethumb($namefile,$sourcefile,$thumbfile);

      if ($info{$file}{'thumb_width'}  == 0 &&
          $info{$file}{'thumb_height'} == 0
      ) { next; }
 
      $info{$file}{'thumb'} = &link($urldir,$dir,$namefile);
      
    } else { 

      ### If unknown file type, use the appropriate icon

      $file =~ /\.(\w+)$/;

      (my $icon, $info{$file}{'thumb_width'}, $info{$file}{'thumb_height'}
      ) = &iconify($1);

      $info{$file}{'orig_width'}  = 0;
      $info{$file}{'orig_height'} = 0;
      $info{$file}{'thumb'}       = &link($icon);
    }
  }

  return \%info;
}

#####> GRAB_ICONS
#> Grabs all the information and names of icons loaded in the icon
#> directory.

# This will be used later by the 'iconify' routine to post icons for
# non-image files. Rather than checking size on every pass, a single
# pass builds a handy reference hash and thus saves CPU cycles. Icons are
# named on extension keyed (IE the icon for mp3s is 'mp3.gif') Gifs only
# at the moment. They are the optimized icon size. Icons larger than
# default thumbnail sizes look really stupid but can be used.

sub grab_icons {
  my $icondir = shift @_;

  my %icons;

  opendir ICONDIR, $icondir;
  foreach my $icon (readdir ICONDIR) {
    next unless $icon =~ /\.gif$/i;
    my ($width,$height) = &get_image_size(&clean($icondir,$icon));
    $icon =~ /^(.*)\.gif$/;
    $icons{$1}= [ $width,$height ];
  }
  closedir ICONDIR;

  return %icons;
}

#####> ICONIFY
#> Returns a URL directory, height and width of the appropriate icon for
#> the submitted directory extension. ('directory' and 'unknown' are
#> special cases.

sub iconify {
  my $type = shift @_;
  my $test = &clean($icondir,$type.'.gif');
     $type = 'unknown' unless -r $test;
  return &clean($iconurl,$type.'.gif'), @{ $icons{$type} };
  # previous line is an ugly form of: return $icon,$width,$height
}

######> LINK

sub link {
  my $out =  &clean(@_);
     $out =~ s/ /%20/g;
  return $out;
}

#####> MAKE_PAGE 
#> Given an output location, filetree location (for title and headers),
#> and "chunks" of HTML code representing thumbnails and icons, this 
#> routine assembles and writes the corresponding HTML directory index.

sub make_page {
  my $html   = shift @_;
  my $dir    = shift @_;
  my $line   = shift @_;
  my @chunks =       @_;

  $debug && do { 
    print '| ';
    printf "%25.25s", $html;
    print  ' | ';
    printf "%14.14s", 'N/A'; 
    print  ' | ';
    printf "%14.14s", 'N/A'; 
    print  ' | ';
  };

  # Assemble the chunks into a table
 
  my $tabletext;
  while (@chunks) {
    my $line = $cgi->td({-align=>'center',-width=>250}, shift @chunks );

    if (@chunks) {
      $line .= $cgi->td({-align=>'center',-width=>250}, shift @chunks );
    } else {
      $line .= $cgi->td({-align=>'center',-width=>250},'&nbsp;');
    }

    if (@chunks) {
      $line .= $cgi->td({-align=>'center',-width=>250}, shift @chunks );
    } else {
      $line .= $cgi->td({-align=>'center',-width=>250},'&nbsp;');
    }

    $tabletext .= $cgi->Tr($line);
  }

  # Assemble the body

  my $body = $macro->{'start_table'}
           . $cgi->Tr(
               $cgi->td({-bgcolor=>'#003300'},
                 $cgi->font({-face=>'Arial',-color=>'#FFFFFF',-size=>5},
                   "FTP Index - $dir"
                 ),
               )
             )
           . $cgi->Tr(
               $cgi->td({-bgcolor=>'#FFFFFF'},
                 $cgi->table({-bgcolor=>'#999999',-cellspacing=>5,-cellpadding=>5},
                   $line,
                   $tabletext
                 )
               )
             )
           . $macro->{'end_table'};

  # Load it into the template

  my $meta = HTML::Template->new(
             die_on_bad_params => 0,
             scalarref => \$tmpl
           );

  $meta->param(
    title        => "Macrophile FTP Index - $dir",
    body         => $body,

    time         => "Last generated $time",

    html_prefix  => $macro->{'html_prefix'},
    image_prefix => $macro->{'image_prefix'},
    start_table  => $macro->{'start_table'},
    end_table    => $macro->{'end_table'}
  );

  # Fire it out

  open OUTFILE, ">$html";
  print OUTFILE $meta->output;
  close OUTFILE;

  $debug && do { print " done! |\n"; };

  return 1;
}


#####> RELATIVE_DIR
#> Given an absolute directory string, it returns the relative part of the
#> tree structure under which everything is keyed.

sub relative_dir {
  my $dir =  shift @_;
     $dir =~ /$indir(.*)$/;
  my $out = '/' . $1 . '/';
     $out = &clean($out);
  return $out;
}
