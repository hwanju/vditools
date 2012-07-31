#!/usr/bin/perl -w

while(<>) {
        if (/(\d+)\s+SI d(\d+)_v(\d+)-p\d+ v=fd/) {
                $vm_id = $2;
                $vcpu_id = $3;
                $state{$vm_id}{$vcpu_id} = 1;   # sent
                $tx_time_us{$vm_id}{$vcpu_id} = $1;
        }
        elsif (/(\d+)\s+OP mod d(\d+)_v(\d+)-p\d+:l(\d+) ts=(\d+) er=(\d+) rr=(\-?\d+)/) {
                $time_us = $1;
                $vm_id = $2;
                $vcpu_id = $3;
                $local = $4;
                $urgent_tslice = $5;
                $exec_time = $6;
                $remaining_runtime = $7;

                if ($local && $state{$vm_id}{$vcpu_id} == 1) {    # sent
                        $latency_us = $time_us - $tx_time_us{$vm_id}{$vcpu_id};
                        if ($latency_us > 200) {
                                print "Warning: latency ($latency_us) is too large at $time_us! tx_time=$tx_time_us{$vm_id}{$vcpu_id}\n";
                                $state{$vm_id}{$vcpu_id} = 0;
                        }
                }
        }
        elsif (/(\d+)\s+OP utm d(\d+)_v(\d+)-p\d+:l(\d+) dl=(\d+) pe=(\d+) ut=(\d+)/) {
                $time_us = $1;
                $vm_id = $2;
                $vcpu_id = $3;
                $local = $4;
                $delay = $5;
                #$urgent_runtime = $6;
                #$urgent = $7;
                if ($local && $state{$vm_id}{$vcpu_id} == 1) {    # sent
                        $state{$vm_id}{$vcpu_id} = 2;   # delayed
                        $delayed_time{$vm_id}{$vcpu_id} = $time_us + $delay;
                }
        }
        elsif (/(\d+)\s+S d(\d+)_v(\d+)-p\d+:u\dq(\d)/) {
                $time_us = $1;
                $vm_id = $2;
                $vcpu_id = $3;
                $on_rq = $4;
                if ($on_rq && defined($state{$vm_id}{$vcpu_id}) && $state{$vm_id}{$vcpu_id} == 2 &&       # delayed and involuntary preemption
                        $time_us < $delayed_time{$vm_id}{$vcpu_id}) {
                        $latency_us = $delayed_time{$vm_id}{$vcpu_id} - $time_us;
                        print "Warning: prematured preemption ($latency_us) at $time_us! delayed_time=$delayed_time{$vm_id}{$vcpu_id} tx_time=$tx_time_us{$vm_id}{$vcpu_id}\n";
                }
                $state{$vm_id}{$vcpu_id} = 0;
        }
}
