#!/bin/sh
parsec_workloads="blackscholes  bodytrack  canneal  dedup  facesim  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264"
modes="baseline purebal fairbal_pct0 fairbal_pct100 fairbal_pct105 fairbal_pct110"
pi_size_map=( NA 206M 316M 536M 1.25G 2.42G 4.75G 11.2G )
if [ $# -lt 2 ]; then
        echo "Usage: $0 <# of parsec workloads> <# of Pi_single> [Pi size]"
        exit
fi

nr_parsec=$1
nr_pi=$2
pi_size=
if [ $# -ge 3 ]; then
        pi_size=${pi_size_map[$3]}
        if [ "$pi_size" == "" -o "$pi_size" == "NA" ]; then
                echo "Error: $3 is an invalid mode for Pi size"
                exit
        fi
        pi_size=-$pi_size
fi

for parsec in $parsec_workloads; do
        for mode in $modes; do 
                ./gen_ubuntu_workload.plx ${nr_parsec}${parsec}+${nr_pi}Pi_single$pi_size@$mode
        done
done
