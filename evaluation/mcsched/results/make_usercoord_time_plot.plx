#!/usr/bin/perl -w

die "Usage: $0 <dir>\n" unless @ARGV == 1;
$dir = shift(@ARGV);
$dir =~ s/\/$//;
$plot_name = "$dir-time";
open OFD, ">$plot_name.dat";
print OFD "# ";

@res_files = `ls $dir/*-time.result`;
foreach $res_file (@res_files) {
	next if ($res_file =~ /baseline/);
        if ( $res_file =~ /(.+)@(.+)\.result/ ) {
		$workload_fmt = $1;
		$mode = $2;
		$workload_fmt =~ s/^.+\///g;
                chomp($res_file);
                open FD, $res_file;

		$type = $mode =~ /nospin/ ? "Block" : "Spin-then-block";
		$resched_co = $1 if ($mode =~ /\d+:\d+:\d+:\d+:\d+:(\d+)/);

		if ($workload_fmt =~ /(\d+)(\w+)\+(\d+)(\w+)/) {
			$id = 1;
			for (1 .. $1) {
				$workload_name[$id++] = $2;
				print OFD "$2(avg,sd,n)\t";
			}
			for (1 .. $3) {
				$workload_name[$id++] = $4;
				print OFD "$4(avg,sd,n)\t";
			}
		}
                while(<FD>) {
			if (/VM(\d+) workload iterations: (\d+)\/(\d+)/) {
				$guest_id = $1;
				$total_iter[$guest_id] = $2;
				$min_iter = $3;
				next;
			}
			if (/^Guest(\d+)/) {
				$guest_id = $1;
				$nr_iter[$guest_id] = 0;
			}
                        if (/Elapsed.+: ([0-9:]+)/) {
				next if ($nr_iter[$guest_id] >= $min_iter && $nr_iter[$guest_id] >= $total_iter[$guest_id] - 1);
                                @times = split(/:/, $1);
                                $nr_times = int(@times);
                                if ($nr_times == 2) {
                                        $sec = $times[0] * 60 + $times[1];
                                }
                                elsif ($nr_times == 3) {
                                        $sec = $times[0] * 3600 + $times[1] * 60 + $times[2];
                                }

				$sum{$type}{$guest_id}{$resched_co} += $sec;
				$sqsum{$type}{$guest_id}{$resched_co} += ($sec * $sec);
				$n{$type}{$guest_id}{$resched_co}++;
				$nr_iter[$guest_id]++;
                        }
                }
                close FD;
	}
}
print OFD "\n";

$base_idx = 2;
$avg_idx = $base_idx;
$avg_step = 3;
$plot = "'$plot_name.dat'";
$plot_first = 1;
@fill_map = ("fs solid 0.05", "fs solid 0.60", "fs pattern 2", "fs solid 0.45", "fs pattern 4", "fs pattern 6");
@title_map = ("w/o Resched-Co", "w/ Resched-Co");
$idx = 0;
foreach $type ("Spin-then-block", "Block") {
	printf OFD "%-30s", $type;
	foreach $guest_id (sort keys %{$sum{$type}}) {
		foreach $resched_co (sort {$a <=> $b} keys %{$sum{$type}{$guest_id}}) {
			$nr_samples = $n{$type}{$guest_id}{$resched_co};
			$avg = $sum{$type}{$guest_id}{$resched_co} / $nr_samples;
			$sd = sqrt(($sqsum{$type}{$guest_id}{$resched_co} / $nr_samples) - ($avg * $avg));
			printf OFD "%-8.2lf%-6.2lf%-3d\t", $avg, $sd, $nr_samples;

			$sd_idx = $avg_idx + 1;
			if ($plot_first && $guest_id == 1) {	# only plot the first main workload
				$plot .= ", ''" unless $resched_co == 0;
				$plot .= " u (\$$avg_idx / \$$base_idx):(\$$sd_idx / \$$base_idx):xtic(1) t \"$title_map[$idx]\" $fill_map[$idx] lt 1";
				$avg_idx += $avg_step;
				$idx++;
			}
		}
	}
	$plot_first = 0;
	print OFD "\n";
}
close OFD;
#print "$plot\n";
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 25
set output '$plot_name.eps'
set size 0.80,1
set key reverse right Left width -1
set ylabel 'Normalized execution time' 
set yrange [0:]
set parametric
#set xtics 0,10
set xtics nomirror
#set xtic rotate by -45
#set ytics 0,20
set ytics nomirror
set style data histograms
set style histogram 
set style histogram errorbars lw 2
set grid y
set boxwidth 0.75
plot $plot
";
close OFD;

system("gnuplot $plot_name.plt");
