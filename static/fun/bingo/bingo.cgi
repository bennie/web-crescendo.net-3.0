#!/usr/bin/perl -I/var/www/crescendo.net/main/fun/bingo/lib

use Bingo;
use CGI;
use Image::Magick;
use strict;

my $bin = new Bingo;
my $cgi = new CGI;

my @param = split '/', $cgi->path_info;

my $back_color   = 'lightsteelblue';
my $frame_color  = 'black';
my $text_color   = 'black';
my $title_color  = 'rgb(29,97,182)';
my $shadow_color = 'black';

my $title;
my $face_image;
my @phrases;
my @queue;

my $id = 1;
$id = 2  if $param[1] =~ /^giza$/i;
$id = $1 if $param[1] =~ /^(\d+)$/;

$bin->access($id);
my $card = $bin->get($id);

$title = $card->{title} . ' Bingo';
$face_image = $card->{face};
@phrases = @{$card->{tiles}};

my $face = new Image::Magick;
my $ret = $face->Read($face_image);
warn $ret if $ret;

my $img = new Image::Magick;

$ret = $img->Set(size=>'420x500');
warn $ret if $ret;
$ret = $img->ReadImage("xc:$back_color");
warn $ret if $ret;
$ret = $img->Frame(width=>1,height=>1,fill=>$frame_color);
warn $ret if $ret;

### Card Title

$ret = $img->Annotate(text=>$title,fill=>$shadow_color,align=>'center',x=>202,y=>62,style=>'Italic',pointsize=>52);
warn $ret if $ret;
$ret = $img->Annotate(text=>$title,fill=>$title_color,align=>'center',x=>200,y=>60,style=>'Italic',pointsize=>52);
warn $ret if $ret;

### Center face

$ret = $img->Composite(image=>$face,x=>175,y=>260);
warn $ret if $ret;

for my $x_count ( 0 .. 4 ) {
  for my $y_count ( 0 .. 4 ) {
    my $x1 = 15 + ( 80 * $x_count );
    my $x2 = $x1 + 70;
    my $y1 = 100 + ( 80 * $y_count );
    my $y2 = $y1 + 70;

    if ( $x_count==2 and $y_count==2 ) {
      $ret = $img->Draw(primitive=>'rectangle',stroke=>$frame_color,
                         points=>"$x1,$y1 $x2,$y2");
      warn $ret if $ret;
    } else { 
      $ret = $img->Draw(primitive=>'rectangle',stroke=>$frame_color,
                        fill=>'white',points=>"$x1,$y1 $x2,$y2");
      warn $ret if $ret;
      &notate(($x1+35),($y1+35));    
    }
  }
}

print $cgi->header(-type=>'image/jpeg');

binmode STDOUT;
print $img->Write('jpeg:-');

### Subroutines

sub notate {
  my $x = shift @_;
  my $y = shift @_;

  my $font_height = 14;
  my @words = split /\s+/, &phrase;

  my @out;

  if ( scalar(@words) == 1 ) {
    my $sx = $x;
    my $sy = $y + int($font_height/2);
    push @out, [ $sx, $sy, $words[0] ];
  } elsif ( scalar(@words) % 2 ) { # odd num of words
    my $middle = int(scalar(@words)/2);
    my $sx = $x;
    my $sy = $y + int($font_height/2);
    push @out, [ $sx, $sy, $words[$middle] ];
    for my $sub ( reverse 0 .. ($middle-1) ) {
      $sy -= $font_height;
      push @out, [ $sx, $sy, $words[$sub] ];
    }
    $sy = $y + int($font_height/2);
    for my $sub ( ($middle+1) .. $#words ) {
      $sy += $font_height;
      push @out, [ $sx, $sy, $words[$sub] ];  
    }
  } else { # even number of words
    my $middle = int(scalar(@words)/2);
    my $sx = $x;
    my $sy = $y + $font_height;
    for my $sub ( reverse 0 .. ($middle) ) {
      push @out, [ $sx, $sy, $words[$sub] ];
      $sy -= $font_height;
    }
    $sy = $y + $font_height;
    for my $sub ( ($middle+1) .. $#words ) {
      $sy += $font_height;
      push @out, [ $sx, $sy, $words[$sub] ];  
    }
  }

  for my $out (@out) {
    my $ret = $img->Annotate(text=>$out->[2],fill=>$text_color,align=>'center',
                             x=>$out->[0],y=>$out->[1]); 
    warn $ret if $ret;
  }
}

sub phrase {
  if ( scalar(@queue) < 1 ) {
    while (@phrases) { push(@queue, splice(@phrases, rand(@phrases), 1)) }
    @phrases = @queue;
  }
  return shift @queue || 'Error';
}
