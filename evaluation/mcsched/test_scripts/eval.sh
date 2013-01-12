#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 <mode: nouvf, reschedpd, tlbco, reschedpd+tlbco, reschedpd+tlbco+reschedco> workload ..."
	exit
fi
mode=$1
shift
if [ "$mode" == "nouvf" ]; then
	eval_params="0:0:0:0:0:0"
elif [ "$mode" == "reschedpd" ]; then
	eval_params="1:500000:18000000:0:500000:0"
elif [ "$mode" == "tlbco" ]; then
	eval_params="1:500000:18000000:1:0:0"
elif [ "$mode" == "reschedpd+tlbco" ]; then
	eval_params="1:500000:18000000:1:500000:0"
elif [ "$mode" == "reschedpd+tlbco+reschedco" ]; then
	eval_params="1:500000:18000000:1:500000:500000"
else
	echo "mode is invalid!"
	exit
fi
ple_gap=`cat /sys/module/kvm_intel/parameters/ple_gap`;
if [ $ple_gap -gt 0 ]; then
	echo 2 > /sys/module/kvm/parameters/ple_aware_ipisched
	echo "ple is on: ple-aware ipisched enabled"
fi
workload_list="1parsec+2x264 1parsec+4x264 1parsec+1freqmine 1parsec+1dedup"
if [ "$1" != "all" ]; then
	workload_list="$*"
fi
for workload in $workload_list; do
	seq=0
	if [ $(echo $workload | grep 2x264) ]; then
		seq=1
	elif [ $(echo $workload | grep 4x264) ]; then
		seq=1
	fi
	if [ $seq -eq 0 ]; then
		params=$eval_params ./test_scripts/mcsched.sh $workload fairbal_pct100
	else
		#mixed=1 params=$eval_params ./test_scripts/mcsched.sh $workload fairbal_pct100
		cfg_postfix=-unfairlock res_postfix=-unfairlock mixed=1 params=$eval_params ./test_scripts/mcsched.sh $workload fairbal_pct100
	fi
done
