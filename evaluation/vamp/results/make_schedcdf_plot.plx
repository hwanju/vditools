#!/usr/bin/perl -w


=pod
* description file format
1st line:
<sched name> ...

2nd line:
<xmax>	...

3rd~ line:
<trace file path> <plot label> <line type> <line color>
=cut

die "Usage: $0 [-c: if first conver to schedcdf, use this] <description file>" unless @ARGV > 0;
$convert = $ARGV[0] eq "-c" ? shift(@ARGV) : 0;
$desc_fn = shift(@ARGV);
$prefix = $desc_fn;
$prefix =~ s/\..+$//g;
open FD, $desc_fn or die "file open error: $desc_fn\n";

$line = 0;
$nr_conf = 0;
while(<FD>) {
	next if substr($_, 0, 1) eq "#";
	$line++;
	if($line == 1) {
		@scheds = split(/\s+/);
		next;
	}
	elsif($line == 2) {
		@xrans = split(/\s+/);
		next;
	}
	($trace_fn, $plot_label, $lt, $lc) = split(/\s+/);
	$plot_label =~ s/_/ /g;
	$plot[$nr_conf][0] = $trace_fn;
	$plot[$nr_conf][1] = $plot_label;
	$plot[$nr_conf][2] = $lt;
	$plot[$nr_conf][3] = $lc;
	$nr_conf++;
}
$i = 0;
foreach $sched (@scheds) {
	$plot_cmd = "plot ";
	foreach $n (0 .. ($nr_conf - 1)) {
		$trace_fn = $plot[$n][0];
		$plot_label = $plot[$n][1];
		$lt = $plot[$n][2];
		$lc = $plot[$n][3];

		`./get_sched.plx $sched $trace_fn` if $convert;

		$schedcdf_fn = $trace_fn;
		$schedcdf_fn =~ s/\.result/-$sched\.schedcdf/g;

		$statistics = `tail -1 $schedcdf_fn`;
		print "$schedcdf_fn:\t$statistics";

		$plot_cmd .= ", " if $plot_cmd ne "plot ";
		$plot_cmd .= "'$schedcdf_fn' u 1:2 t '$plot_label' lt $lt lc $lc lw 10 w l";

	}
	$plot_name = "$prefix-$sched";

	open OFD, ">$plot_name.plt";
	print OFD "
	set key reverse Left right outside 
	set xran [$xrans[$i]]
	set yran [0:100]
	set xlab 'Time (msec)'
	set ylab 'CDF'
	set size 1.3,1
	set terminal postscript eps enhanced
	set terminal post 'Times-Roman' 25
	set output '$plot_name.eps'
	$plot_cmd
	";
	close(OFD);
	system("gnuplot $plot_name.plt");

	$i++;
}
