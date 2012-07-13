#!/usr/bin/perl -w

# Usage: $0 [-c]
# -c means convert debug to lhp files first

die "Usage: $0 [-c] <dir (e.g., sensitivity-preemption-delay>\n" unless @ARGV;
$conv = $ARGV[0] eq "-c" ? shift(@ARGV) : "no";
$dir = shift(@ARGV);
$dir =~ s/\/$//g;
if ($conv eq "-c") {
	@debug_files = `ls $dir/*.debug`;
	foreach $fn (@debug_files) {
		print "convert $fn to lhp file\n";
		system("./get_lockholder.plx futex $fn");
	}
}
@lhp_files = `ls $dir/*.lhp`;
foreach $fn (@lhp_files) {
	if ($fn =~ /\d+(\w+)\+.+-1:\d+:\d+:\d+:(\d+)/ || $fn =~ /\d+(\w+)\+.+-1:\d+:\d+:\d+:(\d+):\d-early/ ) {
		$workload = $1;
		$delay = $2 / 1000;
		$lhp = `tail -1 $fn`;
		chomp($lhp);
		$workload_map{$workload} = 1;

		if ($fn !~ /early/) {
			$lhp_sum{$delay}{$workload} += $lhp;
			$lhp_sqsum{$delay}{$workload} += ($lhp * $lhp);
			$nr_lhp{$delay}{$workload}++;
		}
		else {
			$lhp_sum_early{$delay}{$workload} += $lhp;
			$lhp_sqsum_early{$delay}{$workload} += ($lhp * $lhp);
			$nr_lhp_early{$delay}{$workload}++;
		}
	}
}
$plot_name = $dir;
open OFD, ">$plot_name.dat";
print OFD "#delay";
foreach $workload (sort keys %workload_map) {
	print OFD "\t$workload";
}
print OFD "\n";
$i = 1;
$xtics = "set xtics (";
foreach $delay (sort {$a <=> $b} keys %lhp_sum) {
	$xtics .= ", " unless $i == 1;
	$xtics .= "'$delay' $i";
	printf OFD "$delay\t%d", $i++;
	foreach $workload (sort keys %workload_map) {
		$avg = $lhp_sum{$delay}{$workload} / $nr_lhp{$delay}{$workload};
		$sd = sqrt(($lhp_sqsum{$delay}{$workload} / $nr_lhp{$delay}{$workload}) - ($avg * $avg));
		printf OFD "\t%.2lf\t%.2lf", $avg, $sd;
	}
	print OFD "\n";
}
foreach $delay (sort {$a <=> $b} keys %lhp_sum_early) {
	$xtics .= ", " unless $i == 1;
	$xtics .= "\"$delay\\n(early)\" $i";
	printf OFD "$delay-early\t%d", $i++;
	foreach $workload (sort keys %workload_map) {
		$avg = $lhp_sum_early{$delay}{$workload} / $nr_lhp_early{$delay}{$workload};
		$sd = sqrt(($lhp_sqsum_early{$delay}{$workload} / $nr_lhp_early{$delay}{$workload}) - ($avg * $avg));
		printf OFD "\t%.2lf\t%.2lf", $avg, $sd;
	}
	print OFD "\n";
}
close OFD;
$xtics .= ")";

open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 25
set output '$plot_name.eps'
set key invert reverse Left width -1
set xlabel 'Preemption delay (usec)'
set ylabel '# of futex-queue LHP' 
set xrange [0:$i]
set yrange [0:]
#set xtics 0,10
set xtics nomirror
#set xtic rotate by -45
#set xtics ( '0' 1, '100' 2, '300' 3, '500' 4, '700' 5, '1000' 6, '1000-early' 7 )
$xtics
#set ytics 0,20
set grid y
plot '$plot_name.dat' u 2:3:4 t 'bodytrack' w yerrorlines lw 2 lt 1 pt 1, '' u 2:5:6 t 'facesim' w yerrorlines lw 2 lt 2 pt 4, '' u 2:7:8 t 'streamcluster' w yerrorlines lw 2 lt 4 pt 7
";
close OFD;

system("gnuplot $plot_name.plt");
