#!/usr/bin/perl
#
#
# 16.04.200
# *initial release

use strict;

use vars qw($VERSION %IRSSI);

$VERSION = "20020416";
%IRSSI = (
    authors     => "Stefan 'tommie' Tomanek",
    contact     => "stefan\@pico.ruhr.de",
    name        => "lag-o-meter",
    description => "Illustrates your lag in form of a progressbar",
    license     => "GPLv2",
    url         => "",
    changed     => "$VERSION",
);

sub draw_lag {
    my ($lag) = @_;
    my $maxlag = Irssi::settings_get_int('lagometer_maxlag');
    $maxlag = 1000*Irssi::settings_get_int('server_reconnect_time') if (Irssi::settings_get_bool('lagometer_sync_to_erver_reconnect_time'));
    my $width = Irssi::settings_get_int('lagometer_width');
    
    return "="x($width-1).'>' if $lag > $maxlag;
    my $unit = $width/$maxlag;
    
    my $bars = $lag * $unit;
    my $full = "#" x int($bars);
    my $half = '';

    if ( ($bars - int($bars)) > ($unit/2) ) {
	$half = "|";
    }
    my $bar = $full.$half.(" "x($width-(length $full.$half)));
    return $bar;
}

sub lagometer_show {
    my ($item, $get_size_only) = @_;
    my $win = Irssi::active_win()->{active};
    if (Irssi::active_server()) {
	my $lag = Irssi::active_server()->{lag};
	my $lag_bar = draw_lag($lag);
	my $format = "{sb ".$lag_bar."}";
	$item->{min_size} = $item->{max_size} = length($lag_bar);
	$item->default_handler($get_size_only, $format, 0, 1);
    } else {
	$item->{min_size} = $item->{max_size} = 0;
    }
}
Irssi::settings_add_int('misc', 'lagometer_maxlag', 1000);
Irssi::settings_add_int('misc', 'lagometer_width', 20);
Irssi::settings_add_bool('misc', 'lagometer_sync_to_server_reconnect_time', 1);

Irssi::statusbar_item_register('lagometer', 0, 'lagometer_show');
