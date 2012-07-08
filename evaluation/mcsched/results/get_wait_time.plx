#!/usr/bin/perl -w

die "Usage: $0 <threadinfo dir>\n" unless @ARGV == 1;
$dir = shift(@ARGV);
@files = `ls $dir/g1.*`;

foreach $f (@files) {
	chomp($f);
	$nr_vcpu_stacked=`grep vcpu_stacked $f | tail -n1 | awk '{print \$3}'`;
	if (int($nr_vcpu_stacked) > 0) {
		$prev_wait_sum = `grep se.statistics.wait_sum $f | head -n1 | awk '{print \$3}'`;
		$prev_wait_count = `grep se.statistics.wait_count $f | head -n1 | awk '{print \$3}'`;

		$wait_sum = `grep se.statistics.wait_sum $f | tail -n1 | awk '{print \$3}'`;
		$wait_count = `grep se.statistics.wait_count $f | tail -n1 | awk '{print \$3}'`;


		$wait_sum -= $prev_wait_sum;
		$wait_count -= $prev_wait_count;
		printf "$f: %.3lf ($wait_sum / $wait_count)\n", $wait_sum / $wait_count;
	}
}
