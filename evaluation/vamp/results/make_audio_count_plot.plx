#!/usr/bin/perl -w

die "Usage: $0 <audio count desc>\n" unless @ARGV == 1;
$fn = shift(@ARGV);
open FD, $fn or die "file open error: $fn\n";
while(<FD>) {
	next if substr($_, 0, 1) eq "#"; 
	$line++;
	if ($line == 1) {
		@modes = split(/\s+/);
	}
	else {
		chomp;
		$prefix = $_;
		$bg_name = $1 if ($prefix =~ /^1video:(\w+)\+/);

		foreach $mode (@modes) {
			@ac_files = `ls $prefix-$mode*.ac`;
			foreach $ac_file (@ac_files) {
				chomp($ac_file);
			}
			$xmax = 0;
			$i = 0;
			foreach $ac_file (@ac_files) {
				$last_time = `tail -1 $ac_file | awk '{print \$1}'`;
				chomp($last_time);
				if ($xmax == 0 || $last_time < $xmax) {
					$xmax = $last_time; 
					$video_file = $ac_file;
					$bg_file = $ac_files[$i ^ 1];
				}
				$i++;
			}
			print "$xmax: video=$video_file\tbg=$bg_file\n";
			open OFD, ">$prefix-$mode-acount.plt";
			print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 25
set output '$prefix-$mode-acount.eps'
set key reverse Left left top
set ytics 0,50
set xran [0:$xmax]
set xlab 'Time (sec)'
set ylab 'Audio counter'
set size 1.5,0.5
plot '$video_file' u 1:2 t 'VLC' w lp lc 1 lt 1 lw 3 pt 4, '$bg_file' u 1:2 t '$bg_name' w lp lc 3 lt 2 lw 3 pt 6
";
			close OFD;
			system("gnuplot $prefix-$mode-acount.plt");
		}
	}
}
