#!/usr/bin/perl -w

die "Usage: $0 <debug file> <bg task id>\n" unless @ARGV == 2;
$fn = shift(@ARGV);
$task_id = shift(@ARGV);
open FD, "$fn" or die "file open error: $fn\n";

while(<FD>) {
	if (/IPI fd (\w+) d\d+_v\d+ d(\d+)_v(\d+) pgd=([0-9a-f]+) src_waker=([0-9a-f]+)/) {
		$src_task_name = $1;
		$vm_id = $2;
		$vcpu_id = $3;
		$src_pgd = $4;
		$src_waker = $5;
		if ($src_waker eq $task_id) {
			$ipi_waker_tgid{$vm_id}{$vcpu_id} = int($1) if /tgid=(\d+)/;
			$ipi_waker_name{$vm_id}{$vcpu_id} = $src_task_name;
			$ipi_waker_pgd{$vm_id}{$vcpu_id} = $src_pgd;
		}
	}
	elsif (/(\d+)\s+GA d(\d+)_v(\d+)-p\d+ t=[0-9a-f]+ f=\d n=(\w+)/) {
		$time = $1;
		$vm_id = $2;
		$vcpu_id = $3;
		$task_name = $4;

		if (/ id=(\d+)/) {
			$tgid = int($1);
			$curr_tgid{$vm_id}{$vcpu_id} = $tgid;
			$tgid_to_name{$tgid} = $task_name;
		}
		if (/ptgid=(\d+)/) {
			$remote_pending_tgid = int($1);
			$curr_ptgid{$vm_id}{$vcpu_id} = $remote_pending_tgid;
		}
		if (/wval=1/) {
			$ipi_wakeup_latency{$vm_id}{$vcpu_id} = $time - $ipi_injected_time{$vm_id}{$vcpu_id};
		}
	}
	elsif (/(\d+)\s+IJI d(\d+)_v(\d+)-p\d+ irq=fd/) {
		$ipi_injected_time{$2}{$3} = $1;
	}
	elsif (/AC d(\d+)_v(\d+)-p\d+/) {
		$vm_id = $1;
		$vcpu_id = $2;
		$rwaker = $1 if (/rwaker=([0-9a-f]+)/);
		if ($rwaker eq $task_id) {
			if ($ipi_waker_tgid{$vm_id}{$vcpu_id} == $curr_tgid{$vm_id}{$vcpu_id}) {
				if ($ipi_waker_pgd{$vm_id}{$vcpu_id} eq $task_id) {
					print "[Error] BG wakes up AUDIO task! Check it!\n";
				}
				else {
					print "[Warning] BG pretend to wake up AUDIO task! origianl source is $ipi_waker_name{$vm_id}{$vcpu_id}. Check it!\n";
				}
				print "\t$_";
			}
			else {
				printf "[Verified] ipi_waker_tgid=$ipi_waker_tgid{$vm_id}{$vcpu_id}($tgid_to_name{$ipi_waker_tgid{$vm_id}{$vcpu_id}}) != curr_tgid=$curr_tgid{$vm_id}{$vcpu_id}($tgid_to_name{$curr_tgid{$vm_id}{$vcpu_id}}) curr_ptgid=$curr_ptgid{$vm_id}{$vcpu_id} (%s) ipi_waker_latency=$ipi_wakeup_latency{$vm_id}{$vcpu_id}us\n", $curr_tgid{$vm_id}{$vcpu_id} == $curr_ptgid{$vm_id}{$vcpu_id} ? "SAME: Multiple remote wake-up pending" : "DIFFERENT: One remote wake-up, but no preemption";
				print "\t$_";
			}
		}
	}
}
