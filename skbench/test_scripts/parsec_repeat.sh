#!/bin/sh

if [ $# -ne 3 ]; then
        echo "Usage: $0 <workload file w/o dir & ext> <mode> <# of run>"
        exit
fi
workload=$1
mode=$2
n=$3
for i in `seq $n`; do
        name=${workload}_${mode}
        if [ -e workloads/parsec/$name.skw ]; then
                ./skbench.py -w workloads/parsec/$name.skw start-stop | tee $name-$i.log
                mv $mode.schedstat $name-$i.schedstat
        else 
                echo "Error: workload file is not found!"
        fi
done
