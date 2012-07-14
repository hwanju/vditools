#!/usr/bin/perl -w

die "Usage: $0 <dir (e.g., sensitivity-urgent-tslice>\n" unless @ARGV;
$dir = shift(@ARGV);
$dir =~ s/\/$//g;

@tlbipi_cycles = `./get_cycles_tlbipi.plx $dir`;
@spinlock_cycles = `./get_cycles_spinlock.plx $dir`;
$i = 0;
$max_cycles = 0;
foreach $line (@tlbipi_cycles) {
	($conf, $cycle) = split(/\s+/, $line);
	$urgent_tslice = $1 if ($conf =~ /\d+:(\d+):\d+:\d+:\d+:\d+/);
	$urgent_tslice /= 1000;

	($conf, $cycle) = split(/\s+/, $line);
	$tlb{$urgent_tslice} = $cycle;
	$total_cycles = $cycle;

	($conf, $cycle) = split(/\s+/, $spinlock_cycles[$i++]);
	$spinlock{$urgent_tslice} = $cycle;
	$total_cycles += $cycle;

	$max_cycles = $total_cycles if $total_cycles > $max_cycles;

	$res = `./get_avg_time.plx $conf.result 10`;
	($avg, $sd) = split(/\s+/, $res);
	$avg_time{$urgent_tslice} = $avg;
	$sd_time{$urgent_tslice} = $sd;
}
$plot_name = $dir;
open OFD, ">$plot_name.dat";
print OFD "#Urgent_tslice\tTLB cycles\tSpinlock cycles\tAvg Time\tSd Time\n";
$i = 0;
$xtics = "set xtics (";
foreach $urgent_tslice (sort {$a <=> $b} keys %tlb) {
	$xtics .= ", " unless $i == 0;
	$xtics .= "'$urgent_tslice' $i";
	printf OFD "%d\t%.2lf\t%.2lf\t%d\t%.2lf\t%.2lf\n", 
		$urgent_tslice, 
		$tlb{$urgent_tslice}, $spinlock{$urgent_tslice}, 
		$i++, $avg_time{$urgent_tslice}, $sd_time{$urgent_tslice};
}
close OFD;
$xtics .= ")";
$max_cycles += 15;
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 25
set output '$plot_name.eps'
set key invert reverse left Left width -1
set xlabel 'Urgent time slice (usec)'
set ylabel 'Average execution time (sec)' 
set y2label 'CPU cycles (%)' 
set xrange [-1:$i]
set yrange [30:]
set y2range [0:$max_cycles]
#set xtics 0,10
set xtics nomirror
#set xtic rotate by -45
$xtics
#set ytics 0,20
set ytics 0,10
set ytics nomirror
set y2tics 0,5
set style data histograms
set style histogram rowstacked
set grid y
set boxwidth 0.40
plot '$plot_name.dat' u 2 t 'CPU cycles for TLB shootdown' fs solid 0.50 lt 1 axis x1y2, '' u 3 t 'CPU cycles for lock spinning' fs pattern 4 lt 1 axis x1y2, '' u 4:5:6 t 'Average execution time' w yerrorlines lt 1 pt 4 lw 2"; 
close OFD;

system("gnuplot $plot_name.plt");
