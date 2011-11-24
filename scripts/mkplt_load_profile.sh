#!/bin/sh
if [ $# -ne 2 ]; then
    echo "Usage: $0 <vm_id> <profile_id>";
    exit;
fi
vm_id=$1
profile_id=$2

eps_fn="load-vm$vm_id-id$profile_id.eps"
eps2_fn="info-vm$vm_id-id$profile_id.eps"
plt_fn="load-vm$vm_id-id$profile_id.plt"
plt_str_fn="plt_str.tmp"
plt_str2_fn="plt_str2.tmp"

max_vcpu=16
size_x=1.4

# getting # of vcpus 
nr_vcpus=0
for vcpu_id in `seq 0 $(( $max_vcpu - 1 ))`; do
        dat_fn="load-vm$vm_id-vcpu$vcpu_id-id$profile_id.dat"
        if [ ! -e $dat_fn ]; then
                continue
        fi
        nr_vcpus=$(( $nr_vcpus + 1 ))
done

# height calculation for multiplot
h=0.5
total_h=`bc << EOF
$h * $nr_vcpus
EOF
`
origin=$total_h

col_id=1
extra_info_cols=2
rundelay_idx_from_end=1
flags_idx_from_end=0
echo > $plt_str_fn
echo > $plt_str2_fn
for vcpu_id in `seq 0 $(( $max_vcpu - 1 ))`; do
        dat_fn="load-vm$vm_id-vcpu$vcpu_id-id$profile_id.dat"
        if [ ! -e $dat_fn ]; then
                continue
        fi

        xmax=`wc -l $dat_fn | awk '{print $1}'` # (# of epoch + 2)
        xmax=$(( $xmax + $xmax * 2 / 5 ))

        nr_cols=`tail -1 $dat_fn | awk '{print NF}'`
        label=`head -2 $dat_fn | tail -1`

        # add new line
        plot_str="plot '$dat_fn'"

        for c in `seq 4 $(( $nr_cols - $extra_info_cols ))`; do 
                gtid=`echo $label | awk -v c=$c '{print $c}'` 

                # the following codes are no longer needed
                #if [ -z ${gtid_to_id[0x$gtid]} ]; then
                #    gtid_to_id[0x$gtid]=$col_id
                #    col_id=$(( $col_id + 1 ))
                #fi
                if [ $c != 4 ]; then
                        plot_str="$plot_str, ''"
                fi
                color_opt="ls 1 lt rgb \"#$gtid\""
                plot_str="$plot_str u (\$$c / \$2):xtic(every10th(0)) t '$gtid' $color_opt"
        done
        plot_str="$plot_str, '' u 1:$(( $nr_cols - $rundelay_idx_from_end )) t 'Wait time ratio' lt 1 lw 3 axis x1y2 w lp"
        plot_str="$plot_str, '' u 1:(\$$(( $nr_cols - $flags_idx_from_end )) / 5 ) t 'VCPU flags' lc 2 lt 1 lw 6 w lines"
        plot_str2="plot '$dat_fn' u 1:$(( $nr_cols - $flags_idx_from_end )) t 'VCPU flags' lc 3 lw 5 w lines"
        origin=`bc << EOF
$origin - $h
EOF
`
        # plot1
        echo "set title 'VM$vm_id-VCPU$vcpu_id'" >> $plt_str_fn
        echo "set origin 0,$origin" >> $plt_str_fn
        echo "set size $size_x,$h" >> $plt_str_fn
        echo $plot_str >> $plt_str_fn

        # plot2
        echo "set title 'VM$vm_id-VCPU$vcpu_id'" >> $plt_str2_fn
        echo "set origin 0,$origin" >> $plt_str2_fn
        echo "set size $size_x,$h" >> $plt_str2_fn
        echo $plot_str2 >> $plt_str2_fn
done

plot_str=`cat $plt_str_fn`
plot_str2=`cat $plt_str2_fn`

cat > $plt_fn << EOF
set terminal postscript eps enhanced color
set terminal post "Times-Roman" 10
set output '$eps_fn'
set size $size_x,$total_h
set multiplot layout $nr_vcpus,1
set key vertical right
set xlabel "Load epoch number"
set ylabel "CPU usage (%)" 
set y2label "Wait time ratio"
set xrange [-0.5:$xmax]
set yrange [0:1]
set y2range [0:1]
set xtics 0,10
set xtics nomirror
#set ytics 0,20
set grid y
set style data histograms
set style histogram rowstacked
set style fill solid border 0.2
set boxwidth 1
every10th(col) = (int(column(col))%10 ==0)?stringcolumn(1):""
$plot_str
unset multiplot

set output '$eps2_fn'
set multiplot layout $nr_vcpus,1
set ylabel "VCPU flags" 
set yrange [0:5]
set xtics 0,10
$plot_str2
unset multiplot

EOF
gnuplot $plt_fn

rm -f $plt_str_fn $plt_str2_fn
