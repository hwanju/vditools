#!/bin/bash
PATH=~/skbench/dist:$PATH
NUM_OF_GUESTS=$1
ITERATIONS=$2
let GUEST_NUM=$3+1
GUEST_IP=$4
let WAIT_QUERY_PORT=40000+$GUEST_NUM

i=1
echo  0 > /tmp/iterate$GUEST_NUM
while [ 1 ]
do
	# wait query signal from a corresponding guest
	wait_signal_64 1 $WAIT_QUERY_PORT > /dev/null

	# send repeat message to the guest
	if [ $i -lt $ITERATIONS ]
	then
		ssh $GUEST_IP "echo repeat > /tmp/query"
		echo "VM$GUEST_NUM workload iterations: $i/$ITERATIONS"
		let i=$i+1
	else
		echo "VM$GUEST_NUM workload iterations: $i/$ITERATIONS"
		let i=$i+1
		break
	fi
done
echo 1 > /tmp/iterate$GUEST_NUM

while [ 1 ]
do
	j=1
	flag=0
	while [ $j -le $NUM_OF_GUESTS ]
	do
		iterate=$(cat /tmp/iterate$j)
		if [ $iterate -eq 0 ]
		then
			flag=1
			break
		fi
		let j=$j+1
	done

	if [ $flag -eq 1 ]
	then
		ssh $GUEST_IP "echo repeat > /tmp/query"
	else
		ssh $GUEST_IP "echo stop > /tmp/query"
		break
	fi

	wait_signal_64 1 $WAIT_QUERY_PORT > /dev/null
	echo "VM$GUEST_NUM workload iterations: $i/$ITERATIONS"
	let i=$i+1
done

exit 0
