package Bingo;
$Bingo::VERSION='$Revision: 1.5 $';

use DBI;
use strict;

sub new {
  my $self = {};
  bless $self;
  return $self;
}

=head3 dbh()

Returns the DB handle to the bingo card database.

=cut

sub dbh {
  my $self = shift @_;
  if ( not defined $self->{dbh} ) {
    $self->{dbh} = DBI->connect(qw/dbi:mysql:dbname=bingo bi ngo/);
  }
  return $self->{dbh};
}

=head3 access($id)

Increments the access count for that bingo card.

=cut

sub access {
  my $self = shift @_;
  my $id   = shift @_ || return undef;

  my $dbh = $self->dbh();
  my $sql = 'update access set count=(count+1) where id=?';
  my $sth = $dbh->prepare($sql);
  my $ret = $sth->execute($id);

  return $ret;
}

=head3 cards()

Returns a hashref of all card id's and their titles.

=cut

sub cards {
  my $self = shift @_;
  my %cards;

  my $dbh = $self->dbh();
  my $sql = 'select id, title from info';
  my $sth = $dbh->prepare($sql);
  my $ret = $sth->execute;

  while ( my $ref = $sth->fetchrow_arrayref ) {
    $cards{$ref->[0]} = $ref->[1];
  }

  return \%cards;
}

=head3 get($id)

Returns a complex has reference for everything about the given card.

=cut

sub get {
  my $self = shift @_;
  my $id   = shift @_;

  my $dbh = $self->dbh();
  my $sql = 'select * from info where id=?';
  my $sth = $dbh->prepare($sql);
  my $ret = $sth->execute($id);

  my $ref = $sth->fetchrow_hashref;
  my %get = %$ref; # Copy! Not a reference. 

  $sth->finish;

  $sql = 'select tile from tiles where id=?';
  $sth = $dbh->prepare($sql);
  $ret = $sth->execute($id);

  $get{tiles} = [];

  while ( my $ref = $sth->fetchrow_arrayref ) {
    push @{$get{tiles}}, $ref->[0];
  }

  return \%get;
}

=head3 totals()

Return access total in scalar mode. Or acces total and a hashref of totals by card in list mode.

=cut

sub totals {
  my $self = shift @_;
  my $total = 0;
  my %totals = ();

  my $dbh = $self->dbh();
  my $sql = 'select id, count from access';
  my $sth = $dbh->prepare($sql);
  my $ret = $sth->execute;

  while ( my $ref = $sth->fetchrow_arrayref ) {
    $total += $ref->[1];
    $totals{$ref->[0]} = $ref->[1];
  }

  return wantarray ? ( $total, \%totals ) : $total;
}

1;
