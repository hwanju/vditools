#!/bin/sh

avail_mode_list="ipigrpfirst amvp10ipigrpfirst amvp15ipigrpfirst baseline amvp10 amvp15"
bg_cpu_list="1 2 4"
#postfix=pin1vcpu
if [ "$CLIENT_ADDR" == "" ]; then
        CLIENT_ADDR=canh1
fi
latency_dir=/root/spice/latency
if [ $# -eq 0 ]; then
        echo "Usage: $0 <mode list: $avail_mode_list all>"
        exit
fi

if [ "$1" == "all" ]; then
        mode_list=$avail_mode_list
else
        mode_list=$*
fi

mkdir -p results/1pptlaunchNcpu+4streamline
        
for nr_bg_cpu in $bg_cpu_list; do
        for mode in $mode_list; do 
                workload_name=1pptlaunch${nr_bg_cpu}cpu${postfix}+4streamcluster@$mode
                workload_path=workloads/vdi/$workload_name
                latency_name=pptlaunch+${nr_bg_cpu}cpu-win7.latency
                if [ "$postfix" != "" ]; then
                        latency_name=pptlaunch+${nr_bg_cpu}cpu-win7-$postfix.latency
                fi

                if [ -e $workload_path ]; then
                        if [ "$mode" == "baseline" ]; then
                                ./test_scripts/control_vdikernel.sh 0
                        else 
                                ./test_scripts/control_vdikernel.sh 1
                        fi
                        ./test_scripts/reformat_win7img.sh
                        echo 0 > /proc/sys/kernel/kvm_ipi_first
                        echo 0 > /proc/sys/kernel/kvm_ipi_grp_first
                        echo 0 > /proc/sys/kernel/kvm_resched_no_preempt
                        echo 0 > /proc/sys/kernel/kvm_amvp
                        echo 0 > /proc/sys/kernel/kvm_amvp_sched
                        if [ "$postfix" != "" ]; then
                                echo 15 > /sys/module/kvm/parameters/bg_load_thresh_pct
                        fi

                        echo "./skbench.py -w $workload_path start-stop | tee results/1pptlaunchNcpu+4streamline/$workload_name.result"
                        ./skbench.py -w $workload_path start-stop | tee results/1pptlaunchNcpu+4streamline/$workload_name.result
                        ssh $CLIENT_ADDR cat $latency_dir/$latency_name.* \> $latency_dir/$workload_name.latency
                        ssh $CLIENT_ADDR rm $latency_dir/$latency_name.* 

                        if [ "$postfix" != "" ]; then
                                echo 60 > /sys/module/kvm/parameters/bg_load_thresh_pct
                        fi

                        echo "$workload_name is done! take a rest for 10 sec"
                        sleep 10
                else 
                        echo "Error: workload file ($workload_path) is not found!"
                fi
        done
done
