#!/bin/sh

eval_name=vamp

if [ $# -ne 1 ]; then
	echo "Usage: $0 <skbench dir>"
	exit
fi
skbench_dir=$1
if [ ! -e $skbench_dir ]; then
	echo "Error: $skbench_dir doesn't exist."
	exit
fi

# check custom config files
if [ ! -e config/eval_config ]; then
	echo "Error: config/eval_config doesn't exist."
	echo "cp config/eval_config.example config/eval_config"
	echo "# Then modify it for your environment"
	exit
fi
if [ ! -e virsh/guest_config ]; then
	echo "Error: config/guest_config doesn't exist."
	echo "cp config/guest_config.example config/guest_config"
	echo "# Then modify it for your environment"
	exit
fi

./uninstall.sh $skbench_dir

export SKBENCH_DIR=$skbench_dir
make
ln -sf $PWD/config $skbench_dir/
ln -sf $PWD/virsh $skbench_dir/
ln -sf $PWD/scripts $skbench_dir/scripts/$eval_name
ln -sf $PWD/workloads $skbench_dir/workloads/$eval_name
ln -sf $PWD/test_scripts $skbench_dir/
ln -sf $PWD/chcfg $skbench_dir/
mkdir -p $skbench_dir/results
ln -sf $PWD/results $skbench_dir/results/$eval_name
