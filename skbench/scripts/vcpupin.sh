#!/bin/bash

virsh vcpupin $1 $2 # $1: guest id or name, $2: pcpu number (1,2,3,4,...)
