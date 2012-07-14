#!/usr/bin/perl -w

$def_workload_fmt = "1vips+2facesim";
die "Usage: $0 <dir (e.g., sensitivity-urgent-allowance> [corun format(=$def_workload_fmt)]\n" unless @ARGV;
$dir = shift(@ARGV);
$dir =~ s/\/$//g;
$workload_fmt = @ARGV ? shift(@ARGV) : $def_workload_fmt;

# get solorun data to calculate slowdown
$solorun_time_fn = "solorun_time.dat";
($main_workload, $nr_corun, $corun_workload) = ($1, $2, $3) if ($workload_fmt =~ /1(\w+)\+(\d+)(\w+)/);
die "Error: $solorun_time_fn must exist for calculating slowdown!\n" if ! -e $solorun_time_fn;
$solorun_time = `grep $main_workload $solorun_time_fn | awk '{print \$2}'`;
$corun_solorun_time = `grep $corun_workload $solorun_time_fn | awk '{print \$2}'`;
chomp($solorun_time);
chomp($corun_solorun_time);
$nr_corun = $nr_corun == 1 ? "" : " * $nr_corun";

@tlbipi_cycles = `./get_cycles_tlbipi.plx $dir`;
@spinlock_cycles = `./get_cycles_spinlock.plx $dir`;
$i = 0;
$max_cycles = $max_slowdown = 0;
$workload_fmt =~ s/\+/\\\+/g;
$i = -1;
foreach $line (@tlbipi_cycles) {
	$i++;
	next unless ($line =~ /$workload_fmt/);
	($conf, $cycle) = split(/\s+/, $line);
	if ($conf =~ /(\d+):\d+:(\d+):\d+:\d+:\d+/) {
		$urgent_enabled = $1;
		if ($urgent_enabled) {
			$urgent_allowance = $2;
			$urgent_allowance /= 1000000;	# in ms
		}
		else {
			$urgent_allowance = -1;
		}

		($conf, $cycle) = split(/\s+/, $line);
		$tlb{$urgent_allowance} = $cycle;
		$total_cycles = $cycle;

		($conf, $cycle) = split(/\s+/, $spinlock_cycles[$i]);
		$spinlock{$urgent_allowance} = $cycle;
		$total_cycles += $cycle;

		$max_cycles = $total_cycles if $total_cycles > $max_cycles;

		$res = `./get_avg_time.plx $conf.result 10 1`;
		($avg, $sd) = split(/\s+/, $res);
		$slowdown{$urgent_allowance} = $avg / $solorun_time;
		$sd_slowdown{$urgent_allowance} = $sd / $solorun_time;

		$max_slowdown = $slowdown{$urgent_allowance} if $slowdown{$urgent_allowance} > $max_slowdown;

		$res = `./get_avg_time.plx $conf.result 3 -1`;
		($avg, $sd) = split(/\s+/, $res);
		$corun_slowdown{$urgent_allowance} = $avg / $corun_solorun_time;
		$corun_sd_slowdown{$urgent_allowance} = $sd / $corun_solorun_time;

		$max_slowdown = $corun_slowdown{$urgent_allowance} if $corun_slowdown{$urgent_allowance} > $max_slowdown;

		$stat = `./get_urgent_stat.plx $conf.schedstat`;
		@urgent_stat = split(/\s+/, $stat);
		$urgent_fail{$urgent_allowance} = $urgent_stat[-1];
	}
}
$workload_fmt =~ s/\\\+/\+/g;
$plot_name = "$dir-$workload_fmt";
open OFD, ">$plot_name.dat";
print OFD "#Urgent_tslice\tTLB cycles\tSpinlock cycles\tAvg Time\tSd Time\n";
$i = 0;
$xtics = "set xtics (";
foreach $urgent_allowance (sort {$a <=> $b} keys %tlb) {
	$xt = $urgent_allowance == -1 ? "No UVF" : $urgent_allowance;
	$xtics .= ", " unless $i == 0;
	$xtics .= "'$xt' $i";
	printf OFD "$urgent_allowance\t%.2lf\t%.2lf\t%d\t%.2lf\t%.2lf\t%.2lf\t%.2lf\t%d\n", 
		$tlb{$urgent_allowance}, $spinlock{$urgent_allowance}, 
		$i++, $slowdown{$urgent_allowance}, $sd_slowdown{$urgent_allowance},
		$corun_slowdown{$urgent_allowance}, $corun_sd_slowdown{$urgent_allowance},
		$urgent_fail{$urgent_allowance};
}
close OFD;
$xtics .= ")";
$max_cycles += 15;
$max_slowdown += 2;
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 24
set output '$plot_name.eps'
set key invert reverse left Left width -1
set xlabel 'Urgent allowance (msec)'
set ylabel 'Slowdown (relative to solorun)' 
set y2label 'CPU cycles (%)' 
set xrange [-1:$i]
set yrange [0:$max_slowdown]
set y2range [0:$max_cycles]
set xtics nomirror
#set xtic rotate by -45
$xtics
set ytics 0,1
set ytics nomirror
set y2tics 0,5
set style data histograms
set style histogram rowstacked
set grid y
set boxwidth 0.40
plot '$plot_name.dat' u 2 t 'CPU cycles for TLB shootdown ($main_workload)' fs solid 0.50 lt 1 axis x1y2, '' u 3 t 'CPU cycles for lock spinning ($main_workload)' fs pattern 4 lt 1 axis x1y2, '' u 4:7:8 t 'Slowdown ($corun_workload$nr_corun)' w yerrorlines lt 2 pt 4 lw 2, '' u 4:5:6 t 'Slowdown ($main_workload)' w yerrorlines lt 1 pt 7 lw 2"; 
close OFD;

system("gnuplot $plot_name.plt");
