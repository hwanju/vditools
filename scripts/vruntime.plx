#!/usr/bin/perl -w

die "Usage: $0 <vruntime raw file> <user input id>\n" unless @ARGV == 2;
$fn = shift(@ARGV);
$input_id = shift(@ARGV);

$prev_period_us = 2000000;

open FD, $fn or die "Error: file open error ($fn)\n";

while(<FD>) {
        if (/(\d+) I (\d+) (\d+)/) {
                if ($3 == $input_id) {
                        $input_time_us = $1;
                        $input_vm_id = $2;
                        last;
                }
        }
}
die "Error: user input id %d is not found!\n" unless defined($input_time_us);

seek(FD, 0, 0);

system( "rm -f vruntime-v*.dat" );
while(<FD>) {
        $line++;
        if (/(\d+) R (\d+) (\d+) (\d+) (\d+) (\d+) (\d+) (\d+)/) {
                $vcpu_id = $3;
                if ($log_enabled{$vcpu_id}) {
                        $vm_id = $2;
                        $pcpu_id = $4;
                        $runtime = $7;
                        $vruntime = $8;
                        if ($input_vm_id == $vm_id) { 
                                if (defined($prev_pcpu_id{$vcpu_id}) && $prev_pcpu_id{$vcpu_id} != $pcpu_id) {
                                        #$prev_vruntime{$vcpu_id} = $vruntime;
                                        print "p$prev_pcpu_id{$vcpu_id} -> $pcpu_id = v$vcpu_id: $prev_vruntime{$vcpu_id}\n" if $vcpu_id == 4 && $vcpu_flags == 0;
                                }
                                if (!defined($prev_vruntime{$vcpu_id})) {
                                        $prev_vruntime{$vcpu_id} = $vruntime;
                                        print "--> v$vcpu_id: $prev_vruntime{$vcpu_id}\n" if $vcpu_id == 4 && $vcpu_flags == 0;
                                }
                                $time_us = $1 - $input_time_us;
                                $vcpu_flags = $5;
                                #$share = $6;

                                $elapsed_vruntime = ($vruntime - $prev_vruntime{$vcpu_id});
                                $mono_vruntime{$vcpu_id} += $elapsed_vruntime;
                                $mono_runtime{$vcpu_id} += $runtime;

                                printf "$line: r=%d vr=%d evr=$elapsed_vruntime er=$runtime ($vruntime - $prev_vruntime{$vcpu_id})\n",$mono_runtime{$vcpu_id},  $mono_vruntime{$vcpu_id} if $vcpu_id == 4 && $vcpu_flags == 0;

                                open OFD, ">> vruntime-v$vcpu_id-$vcpu_flags.dat";
                                printf OFD "%d %d\n",$mono_runtime{$vcpu_id} / 1000,  $mono_vruntime{$vcpu_id} / 1000;        # to us scale
                                close OFD;

                                $prev_pcpu_id{$vcpu_id} = $pcpu_id;
                                $prev_vruntime{$vcpu_id} = $vruntime;
                        }
                }
        }
        elsif (/(\d+) E (\d+) (\d+) (\d+) (\d+) (\d+) (\d+)/) {
                $time_us = $1;
                $vm_id = $2;
                $vcpu_id = $3;
                if ($input_vm_id == $vm_id) {
                        $log_enabled{$vcpu_id} = 1 if ($input_time_us - $time_us <= $prev_period_us);
                        if ($log_enabled{$vcpu_id}) {
                                $vruntime = $7;
                                $prev_vruntime{$vcpu_id} = $vruntime;
                                print "!!! v$vcpu_id: $prev_vruntime{$vcpu_id}\n" if $vcpu_id == 4;
                        }
                }
        }
        elsif (/\d+ I \d+ (\d+)/) {
                last if ($1 > $input_id);
        }
}
