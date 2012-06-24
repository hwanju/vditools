#!/bin/sh
if [ $# -ne 1 ]; then
	echo "Usage $0 <0=off|1=on>"
	exit
fi
on=$1

if [ ! -e /cpuctl/g1 ]; then
	cpuctl=/cpuctl
	mkdir -p $cpuctl
	mount -t cgroup -o cpu none $cpuctl
	for i in `seq 1 10`; do
		mkdir -p $cpuctl/g$i
		echo 65536 > $cpuctl/g$i/cpu.shares
	done
fi
if [ $on -eq 0 ]; then
	echo 0 > /proc/sys/kernel/sched_urgent_enabled
	echo 0 > /proc/sys/kernel/sched_urgent_tslice_limit_ns
	echo 0 > /sys/module/kvm/parameters/resched_ipi_unlock_latency_ns
	echo 0 > /sys/module/kvm/parameters/resched_ipi_cosched_tslice_ns
	echo 0 > /sys/module/kvm/parameters/tlb_shootdown_latency_ns

	echo "mcsched off"
else
	echo 1 > /proc/sys/kernel/sched_urgent_enabled
	echo 1000000 > /proc/sys/kernel/sched_urgent_tslice_limit_ns
	echo 500000 > /sys/module/kvm/parameters/resched_ipi_unlock_latency_ns
	echo 500000 > /sys/module/kvm/parameters/resched_ipi_cosched_tslice_ns
	echo 500000 > /sys/module/kvm/parameters/tlb_shootdown_latency_ns

	echo "mcsched on"
fi
