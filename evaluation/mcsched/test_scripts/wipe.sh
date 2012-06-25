#!/bin/sh
echo -n "cleaning housekeeping tasks & old result..."
i=0
while [ $i -lt 3 ]; do
        iter_pids=`ps aux | grep iterate | grep -v grep | awk '{print $2}'`
        for p in $iter_pids; do
                kill -9 $iter_pids > /dev/null 2>&1
        done
        killall -9 nc > /dev/null 2>&1
        killall -9 wait_signal_64 > /dev/null 2>&1
        killall -9 send_signal_64 > /dev/null 2>&1
        killall -9 pidstat > /dev/null 2>&1
        killall -9 perf > /dev/null 2>&1
        killall -9 stapio > /dev/null 2>&1
        i=$(( $i + 1 ))
        sleep 1
done

rm -f /tmp/g[0-9]*
rm -f /tmp/kvm.*
rm -f /tmp/lh.result
rm -f /tmp/total.schedstat
rm -f /tmp/result*
rm -f /tmp/pidstat.log

echo "Done"
