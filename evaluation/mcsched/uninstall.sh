#!/bin/sh

eval_name=mcsched

if [ $# -ne 1 ]; then
	echo "Usage: $0 <skbench dir>"
	exit
fi
skbench_dir=$1
if [ ! -e $skbench_dir ]; then
	echo "Error: $skbench_dir doesn't exist."
	exit
fi

make clean
rm -f $skbench_dir/config $skbench_dir/virsh $skbench_dir/scripts/$eval_name $skbench_dir/workloads/$eval_name $skbench_dir/test_scripts $skbench_dir/chcfg $skbench_dir/results/$eval_name
