use strict;

use vars qw($VERSION %IRSSI);
$VERSION = '2003010401';
%IRSSI = (
    authors     => 'Stefan \'tommie\' Tomanek',
    contact     => 'stefan@pico.ruhr.de',
    name        => 'GoogleFight',
    description => 'Fight like a geek',
    license     => 'GPLv2',
    changed     => $VERSION,
    modules     => 'LWP::Simple HTML::Entities',
);

use Irssi;
use LWP::Simple;
use HTML::Entities;

use vars qw($forked);

sub fight ($$) {
    my ($a, $b) = @_;
    my $querya = HTML::Entities::encode($a);
    my $queryb = HTML::Entities::encode($b);
    my $data = get("http://www.googlefight.com/cgi-bin/compare.pl?q1=".$querya."&q2=".$queryb."&B1=Make+a+fight%21&compare=1&langue=us");
    my %result;
    foreach (split /\n/, $data) {
	if (/^ *<font size="2" color="#666666">\(([0-9 ]+)/) {
	    $result{$a} = $1;
	    $result{$a} =~ s/ //g;
	} elsif (/^ +<font color="#666666">\(([0-9 ]+) results\)/) {
	    $result{$b} = $1;
	    $result{$b} =~ s/ //g;
	}
    }
    return \%result;
}

sub bg_fight ($$$) {
    my ($a, $b, $arena) = @_;
    my ($rh, $wh);
    pipe($rh, $wh);
    return if $forked > 2;
    $forked++;
    my $pid = fork();
    if ($pid > 0) {
        close $wh;
        Irssi::pidwait_add($pid);
        my $pipetag;
        my @args = ($rh, \$pipetag);                                            
        $pipetag = Irssi::input_add(fileno($rh), INPUT_READ, \&pipe_input, \@args);     
    } else {
	eval {
    	    my %result;
    	    $result{$arena} = fight($a, $b);
    	    my $dumper = Data::Dumper->new([\%result]);
    	    $dumper->Purity(1)->Deepcopy(1);
    	    print($wh $dumper->Dump);
    	    close($wh);
	};
	POSIX::_exit(1);
    }
}

sub pipe_input {
    my ($rh, $pipetag) = @{$_[0]};
    $forked--;
    my $text;
    $text .= $_ foreach (<$rh>);
    close($rh);
    return unless($text);
    no strict;
    my $result = eval "$text";
    return unless ref $result;
    foreach my $arena (keys %$result) {
	my $data;
	foreach (keys %{$result->{$arena}}) {
	    $data .= '"'.$_."' has ".$result->{$arena}{$_}." results.\n";
	}
	$data =~ s/\n\Z//g;
	print $data;
    }
}

sub cmd_googlefight ($$$) {
    my ($args, $server, $witem) = @_;
    my $arena = 'null';
    my $sep = Irssi::settings_get_str('googlefight_opponent_separator');
    my ($a, $b) = split(/$sep/, $args);
    bg_fight($a, $b, $arena);
}

Irssi::command_bind('googlefight', \&cmd_googlefight); 

Irssi::settings_add_str($IRSSI{name}, 'googlefight_opponent_separator', ' ');
