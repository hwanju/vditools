#!/bin/sh
parsec_workloads="blackscholes  bodytrack  canneal  dedup  facesim  ferret  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264"
other_workloads="kbuild"
modes="baseline purebal purebal_mig fairbal_pct0 fairbal_pct100 fairbal_pct150"
if [ $# -lt 1 ]; then
        echo "Usage: $0 <# of workloads>"
        exit
fi
nr_workloads=$1
postfix=
if [ $# -ge 2 ]; then
        postfix=$2
fi

for parsec in $parsec_workloads $other_workloads; do
        for mode in $modes; do 
                ./gen_ubuntu_workload.plx ${nr_workloads}${parsec}${postfix}@$mode $postfix
        done
done
