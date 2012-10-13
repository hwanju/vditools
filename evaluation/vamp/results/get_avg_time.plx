#!/usr/bin/perl -w

die "Usage: $0 <result file> <# of samples> [# of VMs to be calculated (default=0 --> all, -1 to skip the first)]\n" unless @ARGV >= 2;
$res_file = shift(@ARGV);
$nr_samples = shift(@ARGV);
$nr_vms = @ARGV ? shift(@ARGV) : 0;

$total = $sqtotal = $n = 0;
open FD, $res_file;
while(<FD>) {
	if (/Guest(\d+):/) {
		last if ($nr_vms > 0 && $1 > $nr_vms);
		next if ($nr_vms == -1 && $1 == 1);
		$vm_id = $1;
	}
	elsif (defined($vm_id) && /Elapsed.+: ([0-9:]+)/) {
		next if defined($vm_count{$vm_id}) && $vm_count{$vm_id} >= $nr_samples;
		@times = split(/:/, $1);
		$nr_times = int(@times);
		if ($nr_times == 2) {
			$sec = $times[0] * 60 + $times[1];
		}
		elsif ($nr_times == 3) {
			$sec = $times[0] * 3600 + $times[1] * 60 + $times[2];
		}
		$total += $sec;
		$sqtotal += ($sec * $sec);
		$n++;
		$vm_count{$vm_id}++;
	}
}
close FD;
$avg = $n ? $total / $n : 0;
$sd = sqrt(($sqtotal / $n) - ($avg * $avg));
printf "avg=%.2lf sd=%.2lf count=%d\n", $avg, $sd, $n;
