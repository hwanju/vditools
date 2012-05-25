#!/bin/sh
parsec_workloads="blackscholes  bodytrack  canneal  dedup  facesim  ferret  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264"
modes="baseline purebal purebal_mig fairbal_pct0 fairbal_pct100 fairbal_pct110"
if [ $# -lt 2 ]; then
        echo "Usage: $0 <# of parsec workloads> <# of workloads to corun> <workload to corun>"
        echo "		e.g., $0 1 1 streamcluster"
        exit
fi

nr_parsec=$1
nr_workload=$2
workload=$3

for parsec in $parsec_workloads; do
        for mode in $modes; do 
                ./gen_ubuntu_workload.plx ${nr_parsec}${parsec}+${nr_workload}${workload}@$mode
        done
done
