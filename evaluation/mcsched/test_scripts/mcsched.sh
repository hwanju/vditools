#!/bin/bash

if [ "$parsec_workloads" == "" -a "$interactive_workloads" == "" ]; then
	source workloads/mcsched/workloads.inc
fi
if [ "$nr_iter" == "" ]; then
	nr_iter=3
fi
avail_mode_list="baseline purebal purebal_mig fairbal_pct0 fairbal_pct150 fairbal_pct100"

if [ $# -le 1 ]; then
        echo "Usage: $0 <workload format> <mode list: $avail_mode_list all>"
	echo "	workload format := MW | NW+NW"
	echo "		N := # of workloads"
	echo "		W := workload name"
	echo "	if W is 'parsec', iteratively replace each of parsec workloads."
        exit
fi

workload_format=$1
if [ $(echo $workload_format | grep parsec) ]; then
	workload_list=$parsec_workloads
	resdir=results/mcsched/_$workload_format
elif [ $(echo $workload_format | grep interactive) ]; then
	workload_list=$interactive_workloads
	resdir=results/mcsched/_$workload_format
else
	workload_list=$(echo $workload_format | sed 's/+.*//g')
	workload_list=$(echo $workload_list | sed 's/^[0-9]*//g')
	resdir=results/mcsched
fi

if [ "$2" == "all" ]; then
        mode_list=$avail_mode_list
else
	shift 1
        mode_list=$*
fi
mkdir -p $resdir

for workload in $workload_list; do 
	for mode in $mode_list; do 
		workload_name=$(echo $workload_format | sed "s/parsec/$workload/g")
		workload_name=$(echo $workload_name | sed "s/interactive/$workload/g")
		workload_name=$workload_name@$mode
		workload_path=workloads/mcsched/$workload_name

		if [ -e $workload_path ]; then
			./test_scripts/wipe.sh

			if [ $(echo $mode | grep 'fairbal') ]; then
				./test_scripts/init_mcsched.sh 1
			else
				./test_scripts/init_mcsched.sh 0
			fi

			# change config.py
			rm -f config.pyc
			if [ $(cat $workload_path | grep 'windows/interactive') ]; then
				ln -sf config/config_1win7_64bit+7ubuntu1104-mcsched.py config.py
			else
				ln -sf config/config_8ubuntu1104-mcsched$postfix.py config.py
			fi

			# additional option
			opt=""
			if [ "$(echo $interactive_workloads | grep $workload)" != "" ]; then	# simple membership test
				opt="-t"	# trace option
			fi
			cmd="./skbench.py $opt -i -p $nr_iter -w $workload_path start-stop"
			echo $cmd
			$cmd | tee $resdir/$workload_name.result
			mv /tmp/total.schedstat $resdir/$workload_name.schedstat
			mv /tmp/pidstat.log $resdir/$workload_name.pidstat

			mkdir -p $resdir/$workload_name.threadinfo
                        rm -rf $resdir/$workload_name.threadinfo/*
			mv /tmp/g[0-9]*.[0-9]* $resdir/$workload_name.threadinfo
			if [ -e /tmp/kvm.perf.data ]; then
				perf kvm --guest --guestkallsyms=/tmp/guest.kallsyms --guestmodules=/tmp/guest.modules report -i /tmp/kvm.perf.data > $resdir/$workload_name.guest.perf
				perf kvm --host --guestkallsyms=/tmp/guest.kallsyms --guestmodules=/tmp/guest.modules report -i /tmp/kvm.perf.data > $resdir/$workload_name.host.perf
			fi
			if [ -e /tmp/lh.result ]; then
				mv /tmp/lh.result $resdir/$workload_name.lockholder
			fi
			if [ -e /tmp/kvm.stat ]; then
				mv /tmp/kvm.stat $resdir/$workload_name.stat
			fi
			if [ -e /tmp/kvm.prof ]; then
				mv /tmp/kvm.prof $resdir/$workload_name.prof
			fi
			if [ -e /tmp/kvm.debug ]; then
				mv /tmp/kvm.debug $resdir/$workload_name.debug
			fi

			echo "$workload_name is done! take a rest for 5 sec"
			sleep 5
		else 
			echo "Error: workload file ($workload_path) is not found!"
		fi
	done
done
