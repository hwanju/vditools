#!/bin/sh
systemtap/vcpusched.stp > /dev/shm/vcpusched.log
mv /dev/shm/vcpusched.log .
#./vcpusched.plx < vcpusched.log
