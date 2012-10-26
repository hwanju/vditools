#!/usr/bin/perl -w

die "Usage: $0 <latency file> [multiple(default=1)] [start number(default=1)] [step(default=1)]\n" unless @ARGV;
$fn = shift(@ARGV);
$mult = @ARGV ? shift(@ARGV) : 1;
$start_num = @ARGV ? shift(@ARGV) : 1;
$step = @ARGV ? shift(@ARGV) : $mult;

$nr_samples = `wc -l $fn | awk '{print \$1}'`;
$nr_samples -= 20 * $mult;
open FD, $fn or die "file open error: $fn\n";

if ($start_num > 1) {
	$i = 1;
	while(<FD>) {
		last if ++$i >= $start_num;
	}
}

$i = 0;
while(<FD>) {
	next unless (/^\d+$/);
	if ($i++ % $step == 0) {
		#next if $i == 1;
		$sum += $_;
		$sqsum += ($_*$_);
		push(@samples, int($_));
		$n++;

		print "$n\t$_";
	}
	last if $i >= $nr_samples;
}     
$step = 100 / $n;
foreach $v (sort {$a <=> $b} @samples) {
	$pct += $step;
	$min = $v if !defined($min);
	$val_5p = $v if !defined($val_5p) && $pct >= 5;
	$val_50p = $v if !defined($val_50p) && $pct >= 50;
	$val_95p = $v if !defined($val_95p) && $pct >= 90;
	$val_99p = $v if !defined($val_99p) && $pct >= 99;
	$max = $v;
}
$avg = $sum / $n;
$sd  = sqrt(($sqsum / $n) - ($avg*$avg));
printf "avg=%.2lf sd=%.2lf 5p=%.2lf 50p=%.2lf 95p=%.2lf 99p=%.2lf min=%.2lf max=%.2lf count=%d\n", 
	$avg, $sd, $val_5p, $val_50p, $val_95p, $val_99p, $min, $max, $n;
