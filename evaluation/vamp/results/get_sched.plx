#!/usr/bin/perl -w

%stat = (
	"utime" => 13,
	"stime" => 14,
);

die "Usage: $0 <sched name> <result file>\n" unless @ARGV == 2;
$sched_name = shift(@ARGV);
$fn = shift(@ARGV);
$out_fn = $fn;
$out_fn =~ s/\.result/-$sched_name\.schedcdf/g;
open FD,  "$fn" or die "file open error: $fn\n";
open OFD, ">$out_fn" or die "file open error: $out_fn\n";

if ($sched_name =~ /\+/) {
	@scheds = split(/\+/, $sched_name);
}
else {
	push(@scheds, $sched_name);
}

$pid = $nr_vals = 0;
while(<FD>) {
	foreach $sched (@scheds) {
		if ($stat{$sched}) {	# /proc/<pid>/stat
			@stats = split(/\s+/);
			if ($pid && $stats[0] == $pid && $stats[$stat{$sched}]) {
				$val += $stats[$stat{$sched}];
			}
			$stat_name = "stat";
		}
		else {
			$stat_name = "sched";
			if (/\.$sched\s+:\s+([\d\.]+)/) {
				$val += $1;
				last;
			}
		}
	}
	if (/^# (\d+) $stat_name (\d+)/) {
		$pid = $2;
		if ($1 > 1) {
			push(@vals, $val);
			$sum += $val;
			$sqsum += ($val * $val);
			$val = 0;
			$nr_vals++;
		}
		next;
	}
	$pid = 0;
}
close(FD);

$cdf = 0;
$step = 100 / $nr_vals;
foreach $v (sort {$a <=> $b} @vals) {
	$cdf += $step;
	$val_99p = $v if !defined($val_99p) && $cdf >= 99;
	$max = $v;
	printf OFD "%.3lf\t%.3lf\n", $v, $cdf;
}

$avg = $sum / $nr_vals;
$sd = sqrt(($sqsum / $nr_vals) - ($avg * $avg));
printf OFD "# nr_samples=$nr_vals avg=%.2lf sd=%.2lf 99p=%.2lf max=%.2lf\n", $avg, $sd, $val_99p, $max;

