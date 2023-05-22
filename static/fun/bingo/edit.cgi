#!/usr/bin/perl -I/home/httpd/html/crescendo.net/main/fun/bingo/lib

use Bingo;
use CGI;
use strict;

my $bin = new Bingo;
my $cgi = new CGI;
my $dbh = $bin->dbh();

print $cgi->header, $cgi->start_html( -bgcolor=>'#FFFFFF', -title=>'Edit' ),
      $cgi->start_form;

if ( my $tiles = $cgi->param('tiles') and my $card = $cgi->param('card') ) {
  &add($card,$tiles);
} elsif ( my $card = $cgi->param('card') ) {
  &edit($card);
} else {
  &default;
}

print $cgi->end_form, $cgi->end_html;

# Subroutines

sub default {
  my $cards = $bin->cards;
  print $cgi->p('Bingo Card:', $cgi->popup_menu(-name=>'card',-values=>[ sort keys %$cards ], -labels=>$cards )),
        $cgi->submit;
}

sub add {
  my $card  = shift @_;
  my $tiles = shift @_;

  my $sql = 'insert into tiles (id,tile) values (?,?)';
  my $dbh = $bin->dbh();
  my $sth = $dbh->prepare($sql);

  for my $tile ( split "\n", $tiles ) {
    chomp $tile;
    my $ret = $sth->execute($card,$tile);
    print $cgi->p('Adding',$cgi->i($tile),"to $card returned $ret.");
  }
}

sub edit {
  my $card = shift @_;
  my $info = $bin->get($card);

  for my $key ( sort keys %$info ) {
    next if $key eq 'tiles';
    print $cgi->p($cgi->b($key),':',$info->{$key});
  }

  print $cgi->p($cgi->b('Current tiles'),':',
        join(', ', @{$info->{tiles}}));

  print $cgi->hidden(-name=>'card',-value=>$card),
        $cgi->textarea(-name=>'tiles',-colums=>30,-rows=>10),
        $cgi->submit;
}
