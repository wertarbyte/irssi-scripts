# by Stefan 'tommie' Tomanek
use strict;

use vars qw($VERSION %IRSSI);
$VERSION = "20021107";
%IRSSI = (
    authors     => "Stefan 'tommie' Tomanek",
    contact     => "stefan\@pico.ruhr.de",
    name        => "Geonosis",
    description => "searches for clones and helps any fair op fighting them",
    license     => "GPLv2",
    changed     => "$VERSION",
);

use Irssi;

sub _min {
	my ($first,$second,$third)=@_;
	my $result=$first;
	$result=$second if ($second < $result);
	$result=$third if ($third < $result);
	return $result
}


sub dist {
	my ($s,@t)=@_;
	my $n=length($s);
	my @result;
	foreach my $t (@t) {
		my @d;
		my $cost=0;
		my $m=length($t);
		if(!$n) {push @result,$m;last}
		if(!$m) {push @result,$n;last}
		$d[0][0]=0;
		foreach my $i (1 .. $n) {$d[$i][0]=$i}
		foreach my $j (1 .. $m) {$d[0][$j]=$j}
		foreach my $i (1 .. $n) {
			my $s_i=substr($s,$i-1,1);
			foreach my $j (1 .. $m) {
				my $t_i=substr($t,$j-1,1);
				if ($s_i eq $t_i) {
					$cost=0
				} else {
					$cost=1
				}
				$d[$i][$j]=&_min($d[$i-1][$j]+1,
						 $d[$i][$j-1]+1,
						 $d[$i-1][$j-1]+$cost)
			}
		}
		push @result,$d[$n][$m];
	}
	if (wantarray) {return @result} else {return $result[0]}
}

sub sig_message_join ($$$$) {
    my ($server, $channel, $nick, $address) = @_;
    my $regexp = Irssi::settings_get_str('geonosis_watch_channels');
    return unless ($channel =~ /^$regexp$/);
    print $nick;
    print $channel;
    my $witem = $server->window_item_find($channel);
    return unless $witem;
    my $min_n = length($nick)/2;
    my $min_h = length($address) / 3;
    my $time = time();
    foreach ($witem->nicks()) {
	next if $_->{nick} eq $nick;
	if (dist($nick, $_->{nick}) < $min_n || dist($address, $_->{host}) < $min_h) {
	    $witem->print("%R>>%n Possible clone: ".$nick." & ".$_->{nick}." (".$address."/".$_->{host}.")", MSGLEVEL_CLIENTCRAP);
	    target($server, $channel, $nick) if Irssi::settings_get_bool('geonosis_target_clones');
	}
    }
    print time()-$time;
}

sub target ($$$) {
    my ($server, $channel, $nick) = @_;
    no strict "refs";
    if (defined %{ "Irssi::Script::target::" }) {
	&{ "Irssi::Script::target::lock_target" }($server, $channel, $nick);
    }
}

Irssi::settings_add_str($IRSSI{name}, 'geonosis_watch_channels', '.*');
Irssi::settings_add_bool($IRSSI{name}, 'geonosis_target_clones', 1);

Irssi::signal_add('message join', \&sig_message_join);

