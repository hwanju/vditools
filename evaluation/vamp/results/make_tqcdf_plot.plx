#!/usr/bin/perl -w

die "Usage: $0 <tqcdf file>\n" unless @ARGV == 1;
$dat_fn = shift(@ARGV);
$name = $dat_fn;
$name =~ s/\.\w+$//g;
open OFD, ">$name.plt";

print OFD "
set xran [0:5000]
set yran [0:100]
set xlab 'Time quantum (usec)'
set ylab 'CDF'
set terminal postscript eps
set terminal post 'Times-Roman' 30
set output '$name.eps'
plot '$dat_fn' u (\$1 / 1000):2 t '' lt 1 lw 3 w lines
";
close(OFD);
system("gnuplot $name.plt");
