#!/usr/bin/perl -w

die "Usage: $0 <log file> <latency file>\n" unless @ARGV == 2;

$log_fn = shift(@ARGV);
$lat_fn = shift(@ARGV);

@lats = `cat $lat_fn`;
$lastline = `grep id= $log_fn | tail -1`;
$nr_lats = `wc -l $lat_fn | awk '{print \$1}'`;
$last_id = $1 if ($lastline =~ /id=(\d+)/);
$start_id = $last_id - $nr_lats + 1;

open FD, "$log_fn" or die "file open error: $log_fn\n";
$id = 0;
while(<FD>) {
        if (/(\d+) UI \d+ \d+ \d+ id=(\d+)/) {
                $time_us = $1;

                if ($id >= $start_id) {
                        $log_enabled = 1;
                        if (!$input_time_us || $2 != $id) {
                                $input_time_us = $time_us;
                        }
                }
                $id = $2;
        }
        if ($log_enabled && /(\d+) V \d+ (\d+) \d+ (\d+) (\d+)/) {
                $vcpu_id = $2;
                $vcpu_sched_time_us{$vcpu_id} = $1;
                $run_delay = $3;
                $vcpu_flags{$vcpu_id} = $4;
                if ($prev_run_delay{$vcpu_id}) {
                        $vcpu_wait_time_ns{$vcpu_id} = $run_delay - $prev_run_delay{$vcpu_id};
                }
                $prev_run_delay{$vcpu_id} = $run_delay;
        }
        if ($log_enabled && /(\d+) G \d+ (\d+) \d+ \S+ (\d+)/) {
                $time_us = $1;
                $vcpu_id = $2;
                $gtask_flags = $3;

                if (defined($vcpu_wait_time_ns{$vcpu_id})) {
                        if ($gtask_flags == 0) {        # for interactive task
                                if ($vcpu_flags{$vcpu_id} == 2) {
                                        # an interactive task is scheduled on a background vcpu
                                        $mode = 1;
                                }
                                else {
                                        $mode = 0;
                                }
                                $gtask_wait_time_us = $time_us - $vcpu_sched_time_us{$vcpu_id};
                                $gtask_wait_time_us += $vcpu_wait_time_ns{$vcpu_id} / 1000;

                                if ($time_us - $input_time_us <= $lats[$id - $start_id] * 1000) {
                                        print "$mode\t$gtask_wait_time_us\n";
                                }
                        }
                }

        }
}
