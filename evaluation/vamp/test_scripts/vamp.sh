#!/bin/bash

project=vamp

# KSM off
echo 0 > /sys/kernel/mm/ksm/run
echo 2 > /sys/kernel/mm/ksm/run

if [ "$parsec_workloads" == "" -a "$interactive_workloads" == "" -a "$npb_workloads" == ""  -a "$ubuntu_workloads" == "" ]; then
	source workloads/$project/workloads.inc
fi
if [ "$nr_iter" == "" ]; then
	nr_iter=3
fi
if [ "$mixed" == "" ]; then
	mixed="0"
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
	resdir=results/$project/_$workload_format
elif [ $(echo $workload_format | grep npb) ]; then
	workload_list=$npb_workloads
	resdir=results/$project/_$workload_format
elif [ $(echo $workload_format | grep interactive) ]; then
	workload_list=$interactive_workloads
	resdir=results/$project/_$workload_format
elif [ $(echo $workload_format | grep ubuntu) ]; then
	workload_list=$ubuntu_workloads
	resdir=results/$project/_$workload_format
else
	workload_list=$(echo $workload_format | sed 's/+.*//g')
	workload_list=$(echo $workload_list | sed 's/^[0-9]*//g')
	resdir=results/$project
fi

if [ "$arg2" != "" -a "$res_postfix" == "" ]; then
	res_postfix=-$arg2
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
		workload_name=$(echo $workload_name | sed "s/npb/$workload/g")
		workload_name=$(echo $workload_name | sed "s/interactive/$workload/g")
		workload_name=$(echo $workload_name | sed "s/ubuntu/$workload/g")
		workload_name=$workload_name@$mode
		workload_path=workloads/$project/$workload_name

		if [ "$params" != "" ]; then
			workload_name=$workload_name-$params
		fi
		workload_name=$workload_name$res_postfix

		if [ -e $workload_path ]; then
			./test_scripts/wipe.sh

                        info_opt=""
			if [ "$params" != "" ]; then
				./test_scripts/init_$project.sh 1 $params
                                info_opt="-o -$params$res_postfix"
			elif [ $(echo $mode | grep 'fairbal') ]; then
				./test_scripts/init_$project.sh 1
			else
				./test_scripts/init_$project.sh 0
			fi

			# change config.py
			rm -f config.pyc
			if [ "$mixed" == "1" ]; then
				ln -sf config/config_1ubuntu1104+7ubuntu1104up-$project$cfg_postfix.py config.py
			elif [ "$mixed" == "2" ]; then
				ln -sf config/config_2ubuntu1104+6ubuntu1104up-$project$cfg_postfix.py config.py
			elif [ "$up" == "1" ]; then
				ln -sf config/config_8ubuntu1104up-$project$cfg_postfix.py config.py
			elif [ $(cat $workload_path | grep 'windows/interactive') ]; then
				ln -sf config/config_1win7_64bit+7ubuntu1104-$project$cfg_postfix.py config.py
			else
				ln -sf config/config_8ubuntu1104-$project$cfg_postfix.py config.py
			fi

			# additional option
			trace_opt=""
			if [ "$(echo $interactive_workloads | grep $workload)" != "" ]; then	# simple membership test
				trace_opt="-t"	# trace option
                        elif [ "$(echo $workload | grep :)" != "" ]; then
				trace_opt="-T"	# trace option
			fi
			iter_opt=""
			if [ $nr_iter != "0" ]; then
				iter_opt="-i $nr_iter"
			else
				iter_opt="-q no_iter"
			fi
			private_opt=""
			if [ "$arg1" != "" ]; then
				private_opt="-p $arg1"
			fi
			if [ "$arg2" != "" -a "$iter_opt" != "-q no_iter" ]; then
				private_opt="$private_opt -q $arg2"
			fi
			cmd="./skbench.py $trace_opt $iter_opt $info_opt $private_opt -w $workload_path start-stop"
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
			if [ -e /tmp/kvm.stat ]; then
				mv /tmp/kvm.stat $resdir/$workload_name.stat
			fi
			if [ -e /tmp/kvm.debug ]; then
				mv /tmp/kvm.debug $resdir/$workload_name.debug
			fi
			if [ "$trace_opt" != "" ]; then		# FIXME: manual
				scp canh1:/root/vamp/latency/$workload_name.latency $resdir/
			fi

			echo "$workload_name is done! take a rest for 5 sec"
			sleep 5
		else 
			echo "Error: workload file ($workload_path) is not found!"
		fi
	done
done
