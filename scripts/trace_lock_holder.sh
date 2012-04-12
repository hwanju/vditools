#!/bin/sh

stp_cmd=systemtap/trace_lock_holder.stp
lh_param_path=/sys/module/kvm/parameters/trace_guest_lock_holder

if [ ! -e $lh_param_path ]; then
        echo "$lh_param_path doesn't exist (no kvm support)"
        exit
fi

trace_mode=1
if [ $# -eq 1 ]; then
        trace_mode=$1
fi

if [ ! -e $stp_cmd ]; then
        echo "$stp_cmd doesn't exist"
        echo "Usage: $0 [systemtap script path]" 
        exit
fi

echo $trace_mode > $lh_param_path
$stp_cmd > lh.result
echo 0 > $lh_param_path
