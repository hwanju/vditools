#!/usr/bin/perl -w

die "Usage: $0 <linux|windows> <Reschedule|TLB> <bin in us> <trace file>\n" unless @ARGV == 4;
$os = shift(@ARGV);
$ipi_type = shift(@ARGV); 
$bin_us = shift(@ARGV);
$fn = shift(@ARGV); 

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
elsif ($os eq "windows") {
	$ipi_name{0x2f} = "Reschedule";
	$ipi_name{0xe1} = "TLB";
}
else {
	die "os type is linux or windows\n";
}

$workload = $1 if ($fn =~ /1(\w+)@/);
$workload = $fn unless defined($workload);
open FD, $fn;
$bin_id = $prev_bin_id = $start_time_us = 0;
while(<FD>) {
	if (/(\d+) \d+ I ([0-9a-f]+)/) {
		next unless defined($ipi_name{hex($2)}) && $ipi_name{hex($2)} eq $ipi_type;
		$time_us = $1;
		$start_time_us = $time_us if $start_time_us == 0;

		$bin_id = int(($time_us - $start_time_us) / $bin_us);
		$ipi[$bin_id]++;

		print "$time_us $bin_id $ipi[$bin_id]\n";

		$prev_bin_id = $bin_id;
	}
}
close FD;
$out_fn = "$workload-$ipi_type-bin${bin_us}us.dat";
open FD, ">$out_fn";
for $bin_id (0 .. $prev_bin_id) {
	printf FD "$bin_id\t%d\n", $ipi[$bin_id] ? $ipi[$bin_id] : 0;
}
