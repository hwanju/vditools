#!/bin/sh

lh_param_path=/sys/module/kvm/parameters/trace_guest_lock_holder

if [ ! -e $lh_param_path ]; then
        echo "$lh_param_path doesn't exist (no kvm support)"
        exit
fi

stp_cmd=systemtap/trace_lock_holder.stp
if [ $# -ge 1 ]; then
        stp_cmd=$1
fi

if [ ! -e $stp_cmd ]; then
        echo "$stp_cmd doesn't exist"
        echo "Usage: $0 [systemtap script path]" 
        exit
fi

echo 1 > $lh_param_path
$stp_cmd > lh.result
echo 0 > $lh_param_path
