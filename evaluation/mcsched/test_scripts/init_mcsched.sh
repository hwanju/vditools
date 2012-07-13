#!/bin/sh
if [ $# -lt 1 ]; then
	echo "Usage $0 <0=off|1=on> [urgent_enabled:tslice:allowance:tlb:unlock:cosched]"
	exit
fi
on=$1

nr_params=6
param_path=(/proc/sys/kernel/sched_urgent_enabled /proc/sys/kernel/sched_urgent_tslice_limit_ns /proc/sys/kernel/sched_urgent_latency_ns /sys/module/kvm/parameters/tlb_shootdown_cosched_enabled /sys/module/kvm/parameters/resched_ipi_unlock_latency_ns /sys/module/kvm/parameters/resched_ipi_cosched_tslice_ns)

if [ $on -eq 0 ]; then
	params="0:0:0:0:0:0"
elif [ $# -ge 2 ]; then
	params=$2
else
	params="1:500000:18000000:1:500000:500000"	# default
fi

# init cgroup
if [ ! -e /cpuctl/g1 ]; then
	cpuctl=/cpuctl
	mkdir -p $cpuctl
	mount -t cgroup -o cpu none $cpuctl
	for i in `seq 1 10`; do
		mkdir -p $cpuctl/g$i
	done
fi

for i in `seq $nr_params`; do
	param_idx=$(( $i - 1 ))
	val=`echo $params | cut -d: -f$i`
	if [ "$val" == "" ]; then
		echo "Warning: value is not defined for ${param_path[$param_idx]}!"
		continue
	fi
	echo $val > ${param_path[$param_idx]}
	echo -n `basename ${param_path[$param_idx]}` " = "
	cat ${param_path[$param_idx]}
done

