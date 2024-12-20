#*************************************************************************

=head1 RCS.pm (RCS)

=head1

=head2 GENERAL INFO:

Basic RCS parser. This file does not rely upon any external utilities to
parse RCS files. Currently it functions with RCS files generate by GNU 
CVS and as documented by the rcsfile(5) man page. There is an astounding
lack of good documentation of this format and most of this is reverse
engineering because I am too lazy to take apart the RCS and CVS code.

=head2 COPYRIGHT: (C) 2001 - $Date: 2002/05/05 02:44:25 $, Phillip Pollard
- Released under GNU Public License

=cut

#*************************************************************************

=head1 USAGE

my $rcs = new RCS;
my $ret = $rcs->load($filename);

my $current = $rcs->recent_version;

=cut

# Document memory structure
#
# - version
# - body
#   - line #
#     - line
#     - origin
#     - new_lines
# - line_map

package RCS;
$RCS::Version = '0.01';

use strict;

sub new {
  my $self = {};
  bless  $self;
  return $self;
}

=head1 METHODS

=item author()

my $author = $rcs->author($version);

The author method returns the author name of the given version. If
no version is given it returns the author of the current loaded version.

=cut

sub author {
  my $self = shift @_;
  my $ver  = shift @_ || $self->version;
  return $self->{rcs}->{$ver}->{author} || undef;
}

=item date()

my $date = $rcs->date($version);

The date method returns the revision date of the given version. If
no version is given it returns the date of the current version.

=cut

sub date {
  my $self = shift @_;
  my $ver  = shift @_ || $self->recent_version;
  return $self->{rcs}->{$ver}->{date} || undef;
}

=item get()

=cut

sub get {
  my $self = shift @_;
  my $ver  = shift @_ || $self->recent_version;
  
  return undef unless $self->{rcs}->{$ver};

  my @chain = $self->_revision_path($self->{current_document}->{version},$ver);

  for my $version ( @chain ) {
    $self->_debug("--> loading delta $version");
    $self->_apply_delta($version);
    $self->_sort;
  }

  return $self->_dump;
}

=item load()

my $ret = $rcs->load($filename);

The load command reads in and parses the given filename. If the
file does not exist or is unreadable by the script, undef is 
returned. Otherwise, 1 is returned upon success.

=cut

sub load {
  my $self      = shift @_;
  $self->{file} = shift @_;
  return undef unless -f $self->{file};

  my $doc_header;
  $self->{rcs} = {};

  $self->_parse_in_rcs($self->{file},$self->{rcs});

  # populate the current doc
  
  $self->{current_document}->{version} = $self->recent_version;

  for my $line ( split /\n/, $self->{rcs}->{$self->recent_version}->{text} ) {
    push @{ $self->{current_document}->{body}->{1}->{new_lines} }, $self->_unquote($line) . "\n";
  }

  # resort it

  $self->_sort;

  return 1;
}

=item notate()

This method builds and assembled statistical information for veriosn.

=cut

sub _grab_note {
  my $self = shift @_;
  my $ref  = shift @_;  
  my $ver = $self->{current_document}->{version};
  for my $line ( keys %{ $self->{current_document}->{body} } ) {
    $ref->{$ver}->{body}->{$line}->{line}   = scalar( split '', $self->{current_document}->{body}->{$line}->{line} );
    $ref->{$ver}->{body}->{$line}->{origin} = $self->{current_document}->{body}->{$line}->{origin};  
  }
  for my $map ( keys %{ $self->{current_document}->{line_map} } ) {
    $ref->{$ver}->{line_map}->{$map} = $self->{current_document}->{line_map}->{$map};
  }

  return 1;
}

sub notate {
  my $self = shift @_;
  my $ver  = $self->recent_version;

  my $note = {};
  
  return undef unless $self->{rcs}->{$ver};

  $self->_grab_note($note);

  
  my @chain = $self->_revision_path($self->{current_document}->{version});

  for my $version ( @chain ) {
    $self->_debug("--> loading delta $version");
    $self->_apply_delta($version);
    $self->_sort;
    $self->_grab_note($note);
  }

  for my $version ( reverse @chain, $self->recent_version ) {
    if ( $version eq $chain[$#chain] ) {
      $self->_debug("Mapping $version pro facia ...");
      map { $note->{$version}->{body}->{$_}->{origin} = $version; } keys %{$note->{$version}->{body}};
    } else {
      $self->_debug("Mapping $version via line count ...");
      my $error;
      for my $line ( keys %{$note->{$version}->{body}} ) {
        
        my $author_ver = $version;
        my $test_line  = $line;
        my $test_ver   = $self->previous_version($version);
        
        $error++ unless defined $test_ver;
        
        while ( $note->{$test_ver}->{line_map}->{$test_line} ) {
          $author_ver = $test_ver;
          $test_line  = $note->{$test_ver}->{line_map}->{$test_line};
          $test_ver   = $self->previous_version($author_ver) || last; #??? break if we bottom on version?
        } 
      
        $note->{$version}->{body}->{$line}->{origin} = $author_ver;
      }
      warn "WARN: $error lines didn't map well for $self->{file} $version"
            if $error > 0;
    }
  }

  return $note;
}

=item previous_version()

=cut

sub previous_version {
  my $self = shift @_;
  my $ver  = shift @_ || $self->recent_version;
  return $self->{rcs}->{revision_path}->{$ver};
}

=item recent_version()

This method returns the most current revision of the file.

=cut

sub recent_version {
  my $self = shift @_;
  return $self->{rcs}->{header}->{head};
}

=item version()

This method returns the most current revision of the file.

=cut

sub version {
  my $self = shift @_;
  return $self->{current_document}->{version};
}

####

sub _apply_delta {
  my $self = shift @_;
  my $ver  = shift @_;
  my $doc  = shift @_ || $self->{current_document};

  my $raw_delta = $self->{rcs}->{$ver}->{text};
  $doc->{version} = $ver;

  my @deltas = split /\n/, $raw_delta;

  while ( @deltas ) {
    my $delta = shift @deltas;
    if ( $delta =~ /^a(\d+) (\d+)$/ ) { 
      my $line  = $1;
      my $count = $2;
      my $test  = 0;
      
      for ( my $c = 0; $c < $count; $c++ ) {
        my $new_line = $self->_unquote( shift @deltas ) . "\n";
        push @{ $doc->{body}->{$line}->{new_lines} }, $new_line;
        $test++;
      }
      $self->_debug("added $test lines at $line ($count directed)"); 
 
    } elsif ( $delta =~ /^d(\d+) (\d+)$/ ) { 

      my $first_line = $1;
      my $last_line  = $1 + $2 - 1;
      for my $line ( $first_line .. $last_line ) {
        $doc->{body}->{$line}->{line} = undef;
      }
      $self->_debug("deleting lines $first_line through $last_line ($2 directed)"); 
    } else { 
      warn "ORPHAN DELTA COMMAND! $delta\n"; 
    }
  }
  return 1;
}

sub _create_full_revision_path {
  my $self = shift @_;
  $self->_debug('Building full revision path for reference...');

  $self->{rcs}->{revision_path} = {};
  $self->{rcs}->{reverse_revision_path} = {};
  
  my $version = $self->recent_version;
  while ( my $next = $self->{rcs}->{$version}->{next} ) {
    $self->{rcs}->{revision_path}->{$version} = $next;
    $self->_debug("  $version -> $next");
    $version = $next;
  }

  #map { $self->{rcs}->{reverse_revision_path}->{$self->{rcs}->{revision_path}->{$_}} = $_ } keys %{$self->{rcs}->{revision_path}};

  $self->_debug('Built a revision path of ' . scalar( keys %{$self->{rcs}->{revision_path}} ) . ' jumps.');
}

sub _debug {
  my $self = shift @_;
  my $mesg = shift @_;
  print "DEBUG: $mesg\n" if $self->{debug};
}

sub _dump {
  my $self = shift @_;
  my $doc  = shift @_ || $self->{current_document};
  return join '', map { $doc->{body}->{$_}->{line} } sort { $a <=> $b } keys %{ $doc->{body} };
}

sub _parse_in_rcs {
  my $self = shift @_;
  my $file = shift @_;
  my $rcs  = shift @_;
 
  open RCSFILE, $file;

  ### Parse in the RCS file header

  my $rcs_header;

  while ( my $line = <RCSFILE> ) {
    last if $line =~ /^$/;
    $rcs_header .= $line;
  }

  for my $chunk ( split /;/, $rcs_header ) {
    $chunk =~ s/\n//g;
    $chunk =~ /^\s*(\w+)\s*(.*)$/;
    $rcs->{header}->{$1} = $2 if $1;
  }

  $rcs_header = undef;

  ### Parse in the individual version headers

  my $version = 'error';
  while ( my $line = <RCSFILE> ) {
    last if $line =~ /^desc$/;

    if ( $line =~ /^([\d|\.]+)/ ) {
      $version = $1;
    } else {
      next if $line =~ /^$/;
      $rcs->{$version}->{header} .= $line;
    }
  }

  my $garbage_double_quote = <RCSFILE>;

  ### Parse in the individual deltas

  $version  = 'error';
  my $directive = 0;
  my $quote = 0;

  while ( my $line = <RCSFILE> ) {
    $version = $1 if $line =~ /^([\d|\.]+)/ && $quote == 0;
    if ( $line =~ /^\@(?!\@)/ ) { $quote = $quote == 0 ? 1 : 0; }
    next if $line =~ /^$/ && $quote == 0;

    if ( $quote == 0 ) {
      $line =~ /^(.+)$/;
      $directive = $1;
    } else {
      $rcs->{$version}->{$directive} .= $line;
    }

    #$rcs{$version}{raw_text} .= $line;
  }
  
  close RCSFILE;

  ### clean the leftover quoting

  for my $version ( keys %$rcs ) {
    for my $directive ( keys %{$rcs->{$version}} ) {
      $rcs->{$version}->{$directive} = $1 if $rcs->{$version}->{$directive} =~ /^\@(.*)$/s;
      $rcs->{$version}->{$directive} = $1 if $rcs->{$version}->{$directive} =~ /^(.*)\@$/s;
    }
  }

  ### disassemble header

  for my $version ( keys %$rcs ) {
    my @commands = split ';', $rcs->{$version}->{header};
    for my $command ( @commands ) {
      chomp $command;
      $rcs->{$version}->{$1} = $2 if $command =~ /\s*(.+)\s+(.+)$/;
    }
  }

  return 1;
}

sub _revision_path {
  my $self = shift @_;
  my $ver  = shift @_ || $self->recent_version;
  my $stop = shift @_ || undef;
  
  return undef unless $self->{rcs}->{$ver};
  return () if $ver eq $stop;  
  
  $self->_debug('Checking revision path...');
  $self->_create_full_revision_path() unless $self->{rcs}->{revision_path};

  my @chain;
  while ( my $next = $self->{rcs}->{revision_path}->{$ver} ) { 
    push @chain, $next;
    last if $next eq $stop;
    $ver = $next;
  }  

   $self->_debug("CHAIN: " . (join ' -> ', @chain));
  return @chain;
}

sub _sort {
  my $self = shift @_;
  my %copy = %{ $self->{current_document} };

  $self->{current_document} = {};
  $self->{current_document}->{version} = $copy{version};

  my $count = 1;
  for my $line_num ( sort { $a <=> $b } keys %{ $copy{body} } ) {
    # add basic line
    if ( $copy{body}{$line_num}{line} ) {
      $self->{current_document}->{body}->{$count}->{line} = $copy{body}{$line_num}{line};
      $self->{current_document}->{line_map}->{$count} = $line_num;
      $count++;
    }
    # add new lines if existant
    if ( $copy{body}{$line_num}{new_lines} ) {
      for my $line ( @{ $copy{body}{$line_num}{new_lines} } ) {
        $self->{current_document}->{body}->{$count}->{line} = $line;
        $count++;
      }
    }
  }

  my %copy = ();

  $self->_debug( "($self->{current_document}->{version}) " . --$count . ' lines sorted...');

  return 1;
}

sub _unquote {
  my $self = shift @_;
  my $in   = shift @_;
  $in =~ s/\@\@/\@/g;
  return $in;
}

1;
