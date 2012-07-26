#!/bin/sh
# for sanity check

workloads="vips"
nr_corun="2"
corun_workloads="facesim"
allowance="0 6000000 12000000 18000000 24000000"
tslice="500000"

for w in $workloads; do
	for n in $nr_corun; do
		for cw in $corun_workloads; do
			for a in $allowance; do 
				params=1:500000:$a:1:500000:0 arg2=perf ./test_scripts/mcsched.sh 1$w+${n}${cw} fairbal_pct100
			done
		done
	done
done

#params=0:0:0:0:0:0 arg2=perf ./test_scripts/mcsched.sh 1vips+2facesim fairbal_pct100
#params=0:0:0:0:0:0 arg2=perf ./test_scripts/mcsched.sh 1vips+2freqmine fairbal_pct100
#params=0:0:0:0:0:0 arg2=perf ./test_scripts/mcsched.sh 1vips+3freqmine fairbal_pct100
