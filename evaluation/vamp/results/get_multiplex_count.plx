#!/usr/bin/perl -w

die "Usage: $0 <debug file>\n" unless @ARGV == 1;
$fn = shift(@ARGV);
open FD, $fn or die "file open error: $fn\n";
while(<FD>) {
	if (/(GA|GD) d(\d+)_v(\d+)-p\d+ t=([0-9a-f]+) f=(\d)/) {
		$op = $1;
		$vm_id = $2;
		$vcpu_id = $3;
		$task_id = $4;
		$flags = $5;

		if ($op eq "GA") {
			if ($cur_flags{$vm_id}{$vcpu_id} && $flags == 0) {
				if ($cur_fg{$vm_id}{$vcpu_id} && $cur_fg{$vm_id}{$vcpu_id} eq $task_id) {
					print "$_";
					$nr_fg_sandwitch++;
				}
				$cur_fg{$vm_id}{$vcpu_id} = $task_id;
				$nr_bg2fg++;
			}
			elsif (!$cur_flags{$vm_id}{$vcpu_id} && $flags) {
				$nr_fg2bg++;
			}
		}
		else {	# depart
			$cur_flags{$vm_id}{$vcpu_id} = $flags;
		}
	}
}
print "nr_bg2fg=$nr_bg2fg nr_fg2bg=$nr_fg2bg nr_fg_sandwitch=$nr_fg_sandwitch\n";
