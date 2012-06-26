#!/bin/sh

if [ $# -ne 1 ]; then
	echo "Usage: $0 <mode (orig, perf, lhp, lhpipi)>"
        exit
fi
mode=$1

#prolog_list="baseline_prolog purebal_prolog purebal_mig_prolog fairbal_0pct_prolog fairbal_100pct_prolog fairbal_150pct_prolog fairbal_200pct_prolog fairbal_250pct_prolog fairbal_300pct_prolog"
prolog_list="baseline_prolog purebal_prolog purebal_mig_prolog fairbal_0pct_prolog fairbal_100pct_prolog"
for p in $prolog_list; do
	ln -sf $p.$mode $p
done
