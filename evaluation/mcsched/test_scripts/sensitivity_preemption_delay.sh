#!/bin/sh
# for sanity check
#workloads="streamcluster"
#delays="300000 500000"
workloads="streamcluster facesim bodytrack"
delays="0 100000 300000 500000 700000 1000000"

for i in `seq 5`; do
	for w in $workloads; do
		echo 0 > /sys/module/kvm/parameters/ipi_early_preemption_delay
		for d in $delays; do
			params=1:5000000:18000000:0:$d:0 nr_iter=1 cfg_postfix=-lockholder res_postfix=-$i arg1=/root/scripts/systemtap/trace_lhp.ko arg2=solo_ipisched ./test_scripts/mcsched.sh 1$w+1dedup fairbal_pct100
		done
		echo 1 > /sys/module/kvm/parameters/ipi_early_preemption_delay
		params=1:5000000:18000000:0:1000000:0 nr_iter=1 cfg_postfix=-lockholder res_postfix=-earlypd-$i arg1=/root/scripts/systemtap/trace_lhp.ko arg2=solo_ipisched ./test_scripts/mcsched.sh 1$w+1dedup fairbal_pct100
	done
done
echo 0 > /sys/module/kvm/parameters/ipi_early_preemption_delay
