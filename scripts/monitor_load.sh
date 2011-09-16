#!/bin/sh
#trap './load_profile.py load_sample.dump' INT
systemtap/vdi_load.stp > load_sample.dump
./load_profile.py load_sample.dump
recent_output=`ls -t | head -1`
vm_id=`echo $recent_output | perl -e '$f = <>; print "$1\n" if $f =~ /vm(\d+)/;'`
max_prof_id=`echo $recent_output | perl -e '$f = <>; print "$1\n" if $f =~ /id(\d+)/;'`
for prof_id in `seq 1 $max_prof_id`; do
        ./mkplt_load_profile.sh $vm_id $prof_id
done
