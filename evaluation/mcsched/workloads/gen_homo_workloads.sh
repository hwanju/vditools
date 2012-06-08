#!/bin/sh
source ./workloads.inc

if [ $# -lt 1 ]; then
        echo "Usage: $0 <# of workloads>"
        exit
fi
nr_workloads=$1
postfix=
if [ $# -ge 2 ]; then
        postfix=$2
fi

for parsec in $parsec_workloads $interactive_workloads $other_workloads; do
        for mode in $modes; do 
                ./gen_workload.plx ${nr_workloads}${parsec}${postfix}@$mode $postfix
        done
done
