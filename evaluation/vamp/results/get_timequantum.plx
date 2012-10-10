#!/usr/bin/perl -w

$debug = 0;

die "Usage: $0 <trace file> [task name]\n" unless @ARGV >= 1;
$fn = shift(@ARGV);
if (@ARGV) {
	$tname = shift(@ARGV);
}
else {
	$tname = $1 if ($fn =~ /1(\w+)\@/);
}

open FD, $fn or die "file open error: $fn\n";
$log_fn = $fn;
$log_fn =~ s/\.\w+$/-$tname\.log/g;
open LFD, ">$log_fn";

my @accum_exec_time_ns;
my %time_quantum;

sub account_time_quantum {
	$tid  = $_[0];
	$time = $_[1];
	if ($tid && $time) {
		push(@{$time_quantum{$tid}}, $time);

		print LFD "\taccount: $tid <- $time\n" if $debug;
	}
	else {
		print LFD "\taccount: ignored\n" if $debug;
	}
}

sub accum_time_quantum {
	$vid  = $_[0];
	$time = $_[1];

	$accum_exec_time_ns[$vid] += $time;

	print LFD "\taccum: $vid += $time = $accum_exec_time_ns[$vid]\n" if $debug;
}

while(<FD>) {
	if (/^(\d+) (\w+) (\S+) (\d+) (\d+) (\d+)/) {
		$vcpu_id = $1;
		$task_id = $2;
		$task_name = $3;
		$task_count{$task_name}{$task_id}++;
		$exec_time_ns = $4;
		$prev_state = $5;
		$nr_gtask_switch = $6;

		print LFD "$_" if $debug;

		if ($nr_gtask_switch == 1) {	# first task
			if ($prev_state) {	# desched with runnable
				accum_time_quantum($vcpu_id, $exec_time_ns);
			}
			else {	# desched as blocked
				account_time_quantum($prev_task_id[$vcpu_id], 
						     $accum_exec_time_ns[$vcpu_id]);
				$accum_exec_time_ns[$vcpu_id] = $exec_time_ns;
			}
		}
		else {	# after first task
			if (defined($prev_task_id[$vcpu_id]) && 
			    $prev_task_id[$vcpu_id] eq $task_id) {
				accum_time_quantum($vcpu_id, $exec_time_ns);
			}
			else {
				if ($nr_gtask_switch == 2 && $prev_state == 0) {
					print LFD "\taccount: ignore the firsly task's time after blocked\n" if $debug;
				}
				else {
					account_time_quantum($prev_task_id[$vcpu_id], 
						$accum_exec_time_ns[$vcpu_id]);
				}
				$accum_exec_time_ns[$vcpu_id] = $exec_time_ns;
			}
		}
		$prev_task_id[$vcpu_id] = $task_id;
	}
}


foreach $task_name (sort keys %task_count) {
	foreach $task_id (sort {$task_count{$task_name}{$b} <=> $task_count{$task_name}{$a}} keys %{$task_count{$task_name}}) {
		print LFD "$task_name\t$task_id\t$task_count{$task_name}{$task_id}\n";
	}
}

foreach $task_id (sort {$task_count{$tname}{$b} <=> $task_count{$tname}{$a}} keys %{$task_count{$tname}}) {
	print LFD "$tname\t$task_id\t$task_count{$tname}{$task_id}\n";
	$designated_task_id = $task_id if !defined($designated_task_id) && $task_id ne "01a03";
}
print LFD "designated_task_id = $designated_task_id\n";

foreach $task_id (keys %time_quantum) {
	next if ($task_id ne $designated_task_id);
	print LFD "$task_id\n";
	$total = int(@{$time_quantum{$task_id}});
	$step = 100 / $total;
	$out_fn = $fn;
	$out_fn =~ s/\.\w+$/-$tname\.tqcdf/g;
	open OFD, ">$out_fn";
	$pct = 0;
	foreach $t (sort {$a <=> $b} @{$time_quantum{$task_id}}) {
		$pct += $step;
		printf OFD "$t\t%.3lf\n", $pct;
	}
	close OFD;
}
