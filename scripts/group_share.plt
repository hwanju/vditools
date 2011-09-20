set terminal postscript eps enhanced color
set terminal post "Times-Roman" 15
set output 'gshare.eps'
set ylab "VCPU Share ratio"
set xlab "Time (msec)"
set yrange [0:1]
plot 'gshare.dat' u ($1 / 1000):($5 / $6) t 'Share ratio (vcpu share / total share)'

set output 'schedcpu.eps'
set auto y
set ylab "PCPU ID"
set xlab "Time (msec)"
plot 'gshare.dat' u ($1 / 1000):4 t 'VCPU'
