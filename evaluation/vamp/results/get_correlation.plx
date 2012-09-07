#!/usr/bin/perl -w

die "Usage: $0 <file name w/o ext>\n" unless @ARGV == 1;
$fn = shift(@ARGV);
$lat_fn = "$fn.latency";
$sched_fn = "$fn.debug";
$out_fn = "$fn.correl";
$gtask_fn = "$fn.gtask";

open OFD, ">$out_fn";
open GFD, ">$gtask_fn";

open FD, $lat_fn or die "file open error: $lat_fn\n";
$i = 0;
while(<FD>) {
	next if $i++ % 2;
	$lat_us[$i / 2] = int($_) * 1000; 
}
close FD;
open FD, $sched_fn or die "file open error: $sched_fn\n";
printf OFD "#idx\tlat\tftime\tbtime\tnr_bg\tbg2fg\tbf_wait\tvwait\tvsleep\tfwait\tbwait\tfsleep\tbsleep\tqwait\tqsleep\tqiowait\n";
printf GFD "#idx\tlat\tftime\tbtime\n";
while(<FD>) {
	if (/(\d+) UI \d+ (\d+)/) {
		$start_ui_time_us = $1;
		$ui_idx = $2;
		$lat_id = $ui_idx - 1;

		undef @prev_wait_sum;
		undef @prev_sleep_sum;
		$vcpu_wait_sum[0] = $vcpu_wait_sum[1] = 0;
		$vcpu_sleep_sum[0] = $vcpu_sleep_sum[1] = 0;
		$vcpu_runtime[0] = $vcpu_runtime[1] = 0;

		undef %prev_qemu_wait_sum;
		undef %prev_qemu_sleep_sum;
		undef %prev_qemu_iowait_sum;
		undef $qemu_wait_sum;
		undef $qemu_sleep_sum;
		undef $qemu_iowait_sum;

		undef %gtask_runtime;

		$wait_sum_bg2fg = 0;
		$nr_bg2fg = 0;

		$episode_finished = 0;
	}
	elsif (/(\d+) WT (\d+) (\d+) (\d+) (\d+)/) {
		next unless defined($lat_id);
		$time_us = $1;
		$vcpu_id = $2;
		$flags = $3 ? 1 : 0;
		$wait_sum = $4;
		$sleep_sum = $5;

		if ($time_us - $start_ui_time_us < $lat_us[$lat_id]) {		# within interative episode
			if (defined($prev_wait_sum[$vcpu_id])) {
				$cur_wait_sum = ($wait_sum - $prev_wait_sum[$vcpu_id]);
				$vcpu_wait_sum[$flags]  += $cur_wait_sum;
				$vcpu_sleep_sum[$flags] += ($sleep_sum - $prev_sleep_sum[$vcpu_id]);
				#print "$ui_idx: $time_us: $flags: $sleep_sum, $prev_sleep_sum[$vcpu_id] $vcpu_sleep_sum[$flags]\n";
			}

			$prev_wait_sum[$vcpu_id] = $wait_sum;
			$prev_sleep_sum[$vcpu_id] = $sleep_sum;

		}
		elsif (!$episode_finished) {	# out of episode, but not finished yet (1st out)
			$episode_finished = 1;

			#printf "ui$ui_idx (%d = $start_ui_time_us - $time_us), lat=$lat_us[$lat_id]\n", $time_us - $start_ui_time_us;
			$total_vcpu_wait_sum = $vcpu_wait_sum[0] + $vcpu_wait_sum[1];
			$total_vcpu_sleep_sum = $vcpu_sleep_sum[0] + $vcpu_sleep_sum[1];
			printf OFD "$ui_idx\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", 
				$lat_us[$lat_id] / 1000, 
				$vcpu_runtime[0] / 1000000, $vcpu_runtime[1] / 1000000,
				$nr_bg_tasks, $nr_bg2fg, $wait_sum_bg2fg / 1000000,
				$total_vcpu_wait_sum / 1000000, $total_vcpu_sleep_sum / 1000000,
				$vcpu_wait_sum[0] / 1000000, $vcpu_wait_sum[1] / 1000000, $vcpu_sleep_sum[0] / 1000000, $vcpu_sleep_sum[1] / 1000000,
				$qemu_wait_sum / 1000000, $qemu_sleep_sum / 1000000, $qemu_iowait_sum / 1000000;

			printf GFD "BEGIN $ui_idx\t%d\t%d\t%d\n", 
				$lat_us[$lat_id] / 1000, $vcpu_runtime[0] / 1000000, $vcpu_runtime[1] / 1000000;
			$fg_sum = $bg_sum = 0;
			foreach $gtask_name (sort keys %gtask_runtime) {
				$fg_time = defined($gtask_runtime{$gtask_name}[0]) ? $gtask_runtime{$gtask_name}[0] / 1000000 : 0;
				$bg_time = defined($gtask_runtime{$gtask_name}[1]) ? $gtask_runtime{$gtask_name}[1] / 1000000 : 0;
				if (int($fg_time) || int($bg_time)) {
					printf GFD "\t$gtask_name\t%d\t%d\n", $fg_time, $bg_time;
				}
				$fg_sum += $fg_time;
				$bg_sum += $bg_time;
			}
			printf GFD "END $ui_idx\t%d\t%d\n", $fg_sum, $bg_sum;

			$nr_bg_tasks = 0;
		}
	}
	elsif (/(\d+) RT \d+ (\d+) (\d+)/) {
		next unless defined($lat_id);
		$time_us = $1;
		$fg_runtime = $2;
		$bg_runtime = $3;

		if ($time_us - $start_ui_time_us < $lat_us[$lat_id]) {		# within interative episode
			$vcpu_runtime[0] += $fg_runtime;
			$vcpu_runtime[1] += $bg_runtime;

			#print "$fg_runtime\t$bg_runtime\n";
		}
	}
	elsif (/(\d+) QW (\d+) (\d+) (\d+) (\d+)/) {
		next unless defined($lat_id);
		$time_us = $1;
		$tid = $2;
		$wait_sum = $3;
		$sleep_sum = $4;
		$iowait_sum = $5;

		if ($time_us - $start_ui_time_us < $lat_us[$lat_id]) {		# within interative episode
			if (defined($prev_qemu_wait_sum{$tid})) {
				$qemu_wait_sum  += ($wait_sum - $prev_qemu_wait_sum{$tid});
				$qemu_sleep_sum  += ($sleep_sum - $prev_qemu_sleep_sum{$tid});
				$qemu_iowait_sum  += ($iowait_sum - $prev_qemu_iowait_sum{$tid});

				#print "$ui_idx: $time_us: $wait_sum, $prev_qemu_wait_sum{$tid} $qemu_wait_sum\n" if $ui_idx == 2;
			}
			$prev_qemu_wait_sum{$tid} = $wait_sum;
			$prev_qemu_sleep_sum{$tid} = $sleep_sum;
			$prev_qemu_iowait_sum{$tid} = $iowait_sum;
		}
	}
	elsif (/(\d+) GR [0-9a-f]+ (.+) (\d+) (\d+)/) {
		next unless defined($lat_id);
		$time_us = $1;
		$gtask_name = $2;
		$flags = $3 ? 1 : 0;
		$exec_time = $4;
		if ($time_us - $start_ui_time_us < $lat_us[$lat_id]) {
			$gtask_runtime{$gtask_name}[$flags] += $exec_time;
		}
	}
	elsif (/(\d+) BF \d+/) {
		$time_us = $1;
		if ($time_us - $start_ui_time_us < $lat_us[$lat_id] &&
		    defined($cur_wait_sum)) {
			$nr_bg2fg++;
			$wait_sum_bg2fg += $cur_wait_sum;
		}
	}
	elsif (/BG [0-9a-f]+ (\d+)/) {
		$flags = int($1);
		$nr_bg_tasks++ if $flags;
	}
}
close OFD;

open OFD, "$out_fn";
$n = -1;
while(<OFD>) {
	next if $n++ == -1;
	@vals = split(/\s+/);
	$i = 0;
	foreach $val (@vals) {
		$sum[$i++] += $val;
	}
}
close OFD;
open OFD, ">>$out_fn";
printf OFD "#idx\tlat\tftime\tbtime\tnr_bg\tbg2fg\tbf_wait\tvwait\tvsleep\tfwait\tbwait\tfsleep\tbsleep\tqwait\tqsleep\tqiowait\n";
$i = 0;
foreach $s (@sum) {
	if ($i++ == 0) {
		printf OFD "avg";
		next;
	}
	printf OFD "\t%d", $s / $n;
}
printf OFD "\n";
close OFD;
