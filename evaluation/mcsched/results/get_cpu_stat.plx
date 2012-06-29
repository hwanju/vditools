#!/usr/bin/perl -w
$filter = @ARGV ? shift(@ARGV) : "";

@res_files = `ls *$filter*.result`;
printf "%-15suser\tnice\tsystem\tidle\tiowait\tirq\tsoftirq\tsteal\tguest\tgnice\n", "workload";
foreach $fn (@res_files) {
	open FD, $fn;
	$workload = $1 if ($fn =~ /1(\w+)(@|\+)/);
	$first = 1;
	while(<FD>) {
		if (/^cpu\s+/) {
			@stat = split(/\s+/);
			if ($first) {
				@prev_stat = @stat;
				$first = 0;
			}
			else {
				printf "%-15s", $workload;
				$total = 0;
				for $i (1 .. 10) {
					$stat[$i] -= $prev_stat[$i];
					$total += $stat[$i];

				}
				for $i (1 .. 10) {
					printf "$stat[$i](%d)\t", $stat[$i] * 100 / $total;
				}
				$user = $stat[1] + $stat[2];
				$sys  = $stat[3] + $stat[6] + $stat[7];
				$all = $user + $sys;
				printf "%d\t%d\n", $user * 100 / $all, $sys * 100 / $all;
				last;
			}
		}
	}
	close (FD);
}
