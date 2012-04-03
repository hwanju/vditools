#!/usr/bin/perl -w

die "Usage: $0 <share trace file> <cpu list (e.g., 0-2 or 0,3,4-7)> [xmin time(ms)(=0)] [xmax time(ms)(=unbound)]\n" if @ARGV < 2;
$fn = shift(@ARGV);
$cpustr = shift(@ARGV);
$xmin = @ARGV ? shift(@ARGV) : 0;
$xmax = @ARGV ? shift(@ARGV) : "";

die "file open error: $fn\n" unless -e $fn;

# parse cpustr
@grps = split(/,/, $cpustr);
foreach $grp (@grps) {
        @cpus = split(/-/, $grp);
        die "wrong expression: $grp\n" unless @cpus <= 2;
        foreach $cpu ($cpus[0] .. $cpus[-1]) {
                $cpulist{$cpu} = 1;
        }
}

$nr_cpus = int(keys %cpulist);
$w = 1.5;
$h = 0.5;
$total_h = $h * $nr_cpus;
$xtics = $xmax / 20 if ($xmax ne "");

$plt_cmd = "\
set terminal postscript eps enhanced color      \
set terminal post 'Times-Roman' 15            \
set output '$fn.eps'                            \
set size $w,$total_h                            \
set multiplot layout $nr_cpus,1                 \
set key vertical right                          \
set xlabel 'Time (msec)'        \
set ylabel 'Shares'     \
set xrange [$xmin:$xmax]        \
set yrange [0:1.1]        \
set grid y      \
";
$plt_cmd .= "set xtics 0, $xtics\n" if defined($xtics);

$origin = $total_h - $h;
foreach $cpu (sort {$a<=>$b} keys %cpulist) {
        system("grep -E \"^$cpu\" $fn | grep -v sync > $fn.$cpu");
        $cmd =  "set title 'CPU$cpu'\n";
        $cmd .= "set origin 0,$origin\n";
        $cmd .= "set size $w,$h\n";
        $cmd .= "plot '$fn.$cpu' u (\$2 / 1000):(\$3 / \$4) t '' w step lw 2\n";

        $plt_cmd .= $cmd;

        $origin -= $h;
}
$plt_cmd .= "unset multiplot\n";

open OFD, ">$fn.plt";
print OFD "$plt_cmd\n";
close OFD;
system("gnuplot $fn.plt");

##foreach $cpu (keys %cpulist) {
##        unlink("$fn.$cpu");
##}
