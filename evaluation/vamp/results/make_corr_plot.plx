#!/usr/bin/perl -w

$def_schedstat = "sum_exec_runtime+wait_sum+remote_wake_sum";
die "Usage: $0 <file name w/o ext> [schedstat(=$def_schedstat)]\n" unless @ARGV >= 1;
$name = shift(@ARGV);
$schedstat = @ARGV ? shift(@ARGV) : $def_schedstat;
$lat_mult = $name =~ /launch/ ? 2 : 1;
open OFD, ">$name-corr.dat";

@latency_data = `./get_latency.plx $name.latency $lat_mult | awk '{print \$2}'`;
@schedstat_data = `./get_sched.plx $schedstat $name.result | awk '{print \$2}'`;

pop(@latency_data);

$n = 0;
foreach $latency (@latency_data) {
	$stat = $schedstat_data[$n];
	chomp($stat);
	chomp($latency);
	printf OFD "%d\t$stat\t$latency\n", $n + 1;
	$n++;

	# statistics
	$sum_X += $stat;
	$sum_Y += $latency;
	$sqsum_X += ($stat*$stat);
	$sqsum_Y += ($latency*$latency);
}
close(OFD);

$avg_X = $sum_X / $n;
$avg_Y = $sum_Y / $n;
$sd_X = sqrt(($sqsum_X / $n) - ($avg_X*$avg_X));
$sd_Y = sqrt(($sqsum_Y / $n) - ($avg_Y*$avg_Y));

$cov = 0;
$i = 0;
foreach $Y (@latency_data) {
	$X = int($schedstat_data[$i++]);
	$cov += ($X - $avg_X) * ($Y - $avg_Y);
	printf "X=$X, Y=$Y, u_X=%.2lf, u_Y=%.2lf, (X-u_x=%.2lf)(Y-u_y=%.2lf)=%.2lf, cov_sum=%.2lf\n", 
		$avg_X, $avg_Y, $X - $avg_X, $Y - $avg_Y, ($X - $avg_X) * ($Y - $avg_Y), $cov;
}
$cov /= $n;
$corr = $cov / ($sd_X * $sd_Y);

printf "cov=$cov\tsd_X($sd_X)*sd_Y($sd_Y)=%.2lf\n", $sd_X * $sd_Y;
printf "%.3lf\n", $corr;

$schedstat =~ s/_/\\_/g;
open OFD, ">$name-corr.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 20
set output '$name-corr.eps'
set key reverse Left bottom 
set xlab 'Scheduler statistics ($schedstat, msec)'
set ylab 'Latency (msec)'
plot '$name-corr.dat' u 2:3 t ''
";
close(OFD);
system("gnuplot $name-corr.plt");
