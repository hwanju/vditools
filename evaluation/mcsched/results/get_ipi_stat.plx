#!/usr/bin/perl -w

die "Usage: $0 [-t: tabular|-p: plot] <linux|windows> <trace file list>\n" unless @ARGV > 1;
$opt = $ARGV[0] eq "-t" ? shift(@ARGV) : ($ARGV[0] eq "-p" ? shift(@ARGV) : "");
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

if ($opt ne "-p") {
	print "# nr_ipi/sec\n";
	print "Application";
}
foreach $fn (@ARGV) {
	$workload = $1 if ($fn =~ /1(\w+)@/);
	if ($opt eq "-t") {
		print "\t& $workload";
	}
	elsif ($opt eq "") {
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
				if ($opt eq "-p") {
					$ipi{$workload}{$ipi_name{hex($2)}}++;
				}
				else {
					$ipi{$ipi_name{hex($2)}}{$workload}++;
				}
			}
			else {
				if ($opt eq "-p") {
					$ipi{$workload}{$2}++;
				}
				else {
					$ipi{$2}{$workload}++;
				}
			}
		}
	}
	$time_sec{$workload} = ($time_us - $start_time_us) / 1000000;
}
if ($opt eq "-t") {
	print " \\\\ \\hline \\hline \n";
}
elsif ($opt eq "") {
	print "\n";
}

if ($opt eq "-p") {
	print "# nr_ipi/sec";
	foreach $vec (keys %{$ipi{$workload_list[0]}}) {
		print "\t$vec";
	}
	print "\n";

	foreach $workload (@workload_list) {
		print "$workload";
		foreach $vec (keys %{$ipi{$workload}}) {
			next if ($os eq "linux" && $vec eq "Call");
			$nr_ipi = defined($ipi{$workload}{$vec}) ? $ipi{$workload}{$vec} : 0;
			printf "\t%d", $nr_ipi / $time_sec{$workload};
		}
		print "\n";
	}
}
else {
	foreach $vec (keys %ipi) {
		print "$vec";
		foreach $workload (@workload_list) {
			$nr_ipi = defined($ipi{$vec}{$workload}) ? $ipi{$vec}{$workload} : 0;
			if ($opt eq "-t") {
				printf "\t& %d", $nr_ipi / $time_sec{$workload};
			}
			elsif ($opt eq "") {
				printf "\t%d", $nr_ipi / $time_sec{$workload};
			}
		}
		if ($opt eq "-t") {
			print " \\\\ \\hline \n";
		}
		elsif ($opt eq "") {
			print "\n";
		}
	}
}
