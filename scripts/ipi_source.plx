#!/usr/bin/perl -w

while(<>) {
        if (/GA (\d+) (\d+) \d+ (\S+) \d+/) {
                $gtask{$1}{$2} = $3;
        }
        if (/IP (\d+) (\d+)/ && defined($gtask{$1}{$2})) {
                $nr_ipi{$gtask{$1}{$2}}++;
        }
}
foreach $gtask (sort {$nr_ipi{$b}<=>$nr_ipi{$a}} keys %nr_ipi) {
        print "$gtask\t$nr_ipi{$gtask}\n";
}
