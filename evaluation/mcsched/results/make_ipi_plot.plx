#!/usr/bin/perl -w

die "Usage: $0 <dir>\n" unless @ARGV == 1;
$dir = shift(@ARGV);
$dir =~ s/\/$//;
$plot_name = "$dir";
system("./get_ipi_stat.plx -p linux $dir/*.debug > $plot_name.dat");
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 30
set output '_1parsec-ipi.eps'
#set key invert reverse top Left width -1 outside
set key reverse top horizontal Left width -1 
set size 1.8,1
#set xlabel 'Workloads'
set ylabel '# of IPIs / second (log scale)' 
set xtics nomirror
set xtic rotate by -45
#set ytics 0,20
set grid y
set log y
set style data histograms
set yrange [1:100000]
set ytics (\"1\" 1, \"10\" 10, \"100\" 100, \"1000\" 1000, \"10000\" 10000)
set style histogram 
set style fill solid border 0.2
set boxwidth 1
plot '$plot_name.dat' u 2:xtic(1) t 'TLB shootdown IPI' fs solid 0.20 lt 1, '' u 3 t 'Reschedule IPI' fs solid 0.70 lt 1
";
close OFD;
system("gnuplot $plot_name.plt");
