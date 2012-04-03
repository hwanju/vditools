#!/bin/sh
ext=log
if [ $# -eq 1 ]; then
        ext=$1
fi
fn=shares.$ext

systemtap/trace_shares.stp > /dev/shm/$fn
mv /dev/shm/$fn .
./mkplt_shares.plx $fn 0-7
