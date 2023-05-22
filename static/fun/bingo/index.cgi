#!/usr/bin/perl -I/home/httpd/html/crescendo.net/main/fun/bingo/lib

use Bingo;
use CGI;
use strict;

my $bin = new Bingo;
my $cgi = new CGI;

my @param = split '/', $cgi->path_info;

if ( $param[1] and $param[1] =~ /^(\d+)$/ ) {
  my $id = $1;
  print $cgi->header, 
        $cgi->start_html( -title=>'Crescendo.net - BINGO!', -bgcolor=>'#FFFFFF' ),
        $cgi->center(
          $cgi->img({-width=>422,-height=>502,-src=>'http://www.crescendo.net/fun/bingo/bingo.cgi/'.$id}),
          $cgi->br,
          $cgi->font({-size=>1},'[',$cgi->a({-href=>'http://www.crescendo.net/fun/bingo/'},'back to main'),']'),
        ),
        $cgi->end_html;
} else {
  my ( $total, $counts ) = $bin->totals();
  my $num_types = scalar( keys %$counts );
  my $cards = $bin->cards();
  my @popular = sort { $counts->{$b} <=> $counts->{$a} || lc($cards->{$a}) cmp lc($cards->{$b}) || $a <=> $b } keys %$counts;

  print $cgi->header, 
      $cgi->start_html( -title=>'Crescendo.net - BINGO!', -bgcolor=>'#FFFFFF' ),
      $cgi->font({-size=>'+5'},'BINGO!'),
      $cgi->hr({-noshade=>undef}),
      $cgi->p({-align=>'center'},"With $num_types different card subjects, over $total bingo cards have been generated!"),
      $cgi->ul(
        map { $cgi->li('(' . $counts->{$_} . ' cards)',
              $cgi->a({-href=>'http://www.crescendo.net/fun/bingo/index.cgi/' . $_}, $cards->{$_} . ' Bingo')) } @popular
      ),
      $cgi->end_html;
}
