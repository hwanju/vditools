#!/bin/sh
if [ $# -lt 1 ]; then
	echo "Usage $0 <0=off|1=on> [extra arg(currently time-related parameter)]"
	exit
fi
on=$1

time_ns=500000
if [ $# -ge 2 ]; then
	time_ns=$2
fi

if [ ! -e /cpuctl/g1 ]; then
	cpuctl=/cpuctl
	mkdir -p $cpuctl
	mount -t cgroup -o cpu none $cpuctl
	for i in `seq 1 10`; do
		mkdir -p $cpuctl/g$i
	done
fi
if [ $on -eq 0 ]; then
	echo 0 > /proc/sys/kernel/sched_urgent_enabled
	echo 0 > /proc/sys/kernel/sched_urgent_tslice_limit_ns
	echo 0 > /sys/module/kvm/parameters/resched_ipi_unlock_latency_ns
	echo 0 > /sys/module/kvm/parameters/resched_ipi_cosched_tslice_ns
	echo 0 > /sys/module/kvm/parameters/tlb_shootdown_cosched_enabled

	echo "mcsched off"
else
	echo 1 > /proc/sys/kernel/sched_urgent_enabled
	#echo $time_ns > /proc/sys/kernel/sched_urgent_tslice_limit_ns
	echo 500000 > /proc/sys/kernel/sched_urgent_tslice_limit_ns
	#echo $time_ns > /sys/module/kvm/parameters/resched_ipi_unlock_latency_ns
	echo 500000 > /sys/module/kvm/parameters/resched_ipi_unlock_latency_ns
	echo 0 > /sys/module/kvm/parameters/resched_ipi_cosched_tslice_ns
	#echo $time_ns > /sys/module/kvm/parameters/tlb_shootdown_latency_ns
	#echo 500000 > /sys/module/kvm/parameters/tlb_shootdown_latency_ns
	echo 1 > /sys/module/kvm/parameters/tlb_shootdown_cosched_enabled

	echo "mcsched on w/ $time_ns"
fi
