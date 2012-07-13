#!/usr/bin/perl -w

die "Usage: $0 <schedstat file>\n" unless @ARGV;
$fn = shift(@ARGV);
open FD, $fn or die "file open error: $fn\n";
$stage = -1;

@stat_names = qw( preempt_delay preempt_delay_timer mod_urgent_timer urgent_timer urgent_running urgent_queued urgent_enqueue urgent_requeue_tail urgent_requeue_head urgent_dequeue urgent_fail );

$urgent_start_idx = 10;
$nr_urgent_stat = int(@stat_names);
while(<FD>) {
	if (/^start_time=(\d+)/) {
		$start_time = $1;
		$stage++;
	}
	elsif (/^end_time=(\d+)/) {
		$end_time = $1;
		$stage++;
	}
	elsif ($stage >= 0 && /^cpu\d+/) {
		@stat = split(/\s+/);
		for $i ( $urgent_start_idx .. ($urgent_start_idx + $nr_urgent_stat - 1) ) {
			$urgent_stat[$stage][$i-$urgent_start_idx] += $stat[$i];
		}
	}
}
printf "# time(s)=%d\n# ", $end_time - $start_time;
for $n (@stat_names) {
	print "$n\t";
}
print "\n";
for $i (0 .. ($nr_urgent_stat - 1)) {
	printf "%d\t", $urgent_stat[1][$i] - $urgent_stat[0][$i];
}
print "\n";
