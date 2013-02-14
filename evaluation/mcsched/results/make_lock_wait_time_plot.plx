#!/usr/bin/perl -w

die "Usage: $0 <result dir> [mode(=baseline)]" unless @ARGV;
$dir = shift(@ARGV);
$mode = @ARGV ? shift(@ARGV) : "baseline";
$plot_name = $dir;
$plot_name =~ s/\/$//g;
$plot_name =~ s/-lockstat//g;
$plot_name .= "-$mode-lock_wait_time";
open OFD, ">$plot_name.dat";

@workloads = qw( bodytrack canneal dedup facesim fluidanimate streamcluster swaptions vips x264 );

foreach $w (@workloads) {
        $res_file = `ls $dir/1$w*\@baseline.result`;
        chomp($res_file);
        @res_lines = `./get_lockstat_waittime.plx $res_file 95`;
        foreach $l (@res_lines) {
                chomp($l);
                ($lock_name, $pct) = split(/\s+/, $l);
                $lock{$lock_name}++;
                $wtime{$lock_name} += $pct;
                $wait_time{$w}{$lock_name} += $pct;
        }
}

print OFD "#workloads";
foreach $lock_name (sort {$wtime{$b} <=> $wtime{$a}} keys %wtime) {
        print OFD "\t$lock_name" if $lock{$lock_name} > 1 || $wtime{$lock_name} > 5;
}
print OFD "\tothers\n";
foreach $w (@workloads) {
        print OFD "$w";
        foreach $lock_name (sort {$wtime{$b} <=> $wtime{$a}} keys %wtime) {
                if ($lock{$lock_name} > 1 || $wtime{$lock_name} > 5) {
                        if (defined($wait_time{$w}{$lock_name})) {
                                print OFD "\t$wait_time{$w}{$lock_name}";
                                $acct_wait_time{$w} += $wait_time{$w}{$lock_name};
                        }
                        else {
                                print OFD "\t0";
                        }
                }
        }
        printf OFD "\t%.2lf\n", 100 - $acct_wait_time{$w};
}
close OFD;
$xtics = "set xtics ( ";
$i = 0;
foreach $w (@workloads) {
        $xtics .= ", " if $i;
        $xtics .= "'$w' $i";
        $i++;
}
$xtics .= " )";

####### the following is the manual depending on generaged data file !!!!! #######
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 25
set output '$plot_name.eps'
#set key invert reverse Left width -1 outside
set key invert reverse Left width -1 outside
set size 1.5,1
#set xlabel 'Workloads'
set ylabel 'Spinlock wait time (%)' 
set yrange [0:100]
set xtics 0,10
set xtics nomirror
set xtic rotate by -45
$xtics
#set ytics 0,20
set grid y
set style data histograms
set style histogram rowstacked 
#set style histogram cluster gap 0.2
set style fill solid border 0.2
set boxwidth 0.6
# lockstat original version (trylock based)
#plot '$plot_name.dat' u 2 t 'futex-queue lock' fs solid 0.10 lt 1 , '' u 3 t 'sem-wait lock' fs pattern 5 lt 1 , '' u 4 t 'runqueue lock' fs solid 0.35 lt 1 , '' u 5 t 'pagetable lock' fs pattern 6 lt 1 , '' u 6 t 'wait-queue lock' fs solid 0.65  lt 1 , '' u 7 t 'other locks' fs solid 0.85 lt 1
# lockstat fixed version (ticketlock based)
plot '$plot_name.dat' u 2 t 'futex-queue lock' fs solid 0.10 lt 1 , '' u 3 t 'sem-wait lock' fs pattern 5 lt 1 , '' u 4 t 'pagetable lock' fs solid 0.35 lt 1 , '' u 5 t 'runqueue lock' fs pattern 6 lt 1 , '' u 6 t 'other locks' fs solid 0.65  lt 1 
";
close OFD;

system("gnuplot $plot_name.plt");
