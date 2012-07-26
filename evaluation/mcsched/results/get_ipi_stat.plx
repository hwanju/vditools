#!/usr/bin/perl -w

die "Usage: $0 [-t] <linux|windows> <trace file list>\n" unless @ARGV > 1;
$tabular = $ARGV[0] eq "-t" ? shift(@ARGV) : 0;
$os = shift(@ARGV);

if ($os eq "linux") {
	# linux-specific ipi info
	$ipi_name{0xfd} = "Reschedule";
	$start_tlb_vec = 0xcf;
	$nr_vcpus = 8;
	foreach $vec ($start_tlb_vec .. ($start_tlb_vec + $nr_vcpus - 1)) {
		$ipi_name{$vec} = "TLB";
	}
	$ipi_name{0xfc} = "Call";
}

print "# nr_ipi/sec\n";
print "Application";
foreach $fn (@ARGV) {
	$workload = $1 if ($fn =~ /1(\w+)@/);
	if ($tabular) {
		print "\t& $workload";
	}
	else {
		print "\t$workload";
	}
	push(@workload_list, $workload);
	open FD, $fn;
	$start_time_us = 0;
	while(<FD>) {
		if (/(\d+) \d+ I ([0-9a-f]+)/) {
			$time_us = $1;
			$start_time_us = $time_us if $start_time_us == 0;
			if (defined($ipi_name{hex($2)})) {
				$ipi{$ipi_name{hex($2)}}{$workload}++;
			}
			else {
				$ipi{$2}{$workload}++;
			}
		}
	}
	$time_sec{$workload} = ($time_us - $start_time_us) / 1000000;
}
if ($tabular) {
	print " \\\\ \\hline \\hline \n";
}
else {
	print "\n";
}
foreach $vec (keys %ipi) {
	print "$vec";
	foreach $workload (@workload_list) {
		$nr_ipi = defined($ipi{$vec}{$workload}) ? $ipi{$vec}{$workload} : 0;
		if ($tabular) {
			printf "\t& %d", $nr_ipi / $time_sec{$workload};
		}
		else {
			printf "\t%d", $nr_ipi / $time_sec{$workload};
		}
	}
	if ($tabular) {
		print " \\\\ \\hline \n";
	}
	else {
		print "\n";
	}
}

