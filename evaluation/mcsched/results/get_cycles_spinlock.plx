#!/usr/bin/perl -w
if (@ARGV && $ARGV[0] eq "-p") {
	$plot = shift(@ARGV);
}
$dir = @ARGV ? shift(@ARGV) : ".";
@flist = `ls $dir/*.guest.perf`;

foreach $f (@flist) {
        chomp($f);
        open FD, $f;
        $sum = $kernel_pct = 0;
        while(<FD>) {
                if(/spin_lock/) {	# for debug spinlock || /native_read_tsc/ ||	/__delay/ || /delay_tsc/ ) {
                        @cols = split(/\s+/);
                        $pct = $cols[1];
                        $pct =~ s/%//g;
                        $sum += $pct;
                }
		$kernel_pct += $1 if (/\[g\]/ && /^\s+(\d+\.\d+)%/);
        }
        close FD;
	$f =~ s/\.guest\.perf$//g;
	if (!$plot) {
		printf "$f\t$sum (%.2lf)\t%.2lf%%\n", $kernel_pct, $sum * 100 / $kernel_pct;
	}
	else {
		$workload = $1 if ($f =~ /[^_]1(\w+)\+/);
		if ($workload) {
			printf "$workload\t%.2lf\n", $sum * 100 / $kernel_pct;
		}
	}
}
