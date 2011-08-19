#!/bin/bash
# parameter: 1-array of dom name of a group
#			 2-ksm root path
#			 3-group name

prev_pages_sharing=0
min_pages_needed=256
actual_mem=()
dom_names=()	
mb_to_kb=1024
group_path=""

# 초기 메모리 설정은 prolog에서 미리했다고 가정
i=0
temp=0
vm_name_arr=""
for name in $@
do
	if [ $name == "/" ]
	then 
		break
	fi
	dom_names[i]=$name
	vm_name_arr="$vm_name_arr $name"
	actual_mem[i]=$(virsh dominfo $name | grep Used | awk '{print $3}')
	let temp=$temp+$min_pages_needed
	let i=$i+1
done
min_pages_needed=$temp
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
	pages_sharing=$(cat $group_path/ksm.pages_sharing)
	if [ $pages_sharing -gt $prev_pages_sharing ]
	then
		#increase memory
		let diff=$pages_sharing-$prev_pages_sharing
		if [ $diff -ge $min_pages_needed ]
		then
			let unit=$diff/$min_pages_needed
			let temp=$unit*$mb_to_kb
			i=0
			for mem in ${actual_mem[@]}
			do
				let target_mem=$mem+$temp	#KB
				virsh setmem ${dom_names[i]} $target_mem > /dev/null
				actual_mem[i]=$target_mem
				let i=$i+1
			done

			let actual_pages=$unit*$min_pages_needed
			let prev_pages_sharing=$prev_pages_sharing+$actual_pages
		fi
	elif [ $pages_sharing -lt $prev_pages_sharing ]
	then
		#decrease memory
		let diff=$prev_pages_sharing-$pages_sharing
		if [ $diff -ge $min_pages_needed ]
		then
			let unit=$diff/$min_pages_needed
			let temp=$unit*$mb_to_kb

			i=0
			for mem in ${actual_mem[@]}
			do
				let target_mem=$mem-$temp	#KB
				virsh setmem ${dom_names[i]} $target_mem > /dev/null
				actual_mem[i]=$target_mem
				let i=$i+1
			done

			let actual_pages=$unit*$min_pages_needed
			let prev_pages_sharing=$prev_pages_sharing-$actual_pages
		fi
	fi

	mem_arr=""
	for mem in ${actual_mem[@]}
	do
		mem_arr="$mem_arr $mem"
	done
	echo $mem_arr

	sleep 1
done


