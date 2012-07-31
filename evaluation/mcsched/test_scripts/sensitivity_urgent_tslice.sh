#!/bin/sh
# for sanity check
#workloads="dedup"
#nr_vms=3
#allowance="1000000000"
#tslice="100000 500000 1000000 2000000"

workloads="vips"
nr_vms="3"
allowance="18000000"
tslice="100000 500000 1000000 3000000"

for w in $workloads; do
	for n in $nr_vms; do
		for a in $allowance; do 
			for t in $tslice; do
				params=1:$t:$a:1:500000:0 arg2=perfall nr_iter=10 ./test_scripts/mcsched.sh $n$w fairbal_pct100
			done
		done
	done
done
