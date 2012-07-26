#!/usr/bin/perl -w

die "Usage: $0 <vm id> <gtask id or name> < <tracefile>\n" unless @ARGV == 2;
$vm_id = shift(@ARGV);
$gtask_id = shift(@ARGV);

while(<>) {
        if (/(\d+) ([A-Z]+) $vm_id (\d+) \d+ $gtask_id/) {
                next if $2 eq "WT" || $2 eq "BG";
                chomp;
                $vcpu_id = $3;
                $exec_time = $1 - $sched_time{$vcpu_id} if $2 eq "GD" && defined($sched_time{$vcpu_id});
                $sched_time{$vcpu_id} = $1 if $2 eq "GA";
                $_ .= "--> ${exec_time}us" if $2 eq "GD" && defined($exec_time);
                $space = 0;
                $space .= " " foreach ( 0 .. $vcpu_id );
                s/GA/${space}GA/g;
                s/GD/${space}GD/g;
                print "$_\n";
        }
}


