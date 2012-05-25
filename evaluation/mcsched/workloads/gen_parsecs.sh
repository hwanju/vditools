#!/bin/sh
parsec_workloads="blackscholes  bodytrack  canneal  dedup  facesim  ferret  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264"
modes="baseline purebal purebal_mig fairbal_pct0 fairbal_pct100 fairbal_pct110"
if [ $# -lt 1 ]; then
        echo "Usage: $0 <# of parsec workloads>"
        exit
fi
nr_parsec=$1
postfix=
if [ $# -ge 2 ]; then
        postfix=$2
fi

for parsec in $parsec_workloads; do
        for mode in $modes; do 
                ./gen_ubuntu_workload.plx ${nr_parsec}${parsec}${postfix}@$mode $postfix
        done
done
