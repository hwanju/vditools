#!/bin/bash 

while [ true ]
do
	cat /proc/diskstats | grep vda5 >> /tmp/swaps
	sleep 1
done
