#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 <mode: nouvf, tlbco, tlbco+reschedpd, tlbco+reschedpd+reschedco> workload ..."
	exit
fi
mode=$1
shift
if [ "$mode" == "nouvf" ]; then
	eval_params="0:0:0:0:0:0"
elif [ "$mode" == "tlbco" ]; then
	eval_params="1:500000:18000000:1:0:0"
elif [ "$mode" == "tlbco+reschedpd" ]; then
	eval_params="1:500000:18000000:1:500000:0"
elif [ "$mode" == "tlbco+reschedpd+reschedco" ]; then
	eval_params="1:500000:18000000:1:500000:500000"
else
	echo "mode is invalid!"
	exit
fi
#workload_list="1parsec+2x264 1parsec+4x264 1parsec+1streamcluster 1parsec+1freqmine 1parsec+1dedup"
workload_list="1parsec+2x264 1parsec+4x264 1parsec+1streamcluster 1parsec+1freqmine"
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
		mixed=1 params=$eval_params ./test_scripts/mcsched.sh $workload fairbal_pct100
	fi
done
