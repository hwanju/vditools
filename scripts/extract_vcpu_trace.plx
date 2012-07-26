#!/usr/bin/perl -w

die "Usage: $0 <vm id> <vcpu id> < <tracefile>\n" unless @ARGV == 2;
$vm_id = shift(@ARGV);
$vcpu_id = shift(@ARGV);

while(<>) {
        if (/(\d+) ([A-Z]+) $vm_id $vcpu_id (\d+)/) {
                #next if $2 eq "WT";
                if ($2 eq "WT") {
                        s/WT/ => WT/g;
                        print "$_";
                        next;
                }
                chomp;
                $exec_time = $1 - $sched_time if $2 eq "GD" && defined($sched_time);
                $sched_time = $1 if $2 eq "GA";
                $_ .= " -> ${exec_time}us" if $2 eq "GD" && defined($exec_time);
                s/GA/  GA/g;
                s/GD/  GD/g;
                s/BG/ BG/g;
                print "$_\n";
        }
}


