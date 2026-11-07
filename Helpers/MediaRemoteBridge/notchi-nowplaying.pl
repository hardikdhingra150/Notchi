#!/usr/bin/perl
# Loads MediaRemoteBridge.dylib into Apple's own perl so macOS lets it read
# the system Now Playing info. See MediaRemoteBridge.m.
#   perl notchi-nowplaying.pl <dylib> stream     # JSON lines on stdout
#   NOTCHI_MR_COMMAND=toggle perl notchi-nowplaying.pl <dylib> command
use strict;
use warnings;
use DynaLoader;

my ($lib, $mode) = @ARGV;
die "usage: notchi-nowplaying.pl <dylib> stream|command\n" unless $lib && $mode;
my $handle = DynaLoader::dl_load_file($lib, 0) or die "can't load $lib: " . DynaLoader::dl_error() . "\n";
my $name = $mode eq 'command' ? 'notchi_command' : 'notchi_stream';
my $sym = DynaLoader::dl_find_symbol($handle, $name) or die "missing $name\n";
DynaLoader::dl_install_xsub('main::run', $sym);
run();
