#!/bin/sh
source ./workloads.inc
if [ $# -lt 2 ]; then
        echo "Usage: $0 <# of main workloads> <# of workloads to corun> <workload to corun>"
        echo "		e.g., $0 1 1 streamcluster"
        exit
fi

nr_main=$1
nr_corun=$2
workload=$3

for parsec in $parsec_workloads $npb_workloads $interactive_workloads $other_workloads; do
        for mode in $modes; do 
                ./gen_workload.plx ${nr_main}${parsec}+${nr_corun}${workload}@$mode
        done
done
