#!/usr/bin/perl -w

die "Usage: $0 <linux|windows> <trace file> <latency file>\n" unless @ARGV > 1;
$os = shift(@ARGV);
$trace_fn = shift(@ARGV);
$latency_fn = shift(@ARGV);

if ($os eq "linux") {
	# linux-specific ipi info
	$ipi_name{0xfd} = "Reschedule";
	$start_tlb_vec = 0xcf;
	$nr_vcpus = 8;
	foreach $vec ($start_tlb_vec .. ($start_tlb_vec + $nr_vcpus - 1)) {
		$ipi_name{$vec} = "TLB";
	}
	$ipi_name{0xfc} = "Call";
	$ui_start_key = "U 1 156";
}
elsif ($os eq "windows") {
	$ui_start_key = "U 3 0";
}
else {
	die "Error: os type must be linux or windows\n";
}

open FD, "$latency_fn" or die "file open error: $latency_fn\n";
$nr_ui = 0;
while(<FD>) {
	if ($nr_ui % 2 == 0) {
		$latency_us[$nr_ui / 2] = int($_) * 1000 if $nr_ui % 2 == 0;
		$total_latency_ms += int($_);
	}
	$nr_ui++;
}
$nr_ui /= 2;
##print "nr_ui=$nr_ui, total_latency_ms=$total_latency_ms\n";
close FD;

## print "# nr_ipi/sec\n";
open FD, $trace_fn;
$start_time_us = 0;
$ui_index = 0;
while(<FD>) {
	if (/(\d+) $ui_start_key/) {
		$interactive_period = 1;
		$start_time_us = $1;
		##printf "START-$ui_index: $start_time_us\n";
	}
	elsif ($interactive_period && /^(\d+)/) {
		$time_us = $1;
		$elapsed_time_us = $time_us - $start_time_us;
		if ($elapsed_time_us >= $latency_us[$ui_index]) {
			##printf "END-$ui_index: $time_us -> $latency_us[$ui_index] = %d\n", $elapsed_time_us;
			$interactive_period = 0;
			$ui_index++;
		}
		elsif (/I ([0-9a-f]+)/) {
			if (defined($ipi_name{hex($1)})) {
				$ipi{$ipi_name{hex($1)}}++;
			}
			else {
				$ipi{$1}++;
			}
			##printf "\tIPI-$ui_index: $time_us -> %d $1\n", $time_us - $start_time_us;
		}
	}
}
foreach $vec (keys %ipi) {
	$total_latency_sec = $total_latency_ms / 1000;
	printf "$vec\t%d\t($ipi{$vec}/%d)\n", $ipi{$vec} / $total_latency_sec, $total_latency_sec;
}
