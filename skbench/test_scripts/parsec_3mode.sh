#!/bin/sh

if [ $# -ne 1 ]; then
        echo "Usage: $0 <workload file w/o dir & ext>"
        exit
fi
workload=$1
for mode in cfs purebal fairbal; do
        name=${workload}_${mode}
        if [ -e workloads/parsec/$name.skw ]; then
                ./skbench.py -w workloads/parsec/$name.skw start-stop | tee $name.log
                mv $mode.schedstat $name.schedstat
        else 
                echo "Error: workload file is not found!"
        fi
done
