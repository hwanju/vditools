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
group_path=""

#초기메모리 설정은 prolog에서 미리했다고 가정
i=0
vm_name_arr=""
for name in $@
do
	if [ $name == "/" ]
	then
		break
	fi
	dom_names[i]=$name
	vm_name_arr="$vm_name_arr $name"
	pid=($(ps -eLf | grep $name | awk '{print $2}'))
	dom_pids[i]=${pid[0]}

	actual_mem[i]=$(virsh dominfo $name | grep Used | awk '{print $3}')
	prev_entitlements[i]=0
	let i=i+1
done
echo $vm_name_arr

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

while [ true ]
do
	i=0
	for pid in ${dom_pids[@]}
	do
		entitlements[i]=$(cat $group_path/ksm.sharing_entitlements | grep $pid | awk '{print $2}')
###
		echo "$pid's previous: ${prev_entitlements[i]}, current: ${entitlements[i]}" >> /tmp/satori_log
###
		if [ ${entitlements[i]} -gt ${prev_entitlements[i]} ]
		then
			#increase memory
			let diff=${entitlements[i]}-${prev_entitlements[i]}
			if [ $diff -ge $min_pages_needed ]
			then
				let unit=$diff/$min_pages_needed
				let temp=$unit*$mb_to_kb
				let target_mem=${actual_mem[i]}+$temp	#KB
			
				virsh setmem ${dom_names[i]} $target_mem > /dev/null

				actual_mem[i]=$target_mem

				let actual_pages=$unit*$min_pages_needed
				let prev_entitlements[i]=${prev_entitlements[i]}+$actual_pages
			fi
		elif [ ${entitlements[i]} -lt ${prev_entitlements[i]} ]
		then
			#decrease memory
			let diff=${prev_entitlements[i]}-${entitlements[i]}
			if [ $diff -ge $min_pages_needed ]
			then
				let unit=$diff/$min_pages_needed
				let	temp=$unit*$mb_to_kb
				let target_mem=${actual_mem[i]}-$temp	#KB
			
				virsh setmem ${dom_names[i]} $target_mem > /dev/null
		
				actual_mem[i]=$target_mem

				let actual_pages=$unit*$min_pages_needed
				let prev_entitlements[i]=${prev_entitlements[i]}-$actual_pages
			fi
		fi
		let i=$i+1
	done
##
	echo "" >> /tmp/satori_log
##
	mem_arr=""
	for mem in ${actual_mem[@]}
	do
		mem_arr="$mem_arr $mem"
	done
	echo $mem_arr

	sleep 1
done
