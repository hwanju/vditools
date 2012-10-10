#!/usr/bin/perl -w


=pod
* description file format
1st line:
<plot file name> <xmax> <ymax>

2nd~ line:
<trace file path> <task name> <plot label> <line type> <line color>
=cut

die "Usage: $0 [-c: if first conver to tqcdf, use this] <description file>" unless @ARGV > 0;
$convert = $ARGV[0] eq "-c" ? shift(@ARGV) : 0;
$desc_fn = shift(@ARGV);
open FD, $desc_fn or die "file open error: $desc_fn\n";

$line = 0;
$plot_cmd = "plot ";
while(<FD>) {
	$line++;
	if($line == 1) {
		($plot_name, $xmax, $ymax) = split(/\s+/);
		next;
	}
	next if substr($_, 0, 1) eq "#";
	($trace_fn, $task_name, $plot_label, $lt, $lc) = split(/\s+/);
	$plot_label =~ s/_/ /g;

	`./get_timequantum.plx $trace_fn $task_name` if $convert;
	$tqcdf_fn = $trace_fn;
	$tqcdf_fn =~ s/\.debug/-$task_name\.tqcdf/g;

	$plot_cmd .= ", " if $line > 2;
	$plot_cmd .= "'$tqcdf_fn' u (\$1 / 1000):2 t '$plot_label' lt $lt lc $lc lw 10 w l";
}

##print "$plot_cmd\n";

$key_xpos = $xmax * 1.2;
$key_ypos = $ymax * 0.4;
open OFD, ">$plot_name.plt";
print OFD "
set key reverse Left at $key_xpos,$key_ypos
set xran [0:$xmax]
set yran [0:$ymax]
set xlab 'Time quantum (usec)'
set ylab 'CDF'
set terminal postscript eps enhanced
set terminal post 'Times-Roman' 27
set output '$plot_name.eps'
$plot_cmd
";
close(OFD);
system("gnuplot $plot_name.plt");
