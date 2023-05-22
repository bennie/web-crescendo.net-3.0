#!/usr/bin/perl

# irclogger.pl is a simple IRC bot that is (c) 2008-2010, Phil Pollard
#
# Portions of this code are also (c) 2008-2010 FusionOne, Inc and are released
# with permission.
#
# This code is licensed under GNU Public License v3.
# http://www.gnu.org/licenses/gpl.html

# This bot is a very simple IRC bot that is designed to log onto multiple 
# channels on an IRC server and log all public actions onto those channels to
# individual log files for each channel.
#
# The bot rotates logfiles automatically on a daily basis with the date and 
# channel name being embedded in the file name. On the assumption that the
# files are available to be viewed via the web, the bot announces to all 
# arrivals the current URL for the log being used for that channel.
#
# The bot also handles a few rudimentary commands:
#
# By a user saying or messaging "bot restart" or "bot reload" the script will 
# attempt to exit and restart itself. This is handy if you are actively editing
# the bots code with a remote editor and wish to relaunch the bot from within
# IRC.
#
# By a user saying or messaging "clock?" or "time?" the bot responds with the
# current time (including corrections for daylight savings) for the timezones 
# listed in the config section. This is handy for international coordination
# of efforts in a channel.
#
# You launch the bot by executing the perl script on the command line. It will
# automatically daemonize and try to run in the background. (IE: you'll have to
# check your process list to see if it is running.) On most basic connection 
# errors it will dump information into the general log and then exit. Also the
# command line option of '--debug' will dump the log messages to STDERR on the
# executing shell.
#
# This bot does not currently handle managing channel operator status or any 
# authentication of commands. Though with the event hooks from Net::IRC and
# some additions to the "Interactions" section of on_msg(), it should be an 
# easy task to set up. Enjoy!

### Config

my %conf = (
  irc_nick => 'LogBot',     # Nickname the bot will use
  irc_host => '127.0.0.1',  # Server the bot will try to join
  irc_port => '6667',       # Server port the bot will try to join
  irc_name => 'GLadDOS',    # "name" the bot will use. Shows up in /who queries
  irc_pass => '',           # Server password the bot can use. Leave blank for non.
  irc_ssl  => 0,            # Set to 1 to use SSL connections to the server. Not heavily tested.
);

my @channels = qw/#chanfoo #chanbar #chanbaz/; # channels the bot will join

my $app = '/home/myaccount/irclogger.pl'; # Command to relaunch the bot. Should be the path to this file.

my $logdir = '/var/www/html/irc/';        # Local directory on the server the bot should log to
my $logurl = 'http://mywebsite.com/irc/'; # Web URL that matches the above directory to view logs

my @timezones = qw|America/Los_Angeles UTC Europe/Tallinn|; # Timezones to respond with for "clock?" queries. Perldoc the DateTime module for more details.

### You shouldn't need to edit beyond this, unless you want to. :)

my $greeting = 'Welcome %s. Logs of this channel will be available at %s';
my $clock_format = "%Z: %a %b %d - %T"; # Formatted by DateTime strftime()

use DateTime;
use Data::Dumper;
use IO::File;
use Net::IRC;
use Proc::Daemon;
use strict;

my $connected = 0;
my $debug = 0;

my %handles;
my %urls;

### Command line

$debug = 1 if $ARGV[0] and $ARGV[0] eq '--debug';

### Main

Proc::Daemon::Init;

my $irc = new Net::IRC;

my $conn = $irc->newconn( Nick => $conf{irc_nick},
                            Server  => $conf{irc_host},
                            Port    => $conf{irc_port},
                            Ircname => $conf{irc_name},
                            Password=> $conf{irc_pass},
                            SSL     => $conf{irc_ssl}
);

$conn->add_global_handler('376',   \&on_connect);
$conn->add_global_handler('422',   \&on_connect);
$conn->add_global_handler('error', \&on_error);

$conn->add_handler('msg',     \&on_msg);
$conn->add_handler('public',  \&on_msg);
$conn->add_handler('join',    \&on_msg);
$conn->add_handler('part',    \&on_msg);
$conn->add_handler('nick',    \&on_msg);
$conn->add_handler('quit',    \&on_msg);
$conn->add_handler('caction', \&on_msg);

logger("Connecting to $conf{'irc_host'}:$conf{'irc_port'}");

$irc->start;

### handlers

sub on_msg {
  my $self  = shift;
  my $event = shift;

  # never talk to our self
  return if ($event->{nick} eq $conf{irc_nick});

  # Prep all events for logging: A few user actions are reformatted for clarity.

  my $msg = $event->{args}[0];

  if ($event->{type} eq 'nick'){
    $msg = sprintf("%s is now known as %s", $event->{nick}, $event->{args}[0]);
  } elsif($event->{type} eq 'part'){
    $msg = sprintf("%s (%s) has left the channel (%s)", $event->{nick}, $event->{userhost}, $event->{args}[0]);
  } elsif($event->{type} eq 'quit'){
    $msg = sprintf("%s (%s) has quit (%s)", $event->{nick}, $event->{userhost}, $event->{args}[0]);
  } elsif($event->{type} eq 'join'){
    $msg = sprintf("%s (%s) entered the channel (%s)", $event->{nick}, $event->{userhost}, $event->{args}[0]);
  }

  my $line = join(' ','<'.join(',',@{$event->{to}}).'>','<'.$event->{nick}.'>','['.$event->{type}.']:',$msg);

  # Log the event

  logger($line);
  print Dumper($event) if $debug > 1;

  for my $channel (@{$event->{to}}) {
    logger($channel,$line);
  }
  
  ### Interactions:
  
  # Welcome users on join
  
  if ($event->{type} eq 'join') {
    $self->privmsg($event->{to}->[0],sprintf($greeting,$event->{nick},$urls{$event->{to}->[0]}));
  }
  
  # Handle commands that are spoken to the bot
  
  return undef unless $event->{type} eq 'public';
  
  if ( $msg =~ /^\s*bot\s+(restart|reload)\s*$/ ) {
    $self->privmsg($event->{to}->[0],"Trying to restart: $app");
    exec($app); # Reload the bot!
  } elsif ( $msg =~ /^\s*(bot\s+)?(clock|time)\??\s*$/ ) {
    for my $time ( &clock() ) {
      $self->privmsg($event->{to}->[0],$time);
    }
  }

}

sub on_connect {
    my $self = shift;
    return if($connected);

    for my $chan (@channels) {
      logger("Joining channel $chan");
      logger($chan,"Joining channel $chan");
      $self->join($chan);
    }
    
    $connected = 1;
}

sub on_error {
    my $self  = shift;
    my $event = shift;

    logger($event->{'args'});
}

### Subs

sub clock {
  my @out;
  my $dt = DateTime->now;
  for my $tz ( @timezones ) {
    my $temp = $dt;
    $temp->set_time_zone($tz);
    push @out, $temp->strftime($clock_format);
  }
  return @out;
}

sub datestamp {
  my @time = localtime;
  return sprintf "%04d-%02d-%02d", $time[5] + 1900, $time[4] +1, $time[3];
}

sub timestamp {
  my @time = localtime;
  return sprintf "%04d-%02d-%02d %02d:%02d:%02d", $time[5] + 1900, $time[4] +1, $time[3], $time[2], $time[1], $time[0];
}

sub logger {
  my $channel = my $rawchannel = 'combined';  

  if ( scalar(@_) > 1 ) {
    $rawchannel = shift @_;
    $channel = $rawchannel;
    $channel =~ s/#//gi;
  }
 
  my $testfilename = $channel eq 'combined'
                   ? $logdir . &datestamp . '.txt'
                   : $logdir . &datestamp . '-'. $channel .'.txt';

  my $testurl = $logurl . &datestamp . '-'. $channel .'.txt';

  my $filename   = $handles{$channel}{filename};
  my $filehandle = $handles{$channel}{handle};

  unless ( $filename eq $testfilename ) {
    if ( $filename ) {
      print $filehandle "Closing $handles{$channel}{filename}\n";
      $filehandle->close;
    }
    $filename = $testfilename;
    $filehandle = new IO::File ">> $filename" or die "Can't open $filename.";
    select((select($filehandle), $| = 1)[0]); # autoflush
    print $filehandle "Opening $filename\n";

    $handles{$channel}{filename} = $filename;
    $handles{$channel}{handle}   = $filehandle;
    $urls{$rawchannel} = $testurl;
  }
  
  for my $line (@_) {
    chomp $line;
    print &timestamp(), " $line\n" if $debug > 0;
    print $filehandle &timestamp() . " $line\n";
  }
}