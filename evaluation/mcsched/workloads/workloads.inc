#!/bin/sh
parsec_workloads="blackscholes  bodytrack  canneal  dedup  facesim  ferret  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264"
npb_workloads="bt cg ep ft is lu mg sp ua"
ubuntu_workloads="impress_launch firefox_launch chrome_launch gimp_launch"
windows_workloads="powerpoint_launch winchrome_launch iexplorer_launch acrobat_launch"
interactive_workloads="$ubuntu_workloads $windows_workloads"
io_workloads="memcached apache"
other_workloads="kbuild hackbench"
modes="baseline purebal purebal_mig fairbal_pct0 fairbal_pct100"
