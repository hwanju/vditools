#!/bin/bash
# parameter: 1-array of dom name of a group
#			 2-group name

prev_pages_sharing=0
mb_to_pages=256
actual_mem=()
dom_names=()	
mb_to_kb=1024
group_path=""

# 초기 메모리 설정은 prolog에서 미리했다고 가정
i=0
temp=0
init_total_mem=0
for name in $@
do
	if [ $name == "/" ]
	then 
		break
	fi
	dom_names[i]=$name
	actual_mem[i]=$(virsh dominfo $name | grep Used | awk '{print $3}')
	let init_total_mem=$init_total_mem+${actual_mem[i]}
	let temp=$temp+$mb_to_pages
	let i=i+1
done
min_pages_needed=$temp

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
init_scan_rate=$(cat $group_path/ksm.pages_to_scan)

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
			total_mem=0
			for mem in ${actual_mem[@]}
			do
				let target_mem=$mem+$temp	#KB
				virsh setmem ${dom_names[i]} $target_mem
				actual_mem[i]=$target_mem
				let total_mem=$total_mem+${actual_mem[i]}
				let i=$i+1
			done
			let scan_rate=$init_scan_rate*$total_mem/$init_total_mem
			echo $scan_rate > $group_path/ksm.pages_to_scan
###debug
			echo "prev total mem: $init_total_mem"
			echo "total mem: $total_mem"
			echo "prev scan rate: $init_scan_rate"
			echo "scan rate: $scan_rate"
###	
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
			total_mem=0
			for mem in ${actual_mem[@]}
			do
				let target_mem=$mem-$temp	#KB
				virsh setmem ${dom_names[i]} $target_mem
				actual_mem[i]=$target_mem
				let total_mem=$total_mem+${actual_mem[i]}
				let i=$i+1
			done
			let scan_rate=$init_scan_rate*$total_mem/$init_total_mem
			echo $scan_rate > $group_path/ksm.pages_to_scan
###debug
			echo "prev total mem: $init_total_mem"
			echo "total mem: $total_mem"
			echo "prev scan rate: $init_scan_rate"
			echo "scan rate: $scan_rate"
###
			let actual_pages=$unit*$min_pages_needed
			let prev_pages_sharing=$prev_pages_sharing-$actual_pages
		fi
	fi

	sleep 1
done


