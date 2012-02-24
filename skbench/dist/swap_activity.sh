#!/bin/bash 

while [ true ]
do
	for name in $1
	do
		cat /proc/diskstats | grep $name >> /tmp/swaps_$name
	done
	sleep 1
done
