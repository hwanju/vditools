#!/usr/bin/perl -w

die "Usage: $0 <dir>\n\tautomatically find -barrier postfix\n" unless @ARGV;
$dir = shift(@ARGV);
@files = `ls $dir/*0-time.result`;
$plot_name = $dir;
$plot_name =~ s/\/$//;
$plot_name .= "-barrier-wait";
$xtics = "set xtics (";
$x = 0;
open OFD, ">$plot_name.dat";
print OFD "# mode\tarrival_spinned\tarrival_blocked\tdeparture_spinned\tdeparture_blocked\n";
$max_wait = 0;
foreach $fn (@files) {
	print "$fn\n";
	$solorun = $fn =~ /baseline/;
	$resched_co = $1 if ($fn =~ /\d+:\d+:\d+:\d+:\d+:(\d+)/);
	if ($solorun) {
		$mode = "Solorun";
	}
	else {
		$mode = $resched_co ? "w/ Resched-Co" : "w/o Resched-Co";
	}
	open FD, $fn;
	$departure_spinned = $departure_blocked = $arrival_spinned = $arrival_blocked = $total_wait = $n = 0;
	while(<FD>) {
		if (/barrier_stat: spin_hit_open=(\d+) blocked_open=(\d+) total_open=\d+ spin_hit_close=(\d+) blocked_close=(\d+) total_close=\d+/) {
			$departure_spinned += $1;
			$departure_blocked += $2;
			$arrival_spinned += $3;
			$arrival_blocked += $4;

			$total_wait += $1 + $2 + $3 + $4;
			$total_block_wait{$mode} += $2 + $4;
		}
		$n++ if (/Elapsed/);
		last if (/Guest2:/);

	}
	close FD;
	$departure_spinned /= $n;
	$departure_blocked /= $n;
	$arrival_spinned /= $n;
	$arrival_blocked /= $n;
	$total_wait /= $n;

	$label = $mode;
	$label =~ s/\s+/_/g;
	printf OFD "$label\t$arrival_spinned\t$arrival_blocked\t$departure_spinned\t$departure_blocked\n";
	$xtics .= ", " unless $x == 0;
	$xtics .= "\"$mode\" $x";
	$x++;

	$resched_co_wait = $total_wait if $mode eq "w/ Resched-Co";
	$max_wait = $total_wait if $total_wait > $max_wait;
}
close OFD;
$block_wait_reduction = ($total_block_wait{"w/o Resched-Co"} - $total_block_wait{"w/ Resched-Co"}) * 100 / $total_block_wait{"w/o Resched-Co"};
$desc = sprintf "%d%% reduction\\nin block-wait", $block_wait_reduction;
$resched_co_wait += 130000;
$xtics .= " )";
$ymax = $max_wait + 500000;
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 25
set output '$plot_name.eps'
set size 1,1
set key invert reverse left Left width -1
set ylabel '# of barrier waits (in thousands)' 
set xrange [-0.3:2.3]
set yrange [0:$ymax]
set xtics 0,200000
set xtics nomirror
#set xtic rotate by -45
$xtics
set label \"$desc\" at 0.7, $resched_co_wait
#set ytics 0,20
set ytics nomirror
set ytics ('200' 200000, '400' 400000, '600' 600000, '800' 800000)
set style data histograms
set style histogram rowstacked
set grid y
set boxwidth 0.35
plot '$plot_name.dat' u 2 t 'Spin-wait on arrival barrier' lt 1 fs solid 0.20, '' u 3 t 'Block-wait on arrival barrier'  lt 1 fs pattern 4, '' u 4 t 'Spin-wait on departure barrier'  lt 1 fs solid 0.70, '' u 5 t 'Block-wait on departure barrier'  lt 1 fs pattern 7
";
close OFD;

system("gnuplot $plot_name.plt");
