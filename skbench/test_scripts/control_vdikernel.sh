#!/bin/sh

if [ $# -ne 1 ]; then
        echo "Usage: $0 <0=off | 1=on>"
        exit
fi
if [ $1 -eq 0 ]; then
        echo "task track disabled"
        arg="load_monitor_enabled=0"
        arch_arg="track_cr3_load=0"
fi

rmmod kvm_intel
rmmod kvm
modprobe kvm $arg
modprobe kvm_intel $arch_arg
