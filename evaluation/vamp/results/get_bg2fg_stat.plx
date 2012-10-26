#!/usr/bin/perl -w

die "Usage: $0 <threadinfo dir>\n" unless @ARGV == 1;
$dir = shift(@ARGV);
@files = `ls $dir/g1.*`;

foreach $f (@files) {
	chomp($f);
	$nr_vcpu_task_switch=`grep nr_vcpu_task_switch $f | tail -n1 | awk '{print \$3}'`;
	$nr_vcpu_task_switch = int($nr_vcpu_task_switch);
	if ($nr_vcpu_task_switch > 0) {
		$prev_nr_vcpu_task_switch = `grep nr_vcpu_task_switch  $f | head -n1 | awk '{print \$3}'`;
		$prev_nr_vcpu_fg_switch = `grep nr_vcpu_fg_switch  $f | head -n1 | awk '{print \$3}'`;
		$prev_nr_vcpu_bg2fg_switch = `grep nr_vcpu_bg2fg_switch $f | head -n1 | awk '{print \$3}'`;

		$nr_vcpu_bg2fg_switch = `grep nr_vcpu_bg2fg_switch $f | tail -n1 | awk '{print \$3}'`;
		$nr_vcpu_fg_switch = `grep nr_vcpu_fg_switch $f | tail -n1 | awk '{print \$3}'`;

		$nr_vcpu_task_switch -= $prev_nr_vcpu_task_switch;
		$nr_vcpu_fg_switch -= $prev_nr_vcpu_fg_switch;
		$nr_vcpu_bg2fg_switch -= $prev_nr_vcpu_bg2fg_switch;
		printf "$f: bg2fg/fg=%.3lf%% ($nr_vcpu_bg2fg_switch / $nr_vcpu_fg_switch) fg/total=%.3lf%% ($nr_vcpu_fg_switch/$nr_vcpu_task_switch)\n", $nr_vcpu_bg2fg_switch * 100 / $nr_vcpu_fg_switch, $nr_vcpu_fg_switch * 100 / $nr_vcpu_task_switch;
		$total_vcpu_bg2fg_switch += $nr_vcpu_bg2fg_switch;
		$total_vcpu_fg_switch += $nr_vcpu_fg_switch;
	}
}
print "# total_vcpu_bg2fg_switch=$total_vcpu_bg2fg_switch\n";
printf "total=%.3lf%% ($total_vcpu_bg2fg_switch/$total_vcpu_fg_switch)\n", 
	$total_vcpu_bg2fg_switch * 100 / $total_vcpu_fg_switch;
