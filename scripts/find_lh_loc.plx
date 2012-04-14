#!/usr/bin/perl

$coverage_line = 3;
$vmlinux_path="/backup/vdikernel/vmlinux";
die "Usage: $0 <eip> [vmlinux path(=$vmlinux_path)]\n" unless @ARGV > 0;
$eip = shift(@ARGV);
$vmlinux_path = shift(@ARGV) if @ARGV;

die "$vmlinux is not found\n" unless -e $vmlinux_path;

$nr_fails = 0;
retry:
$found = 0;
$loc = `addr2line -e $vmlinux_path $eip`;
chomp($loc);
($src_file, $line) = split(/:/, $loc);

if (!$line) {
        print "not_found_by_addr2line\n";
        die "addr2line cannot find a location for $eip (probably module)\n";
}

$initial_loc = $loc if $nr_fails == 0;
chomp($initial_loc);

$head = $line + $coverage_line;
$tail = $coverage_line * 2 + 1;
@src = `head -n $head $src_file | tail -n $tail`;

$spin_lock_call = "";
$l = $line - $coverage_line;
##print "$line, $head, $tail, $l\n";
foreach $s (@src) {
        #print "$src_file:$l\t$s";
        if (($s =~ /_lock/ || $s =~ /_LOCK/) && $s !~ /unlock/) {
                # check exceptional cases
                if ($l < $line && $s =~ /void spin_lock/) {
                        $spin_lock_call = "s";
                        last;
                }
                $lock_src = $s;
                $lock_line = $l;
                $lock_offset = $l - $line;
                $found = 1;

                # if reaching the line and found, break
                last if $l <= $line;
        }
        $initial_src = $s if $l == $line && $nr_fails == 0;
        $l++;
}
if ($found) {
        $lock_src =~ s/^\s+//g;
        chomp($lock_src);
        print "$src_file:$lock_line\t$lock_src\t$lock_offset\t$nr_fails$spin_lock_call\n";
}
else {
        $nr_fails++;
        if ($nr_fails < 15) {
                $eip = hex($eip) - 4;
                $eip = sprintf("%lx", $eip);
		#print "try: $eip\n";
                goto retry;
        }
        else {
                $initial_src = "spin_lock" if (!defined($initial_src));
                chomp($initial_src);
                print "$initial_loc\t$initial_src\t0\t${spin_lock_call}f\n";
                #print "not_found_by_script\n";
                #die "Fail to find a location\n";
        }
}
