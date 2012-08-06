#!/bin/sh
if [ $# -lt 1 ]; then
	echo "Usage $0 <0=off|1=on> [vamp:mixed_parallelism:bg_load_thresh_pct:load_monitor_window:max_interactive_phase_msec]"
	exit
fi
on=$1

nr_params=5
param_path=(/proc/sys/kernel/kvm_vamp /dev/null /sys/module/kvm/parameters/bg_load_thresh_pct /sys/module/kvm/parameters/load_monitor_window /sys/module/kvm/parameters/max_interactive_phase_msec)

default_params="33:8:60:30000000:5000"
if [ $on -eq 0 ]; then
	params="0:0:0:0:0:0"
elif [ $# -ge 2 ]; then
	params=$2
else
	params=$default_params
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
	echo $val > ${param_path[$param_idx]}
        if [ "${param_path[$param_idx]}" == "/dev/null" ]; then
                echo "mixed_parallelism = $val"
        else
	        echo -n `basename ${param_path[$param_idx]}` " = "
	        cat ${param_path[$param_idx]}
        fi

        next_i=$(( $i + 1 ))
	val=`echo $params | cut -d: -f$next_i`
        if [ "$val" == "" ]; then
                params=$default_params
        elif [ ! $(echo $params | grep :) ]; then
                params=$default_params
	fi
done
