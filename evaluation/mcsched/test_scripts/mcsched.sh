#!/bin/bash

if [ "$parsec_workloads" == "" -a "$interactive_workloads" == "" ]; then
	source workloads/mcsched/workloads.inc
	#parsec_workloads="blackscholes bodytrack canneal dedup facesim ferret fluidanimate freqmine raytrace streamcluster swaptions vips x264"
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
	workload_list=dummy
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

			# additional option
			opt=""
			if [ "$(echo $interactive_workloads | grep $workload)" != "" ]; then	# simple membership test
				opt="-t"	# trace option
			fi
			cmd="./skbench.py $opt -w $workload_path start-stop | tee $resdir/$workload_name.result"
			echo $cmd
			$cmd
			mv /tmp/total.schedstat $resdir/$workload_name.schedstat
			mv /tmp/pidstat.log $resdir/$workload_name.pidstat
			mkdir -p $resdir/$workload_name.threadinfo
			mv /tmp/g[0-9]*.[0-9]* $resdir/$workload_name.threadinfo
			if [ -e /tmp/kvm.perf.data ]; then
				perf kvm --guest --guestkallsyms=/tmp/guest.kallsyms --guestmodules=/tmp/guest.modules report -i /tmp/kvm.perf.data > $resdir/$workload_name.guest.perf
				perf kvm --host --guestkallsyms=/tmp/guest.kallsyms --guestmodules=/tmp/guest.modules report -i /tmp/kvm.perf.data > $resdir/$workload_name.host.perf
			fi
			if [ -e /tmp/lh.result ]; then
				mv /tmp/lh.result $resdir/$workload_name.lockholder
			fi
			if [ -e /tmp/kvm.exits ]; then
				mv /tmp/kvm.exits $resdir/$workload_name.exits
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
