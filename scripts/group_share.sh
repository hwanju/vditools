#!/bin/sh
systemtap/group_share.stp > /dev/shm/gshare.dat
mv /dev/shm/gshare.dat .
gnuplot group_share.plt
