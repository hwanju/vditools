#!/bin/bash

#logging sharing amounts
temp=$(cat $1/ksm.sharing_entitlements | awk '{print $1}')
i=0
vm_pids=""
for pid in $temp
do
	let i=i+1
	if [ $i -eq 1 ]
	then
		continue
	fi
	vm_pids="$vm_pids $pid"
done
echo $vm_pids >> $3/entitlements_$4

while [ true ]
do
	cat $1/$2 >> $3/sharings_$4
	temp=$(cat $1/ksm.sharing_entitlements | awk '{print $2}')
	i=0
	entitlements=""
	for ent in $temp
	do
		let i=i+1
		if [ $i -eq 1 ]
		then	
			continue
		fi
		entitlements="$entitlements $ent"
	done
	echo $entitlements >> $3/entitlements_$4

	sleep 1
done
