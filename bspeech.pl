use strict;

use vars qw($VERSION %IRSSI);
$VERSION = "2003072401";
%IRSSI = (
    authors     => "Stefan 'tommie' Tomanek",
    contact     => "stefan\@pico.ruhr.de",
    name        => "Bspeech",
    description => "convert your messages into b-Speech",
    license     => "GPLv2",
    changed     => "$VERSION",
    commands	=> "bspeech"
);

use Irssi 20020324;

sub text2b ($) {
    my ($text) = @_;
    $text =~ s/([aeiouAEIOUäöüÄÖÜ])/$1b$1/g;
    return $text;
}

sub b2text ($) {
    my ($btext) = @_;
    $btext =~ s/([aeiouAEIOUäöüÄÖÜ])b\1/$1/g;
    return $btext;
}

sub bspeech_decode ($$$) {
    my ($server, $target, $text) = @_;
    return unless ($text =~ /([aeiouAEIOUäöüÄÖÜ])b\1/g);
    my $witem = $server->window_item_find($target);

    return unless ($witem);
    $witem->print("%B[bspeech]>>%n ".b2text($text), MSGLEVEL_CLIENTCRAP);
}

sub cmd_bspeech ($$$) {
    my ($arg, $server, $witem) = @_;
    if ($witem && ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY')) {
	$witem->command('MSG '.$witem->{name}.' '.text2b($arg));
    } else {
	print CLIENTCRAP "%B>>%n ".text2b($arg);
    }
}

sub cmd_debspeech ($$$) {
    my ($arg, $server, $witem) = @_;
    print CLIENTCRAP "%B>>%n ".b2text($arg);
}

Irssi::command_bind('bspeech', \&cmd_bspeech);
Irssi::command_bind('debspeech', \&cmd_debspeech);

Irssi::signal_add('message public', sub { bspeech_decode($_[0], $_[4], $_[1]); });
Irssi::signal_add('message own_public', sub { bspeech_decode($_[0], $_[2], $_[1]); });

print "%B>>%n ".$IRSSI{name}." ".$VERSION." loaded";

