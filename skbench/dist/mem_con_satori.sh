#!/bin/bash
# parameter: 1-array of dom name of a group, 
#			 2-group name

min_pages_needed=256
mb_to_kb=1024
actual_mem=()
prev_entitlements=()
entitlements=()
dom_pids=()
dom_names=()
prev_total_mem=0
group_path=""

#초기메모리 설정은 prolog에서 미리했다고 가정
i=0
for name in $@
do
	if [ $name == "/" ]
	then
		break
	fi
	dom_names[i]=$name
	pid=($(ps -eLf | grep $name | awk '{print $2}'))
	dom_pids[i]=${pid[0]}

	actual_mem[i]=$(virsh dominfo $name | grep Used | awk '{print $3}')
	let prev_total_mem=$prev_total_mem+${actual_mem[i]}
	prev_entitlements[i]=0
	let i=i+1
done
i=0
for param in $@
do
	if [ $param == "/" ]
	then
		i=1
		continue
	fi

	if [ $i -eq 1 ]
	then
		group_path=$param
	fi	
done
prev_scan_rate=$(cat $group_path/ksm.pages_to_scan)
####debug
	echo "prev total mem=$prev_total_mem KB"
	echo "prev scan rate=$prev_scan_rate"
#######

while [ true ]
do
	i=0
	flag=0
	for pid in ${dom_pids[@]}
	do
		entitlements[i]=$(cat $group_path/ksm.sharing_entitlements | grep $pid | awk '{print $2}')
		if [ ${entitlements[i]} -gt ${prev_entitlements[i]} ]
		then
			#increase memory
			let diff=${entitlements[i]}-${prev_entitlements[i]}
			if [ $diff -ge $min_pages_needed ]
			then
				let unit=$diff/$min_pages_needed
				let temp=$unit*$mb_to_kb
				let target_mem=${actual_mem[i]}+$temp	#KB
			
				virsh setmem ${dom_names[i]} $target_mem

				actual_mem[i]=$target_mem

				let actual_pages=$unit*$min_pages_needed
				let prev_entitlements[i]=${prev_entitlements[i]}+$actual_pages
			fi
			flag=1
		elif [ ${entitlements[i]} -lt ${prev_entitlements[i]} ]
		then
			#decrease memory
			let diff=${prev_entitlements[i]}-${entitlements[i]}
			if [ $diff -ge $min_pages_needed ]
			then
				let unit=$diff/$min_pages_needed
				let	temp=$unit*$mb_to_kb
				let target_mem=${actual_mem[i]}-$temp	#KB
			
				virsh setmem ${dom_names[i]} $target_mem
		
				actual_mem[i]=$target_mem

				let actual_pages=$unit*$min_pages_needed
				let prev_entitlements[i]=${prev_entitlements[i]}-$actual_pages
			fi
			flag=1
		fi
		let i=$i+1
	done

	if [ $flag -eq 1]
	then
		total_mem=0
		for mem in ${actual_mem[@]}
		do
			let total_mem=$total_mem+$mem
		done
		let scan_rate=$prev_scan_rate*$total_mem/$prev_total_mem
		echo $scan_rate > $group_name/ksm.pages_to_scan
		prev_total_mem=$total_mem
		prev_scan_rate=$scan_rate
	fi
	
	sleep 1

done


