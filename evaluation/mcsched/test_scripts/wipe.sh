#!/bin/sh
killall -9 nc > /dev/null 2>&1
killall -9 wait_signal_64 > /dev/null 2>&1
killall -9 send_signal_64 > /dev/null 2>&1
killall -9 pidstat > /dev/null 2>&1
killall -9 perf > /dev/null 2>&1
killall -9 stapio > /dev/null 2>&1

rm -f /tmp/g[0-9]*
rm -f /tmp/kvm.*
rm -f /tmp/lh.result
rm -f /tmp/total.schedstat
rm -f /tmp/result*
rm -f /tmp/pidstat.log
