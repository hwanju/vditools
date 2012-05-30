#!/bin/sh
parsec_workloads="blackscholes  bodytrack  canneal  dedup  facesim  ferret  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264"
other_workloads="kbuild"
modes="baseline purebal purebal_mig fairbal_pct0 fairbal_pct100 fairbal_pct150"
if [ $# -lt 2 ]; then
        echo "Usage: $0 <# of main workloads> <# of workloads to corun> <workload to corun>"
        echo "		e.g., $0 1 1 streamcluster"
        exit
fi

nr_main=$1
nr_corun=$2
workload=$3

for parsec in $parsec_workloads $other_workloads; do
        for mode in $modes; do 
                ./gen_ubuntu_workload.plx ${nr_main}${parsec}+${nr_corun}${workload}@$mode
        done
done
