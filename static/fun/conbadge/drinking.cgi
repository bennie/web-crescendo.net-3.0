#!/usr/bin/perl

use CGI;
use CGI::Carp qw/fatalsToBrowser/;
use strict;

### Handle errors quickly

my $cgi = new CGI;
my $badgename = $cgi->param('badgename');

if ( $badgename ) {
  print $cgi->header;
} else {
  print $cgi->redirect('index.html');
  exit;
}

my $version = ( split ' ', '$Revision: 1.22 $')[1];

### TESTS

my %animals;

$animals{aquatic}   = [ qr/fish/i, qr/orca/i ];
$animals{badger}    = [ qr/badger/i ];
$animals{bat}       = [ qr/bat/i ];
$animals{bear}      = [ qr/bear/i, qr/panda/i ];
$animals{bird}      = [ qr/bird/i, qr/crow/i, qr/raven/i ];
$animals{buffalo}   = [ qr/buffalo/i ];
$animals{cat}       = [ qr/[ckq]at/i, qr/kitten/i, qr/kitty/i, qr/tabbie/i ];
$animals{cheetah}   = [ qr/cheetah/i ];
$animals{chipmunk}  = [ qr/chipmunk/i ];
$animals{cougar}    = [ qr/couga?r/i ];
$animals{coyote}    = [ qr/([ck]o)?yote/i ];
$animals{deer}      = [ qr/deer/i ];
$animals{dog}       = [ qr/can[iu]{0,2}s/i, qr/collie/i, qr/dog/i, qr/husky/i, qr/pup(py)?/i, qr/hound/i, qr/canine/i, qr/dingo/i ];
$animals{dragon}    = [ qr/dra[cg]on/i, qr/hydra/i, qr/wyvern/i ];
$animals{ferret}    = [ qr/ferret/i ];
$animals{fox}       = [ qr/fawks/i, qr/(ph|f)ox+y?/i, qr/fennec/i, qr/kitsune/i, qr/vixen/i, qr/vulpin(e)?/i, qr/vulpe(s)?/i ];
$animals{gazelle}   = [ qr/gazelle/i ];
$animals{goat}      = [ qr/goat/i ];
$animals{gryphon}   = [ qr/gryphon/i, qr/griff[io]n/i ];
$animals{horse}     = [ qr/horse/i, qr/pon[iy]/i ];
$animals{hyena}     = [ qr/hyena/i ];
$animals{jaguar}    = [ qr/jaguar/i ];
$animals{jackal}    = [ qr/jackal/i ];
$animals{koala}     = [ qr/koala/i ];
$animals{lion}      = [ qr/lion/i ];
$animals{lizard}    = [ qr/lizard/i ];
$animals{lynx}      = [ qr/lynx/i ];
$animals{mouse}     = [ qr/mous(i)?e/i ];
$animals{otter}     = [ qr/otter/i ];
$animals{panther}   = [ qr/panther/i ];
$animals{rabbit}    = [ qr/rabbit/i, qr/bunny/i, qr/bunnie/i, qr/bunn\b/i, qr/lapine/i ];
$animals{racoon}    = [ qr/(ra)?coon/i ];
$animals{rat}       = [ qr/rat/i ];
$animals{roo}       = [ qr/kangaroo/i, qr/roo\b/i ];
$animals{sheep}     = [ qr/sheep/i, qr/lamb/i ];
$animals{skunk}     = [ qr/skunk(ie)?/i ];
$animals{snake}     = [ qr/snake/i, qr/python/i ];
$animals{squirrel}  = [ qr/squirrel/i ];
$animals{tiger}     = [ qr/t[iy]g(re|e?r)/i, qr/tora/i ];
$animals{turtle}    = [ qr/turtle/i ];
$animals{unicorn}   = [ qr/unicorn/i ];
$animals{weasel}    = [ qr/weasel/i, qr/mongoose/i ];
$animals{wolf}      = [ qr/(v|wh|w)+(0|o|ou|u|y)+(l*(f|ph|(?<!vol)v))+(ei?|ie|in|y)?/i, qr/lupin(e)?/i, qr/fenris/i ];
$animals{woodchuck} = [ qr/woodchuck/i ];
$animals{zebra}     = [ qr/zebra/i ];

### Colors & metals

my %colors;
map {$colors{$_} = [ qr/$_/i ];} qw/black blue brown emerald green grey orange red white yellow rainbow/;

$colors{purple} = [ qr/pu?rple?/i ];

my %metals;
map {$metals{$_} = [ qr/$_/i ];} qw/brass cobalt copper gold iron metal silver/;

my %seasons;
map {$seasons{$_} = [ qr/$_/i ];} qw/spring summer fall winter/;

my %elements;
map {$elements{$_} = [ qr/$_/i ];} qw/earth wind fire flame water ice/;

my %celestials;

$celestials{angel}   = [ qr/angel/i ];
$celestials{gods}    = [ qr/anubis/i, qr/osiris/i, qr/sirius/i, qr/fenris/i ];
$celestials{demon}   = [ qr/demon/i ];
$celestials{god}     = [ qr/god/i ];

$celestials{moon}    = [ qr/moon/i ];
$celestials{thunder} = [ qr/thunder/i ];
$celestials{rainbow} = [ qr/rainbow/i ];
$celestials{sky}     = [ qr/\bsky/i ];
$celestials{shadow}  = [ qr/shadow/i ];
$celestials{snow}    = [ qr/snow/i ];
$celestials{star}    = [ qr/star/i ];
$celestials{storm}   = [ qr/storm/i ];
$celestials{sun}     = [ qr/\bsun/i ];

my %opts;
$opts{cutesy}   = [ qr/fluffy/i, qr/fur(ry)?(vert)?/i, qr/fuzzy/i, qr/yiff/i, qr/sparkl[ey]/i, qr/wyld/i  ];
$opts{dark}     = [ qr/dark/i ];
$opts{Dorsai}   = [ qr/\b\(?di\)?\b/i, qr/dorsai/i ];
$opts{pedantic} = [ qr/\bthe\b/i ];
$opts{size}     = [ qr/mega/i, qr/micro/i, qr/magna/i, qr/little/i, qr/tiny/i, qr/mini/i ];
$opts{title}    = [ qr/baron/i, qr/sir/i, qr/captain/i, qr/lord/i ];

$opts{hyphen}   = [ qr/-/i ];
$opts{'multiple apostrophes'}   = [ qr/'.+?'/i ];

# Drink for every umlaute

## Assemble the tests

my %tests;

$tests{animal}    = \%animals;
$tests{color}     = \%colors;
$tests{metal}     = \%metals;
$tests{season}    = \%seasons;
$tests{element}   = \%elements;
$tests{celestial} = \%celestials;

$tests{'heavy drinker item'} = \%opts if $cgi->param('heavy') eq 'on';

### Done with test

print $cgi->start_html( -title => 'Your drinking score.', -bgcolor=>'#FFFFFF' );

my $drinks = 0;
my %matches;

for my $category ( keys %tests ) {
  for my $type ( keys %{$tests{$category}} ) {
    for my $test (@{$tests{$category}{$type}}) {
      while ( $badgename =~ /($test)/g ) { 
        $drinks++;
        $matches{$category}{$type}{$1}++;
      }
    }
  }
}

my $score = '
<center><table width="500" style="border:1px solid black; background-color:white; color:black;">
<tr><td align="center">

<font size="5">The Furry ConBadge Drinking Game</font><br /><br />
<img src="http://www.crescendo.net/fun/conbadge/drinkgame2.jpg" width=300 height=201 /><br /><br />

<small>My badgename</small><br />
<tt><b><font size="6">'.$badgename.'</font></b></tt><br />
<small>is worth</small><br />
<b><font size="5">'.$drinks.' drink'.($drinks == 1 ? '':'s').'!</font></b><br /><br /><tt>';

if ( $drinks < 1 ) {
  $score .= "It looks like you've got a fairly creative badge name.<br />No drinks for you.<br />";
} else {
  for my $category ( sort keys %matches ) {
    for my $type ( sort keys %{$matches{$category}} ) {
      for my $match ( sort keys %{$matches{$category}{$type}} ) {
        $score .= "<i><u>$match</u></i> is $category ($type) and is worth a drink!" . $cgi->br;
      }
    }
  }
}

$score .= '<br /></tt>
<small><a href="http://www.crescendo.net/fun/conbadge/">http://www.crescendo.net/fun/conbadge/</a> v'.$version.'</small>
</td></tr></table>';

print $score;

# Final cleanup of score
$score .= '<form action="http://www.crescendo.net/fun/conbadge/drinking.cgi">
<input type="text" name="badgename" /><input type="submit" value="Check my badgename!" /><br />
<small><input type=checkbox name=heavy checked /> I\'m a heavy drinker</small>
</form></center>';


$score =~ s/\n//g;

print "<br /><br />";

print '<b>Share your score on your blog, LJ, etc:</b><br><textarea rows=5 cols=60 onclick=\'this.select();\'>',
      $score, '</textarea><br /><b>Click in the pane above, and copy and paste into your journal!</b>';

print "<br /><br /><br />";

print '<form action="drinking.cgi">
<input type="text" name="badgename" /><input type="submit" value="Check another!" /><br />
<input type=checkbox name=heavy checked /> I\'m a heavy drinker
</form>';

print "<br /><small>The rules are <a href=\"index.html\">here</a>.</small>";

print $cgi->end_html;

open OUTFILE, '>>', '/var/www/crescendo.net/main/fun/conbadge/badges.log';
print OUTFILE time, "\t$version\t$badgename\n";
close OUTFILE;