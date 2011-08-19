#!/bin/bash

#logging disk stats

while [ true ]
do
	stats_g1=$(grep -E 'sda1|sda2' /proc/diskstats)
	stats_g2=$(grep -E 'sdb' /proc/diskstats)
	
	echo $stats_g1 >> $1/diskstat_g1
	echo $stats_g2 >> $1/diskstat_g2

	sleep 5
done
