#!/bin/sh
### FIXME: NOT general!
if [ $# -eq 0 ]; then
        echo "Usage: $0 <1=on|0=off> [cpu cgroup root dir(=/root/work/cpuctl)]"
        exit
fi
on=$1
cpudir=/root/work/cpuctl
if [ $# -ge 2 ]; then
        cpudir=$2
fi
if [ ! -e $cpudir ]; then
        echo "Error: $cpudir doesn't exist"
        exit
fi

if [ $on -eq 1 ]; then
        vcpu_mode=2
        task_mode=1
elif [ $on -eq 0 ]; then
        vcpu_mode=0
        task_mode=0
else
        echo "1=on, 0=off"
fi

echo $vcpu_mode > $cpudir/vm/cpu.balsched
for i in `seq 1 8`; do
        echo $task_mode > $cpudir/cpu$i/cpu.balsched
done
