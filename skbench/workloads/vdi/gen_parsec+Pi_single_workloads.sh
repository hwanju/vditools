#!/bin/sh
parsec_workloads="blackscholes  bodytrack  canneal  dedup  facesim  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264"
modes="baseline purebal fairbal_pct100 fairbal_pct105 fairbal_pct110"
if [ $# -ne 2 ]; then
        echo "Usage: $0 <# of parsec workloads> <# of Pi_single>"
        exit
fi

nr_parsec=$1
nr_pi=$2

for parsec in $parsec_workloads; do
        for mode in $modes; do 
                ./gen_ubuntu_workload.plx ${nr_parsec}${parsec}+${nr_pi}Pi_single@$mode
        done
done
