#!/usr/bin/perl -w

@trace_files = `ls *.debug`;

# linux-specific ipi info
$ipi_name{0xfd} = "Reschedule";
$start_tlb_vec = 0xcf;
$nr_vcpus = 8;
foreach $vec ($start_tlb_vec .. ($start_tlb_vec + $nr_vcpus - 1)) {
	$ipi_name{$vec} = "TLB";
}
$ipi_name{0xfc} = "Call";

print "# nr_ipi/sec\n";
foreach $fn (@trace_files) {
	$workload = $1 if ($fn =~ /1(\w+)@/);
	print "\t$workload";
	push(@workload_list, $workload);
	open FD, $fn;
	$start_time_us = 0;
	while(<FD>) {
		if (/(\d+) \d+ I ([0-9a-f]+)/) {
			$time_us = $1;
			$start_time_us = $time_us if $start_time_us == 0;
			$ipi{$ipi_name{hex($2)}}{$workload}++;
		}
	}
	$time_sec{$workload} = ($time_us - $start_time_us) / 1000000;
}
print "\n";
foreach $vec (keys %ipi) {
	print "$vec";
	foreach $workload (@workload_list) {
		$nr_ipi = defined($ipi{$vec}{$workload}) ? $ipi{$vec}{$workload} : 0;
		printf "\t%d", $nr_ipi / $time_sec{$workload};
	}
	print "\n";
}
