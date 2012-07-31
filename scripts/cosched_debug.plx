#!/usr/bin/perl -w

while(<>) {
        if (/(\d+)\s+UT d\d+_v\d+-p\d+->d(\d+)_v(\d+) ts=(\d+)/) {
                $vm_id = $2;
                $vcpu_id = $3;

                if (defined($on_cpu{$vm_id}{$vcpu_id}) && $on_cpu{$vm_id}{$vcpu_id} == 0) {
                        $state{$vm_id}{$vcpu_id} = 1;   # recved when not running
                        $rx_time_us{$vm_id}{$vcpu_id} = $1;
                }
        }
        elsif (/(\d+)\s+S d(\d+)_[vt](\d+)-p\d+:u\dq(\d)->d(\d+)_[vt](\d+)-p\d+:u(\d):ts(\d+)/) {
                $time_us = $1;
                $prev_vm_id = $2;
                $prev_vcpu_id = $3;
                $prev_on_rq = $4;
                $next_vm_id = $5;
                $next_vcpu_id = $6;
                $next_urgent = $7;
                $next_tslice = $8;

                if (defined($state{$next_vm_id}{$next_vcpu_id}) && $state{$next_vm_id}{$next_vcpu_id} == 1) {
                        $latency_us = $time_us - $rx_time_us{$next_vm_id}{$next_vcpu_id};

                        #print ("$time_us\t$latency_us\n");
                        print ("$rx_time_us{$next_vm_id}{$next_vcpu_id}\t$time_us\t$latency_us\n") if $latency_us > 1000;
                        $state{$next_vm_id}{$next_vcpu_id} = 0;
                }

                $on_cpu{$prev_vm_id}{$prev_vcpu_id} = 0;
                $on_cpu{$next_vm_id}{$next_vcpu_id} = 1;
        }
}
