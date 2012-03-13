#!/bin/bash
PATH=~/skbench/dist:$PATH
NUM_OF_GUESTS=$1
ITERATIONS=$2
let GUEST_NUM=$3+1
GUEST_IP=$4
let WAIT_QUERY_PORT=40000+$GUEST_NUM

i=0
echo  0 > /tmp/iterate$GUEST_NUM
while [ 1 ]
do
	# wait query signal from a corresponding guest
	wait_signal_64 1 $WAIT_QUERY_PORT

	# send repeat message to the guest
	if [ $i -lt $ITERATIONS ]
	then
		echo repeat | nc -q 0 $GUEST_IP 50000
	else
		break
	fi
	let i=$i+1
done
echo 1 > /tmp/iterate$GUEST_NUM

while [ 1 ]
do
	i=1
	flag=0
	while [ $i -le $NUM_OF_GUESTS ]
	do
		iterate=$(cat /tmp/iterate$i)
		if [ $iterate -eq 0 ]
		then
			flag=1
			break
		fi
		let i=$i+1
	done

	if [ $flag -eq 1 ]
	then
		echo repeat | nc -q 0 $GUEST_IP 50000
	else
		echo stop | nc -q 0 $GUEST_IP 50000
		break
	fi

	wait_signal_64 1 $WAIT_QUERY_PORT
	
done
