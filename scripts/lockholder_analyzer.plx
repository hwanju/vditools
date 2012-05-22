#!/usr/bin/perl -w

$filter_str = @ARGV ? shift(@ARGV) : "";

####### configurable parameters
$max_lh_id = 6;
$thresh_lhp_per_sec = 20;

@res_files = `ls *$filter_str.result`;
@lhp_files = `ls *$filter_str.lockholder`;

foreach $f (@res_files) {
        if ( $f =~ /\d+(\w+)\+\d+\w+@(\w+)/ ) {
		$f = `basename $f`;
		chomp($f);
		$w = $1 if ($f =~ /(^[\w+]+)@/);
		open FD, $f or die "file open error: $f\n";
                while(<FD>) {
                        if (/Elapsed.+: ([0-9:]+)/) {
                                @times = split(/:/, $1);
                                $nr_times = int(@times);
                                if ($nr_times == 2) {
                                        $sec = $times[0] * 60 + $times[1];
                                }
                                elsif ($nr_times == 3) {
                                        $sec = $times[0] * 3600 + $times[1] * 60 + $times[2];
                                }
				$extime_sec{$w} = $sec;
				last;
                        }
                }
                close FD;
        }
}

foreach $f (@lhp_files) {
	$f = `basename $f`;
	chomp($f);
	$w = $1 if ($f =~ /(^[\w+]+)@/);
	open FD, $f or die "file open error: $f\n";
	$cur_mode = "";
	while (<FD>) {
		@info = split(/\s+/);
		next if (/^\s*$/);
		if ($info[0] eq "#") {
			$cur_mode = $info[1];
			next;
		}
		if ($cur_mode eq "lhp" && $info[0] > 0) {
			$lh_id = "$info[0]:$info[1]:$info[2]:$info[3]:$info[4]";
			$count = $info[5];

			# reason code
			# e000: by another VM
			# f000: by another vcpu in the same VM
			# f001: by qemu thread in the same VM
			$reason_code = $info[6];    

			$workload_lhp_count_by_id{$w}{$lh_id} += $count;
			$inter_vm_lhp_count{$w} += $count if $reason_code eq "e000";
			$intra_vm_lhp_count{$w} += $count if $reason_code eq "f000" || $reason_code eq "f001";
			$workload_lhp_count{$w} += $count;
			$lhp_count += $count;
		}
		elsif ($cur_mode eq "lhipi") {
			$lh_id = "$info[0]:$info[1]:$info[2]:$info[3]:$info[4]";
			$count = $info[5];

			# ipi type
			$ipi_type = $info[6];    

			if ($ipi_type eq "fd") {	# resched ipi
				#print "$w\t$lh_id\n" if $lh_id eq "0:0:0:0:0";
				$workload_lhipi_count_by_id{$w}{$lh_id} += $count;
				$workload_lhipi_count{$w} += $count;
			}
		}
		elsif ($cur_mode eq "lhp-reschedipi") {
			if (/value \|/) {
				while(<FD>) {
					last if /^$/;
					if (/^\s*(\d+)\s+.+\s+(\d+)$/) {
						$resched_ipi_hist{$1} += $2;
						$lh_resched_ipi += $2;
					}
				}
			}
		}
	}
}

#print ("# workload\tlhp/sec\tlhp\textime\n");
print ("# workload\tlhp/sec\tintra\tinter\n");
foreach $w (sort keys %workload_lhp_count) {
	$wname = $w;
	$wname =~ s/^(\d+)//g;
	$wname =~ s/\+\w+$//g;
	$lhp_per_sec{$w} = $workload_lhp_count{$w} / $extime_sec{$w};
	$intra_vm_lhp_per_sec = $intra_vm_lhp_count{$w} / $extime_sec{$w};
	$inter_vm_lhp_per_sec = $inter_vm_lhp_count{$w} / $extime_sec{$w};
	printf("$wname\t%d\t%d\t%d\n", $lhp_per_sec{$w}, $intra_vm_lhp_per_sec, $inter_vm_lhp_per_sec);
	#printf("$wname\t%d\t$workload_lhp_count{$w}\t$extime_sec{$w}\n", $lhp_per_sec{$w});
}

$nr_workloads = keys %workload_lhp_count; 
foreach $w (sort keys %workload_lhp_count) {
	if ($lhp_per_sec{$w} < $thresh_lhp_per_sec) {
		$nr_workloads--;
		next;
	}
	foreach $lh_id (keys %{$workload_lhp_count_by_id{$w}}) {
		$lhp_lhid_proportion{$lh_id} += 
			$workload_lhp_count_by_id{$w}{$lh_id} / $workload_lhp_count{$w};
	}
}

# assign numerical id to lh_id based on frequency
$id = 1;
foreach $lh_id (sort {$lhp_lhid_proportion{$b} <=> $lhp_lhid_proportion{$a}} keys %lhp_lhid_proportion) {
	last if $id > $max_lh_id;
	printf "$id\t$lh_id\t%.2lf\n", $lhp_lhid_proportion{$lh_id} / $nr_workloads;
	$id_map[$id++] = $lh_id;
}

# report lhp stat
print "# lhp\n";
foreach $w (sort keys %workload_lhp_count) {
	next if $lhp_per_sec{$w} < $thresh_lhp_per_sec;
	$wname = $w;
	$wname =~ s/^(\d+)//g;
	$wname =~ s/\+\w+$//g;
	print "$wname\t";
	$major_count = 0;
	for ($id=1; $id <= $max_lh_id; $id++) {
		$lh_id = $id_map[$id];
		if ($workload_lhp_count_by_id{$w}{$lh_id}) {
			$count = $workload_lhp_count_by_id{$w}{$lh_id};
			printf ("%.1lf\t", $count * 100 / $workload_lhp_count{$w});
			$major_count += $count;
		}
		else {
			printf("0.0\t");
		}
	}
	$others_count = $workload_lhp_count{$w} - $major_count;
	printf ("%.1lf\n", $others_count * 100 / $workload_lhp_count{$w});
}

# report lhipi stat
print "# lhipi\n";
foreach $w (sort keys %workload_lhipi_count) {
	next if $lhp_per_sec{$w} < $thresh_lhp_per_sec;
	$wname = $w;
	$wname =~ s/^(\d+)//g;
	$wname =~ s/\+\w+$//g;
	print "$wname\t";
	$major_count = 0;
	for ($id=1; $id <= $max_lh_id; $id++) {
		$lh_id = $id_map[$id];
		if ($workload_lhipi_count_by_id{$w}{$lh_id}) {
			$count = $workload_lhipi_count_by_id{$w}{$lh_id};
			printf ("%.1lf\t", $count * 100 / $workload_lhipi_count{$w});
			$major_count += $count;
		}
		else {
			printf("0.0\t");
		}
	}
	$no_lhipi_count = $workload_lhipi_count_by_id{$w}{"0:0:0:0:0"};
	$others_count = $workload_lhipi_count{$w} - $major_count - $no_lhipi_count;
	printf ("%.1lf\t", $others_count * 100 / $workload_lhipi_count{$w});
	printf ("%.1lf\n", $no_lhipi_count * 100 / $workload_lhipi_count{$w});
}

printf ("# lhipi / lhp = %.3lf\n", $lh_resched_ipi / $lhp_count);
$cum_lhipi_count = 0;
foreach $t (sort {$a <=> $b} keys %resched_ipi_hist) {
	$cum_lhipi_count += $resched_ipi_hist{$t};
	printf ("%d\t%.3lf\t%.3lf\n", $t, $resched_ipi_hist{$t} / $lhp_count, $cum_lhipi_count / $lhp_count);
}
