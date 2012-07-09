#!/usr/bin/perl -w

die "Usage: $0 <mode: baseline|purebal_mig|fairbal_pct100> <solorun dir> <corun dir>\n" unless @ARGV == 3;
$mode = shift(@ARGV);
$solorun_dir = shift(@ARGV);
$corun_dir   = shift(@ARGV);

$plot_name = $corun_dir;
$plot_name =~ s/-\w+\/?$//;
$plot_name .= "-$mode-user_kernel_time";
open OFD, ">$plot_name.dat";

@res_files = `ls $solorun_dir/*\@baseline.result`;
printf OFD "#workload\tkernel\tuser\n";
foreach $fn (@res_files) {
retry:
	open FD, $fn;
	if ($fn =~ /\/1(\w+)(@|\+)/) {
		$workload = $1;
		$solorun = $2 eq "@";
	}
	$first = 1;
	while(<FD>) {
		if (/^cpu\s+/) {
			@stat = split(/\s+/);
			if ($first) {
				@prev_stat = @stat;
				$first = 0;
			}
			else {
				printf OFD "$workload";
				$total = 0;
				for $i (1 .. 10) {
					$stat[$i] -= $prev_stat[$i];
					$total += $stat[$i];

				}
				#for $i (1 .. 10) {
				#	printf "$stat[$i](%d)\t", $stat[$i] * 100 / $total;
				#}
				$user = $stat[1] + $stat[2];
				$sys  = $stat[3] + $stat[6] + $stat[7];
				#$idle = $stat[4];
				#$steal = $stat[8];

				$all = $user + $sys;
				printf OFD "\t%.3lf\t%.3lf\n", $sys * 100 / $all, $user * 100 / $all;
				#printf OFD "\t%.3lf\t%.3lf\t%.3lf\t%.3lf\n", $steal / 800, $user / 800, $sys / 800, $idle / 800;
				last;
			}
		}
	}
	close (FD);

	if ($solorun) {
		$fn = `ls $corun_dir/1$workload*\@$mode.result`;
		goto retry;
	}
	else {
		print OFD "dummy\t0\t0\n";
	}
}
close OFD;
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 25
set output '$plot_name.eps'
#set key invert reverse Left width -1 outside
set key invert reverse Left width -1 
set size 1.5,1
#set xlabel 'Workloads'
set ylabel 'CPU Usage (%)' 
set yrange [0:125]
set xtics 0,10
set xtics nomirror
set xtic rotate by -45
set xtics ( 'blackscholes' 0, 'bodytrack' 3, 'canneal' 6, 'dedup' 9, 'facesim' 12, 'ferret' 15, 'fluidanimate' 18, 'freqmine' 21, 'raytrace' 24, 'streamcluster' 27, 'swaptions' 30, 'vips' 33, 'x264' 36 )
#set ytics 0,20
set label 'Solorun' at 0, 112
set style arrow 1 head nofilled ls 1 
set arrow from 2.5, 108 to 3, 100 as 1
set label 'Corun' at 4.5, 112
set arrow from 4.5, 108 to 4, 100 as 1
set grid y
set style data histograms
set style histogram rowstacked
set style fill solid border 0.2
set boxwidth 1
plot '$plot_name.dat' u 2 t 'Kernel' fs solid 0.65 lt 1, '' u 3 t 'User' fs pattern 4 lt 1
";
close OFD;

system("gnuplot $plot_name.plt");
