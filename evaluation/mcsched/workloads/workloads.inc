#!/bin/sh
parsec_workloads="blackscholes  bodytrack  canneal  dedup  facesim  ferret  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264"
ubuntu_workloads="impress_launch firefox_launch chrome_launch gimp_launch"
windows_workloads="powerpoint_launch winchrome_launch iexplorer_launch acrobat_launch"
interactive_workloads="$ubuntu_workloads $windows_workloads"
other_workloads="kbuild"
modes="baseline purebal purebal_mig fairbal_pct0 fairbal_pct100"
