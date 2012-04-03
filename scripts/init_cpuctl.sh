#!/bin/sh

cpuctl=/cpuctl
cpuset=/cpuset
mkdir -p $cpuctl
mkdir -p $cpuset
mount -t cgroup -o cpu none $cpuctl
mount -t cgroup -o cpuset none $cpuset
for i in `seq 1 10`; do
        mkdir -p $cpuctl/g$i
        echo 65536 > $cpuctl/g$i/cpu.shares

        mkdir -p $cpuset/g$i
        echo 0,2,4,6 > $cpuset/g$i/cpuset.cpus
        echo 0 > $cpuset/g$i/cpuset.mems
done
