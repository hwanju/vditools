#!/usr/bin/perl -w

sub update_exec_time {
        $time_us = $_[0];
        $vm_id = $_[1];
        $vcpu_id = $_[2];

        $id = defined($ui_id{$vm_id}) ? $ui_id{$vm_id} : 0;

        $exec_time_for_ipi = $time_us - $ipi_send_time{$vm_id}{$vcpu_id};
        print "$ipi_vector{$vm_id}{$vcpu_id} ($cur_gtask{$vm_id}{$vcpu_id}): $exec_time_for_ipi ($ipi_send_time{$vm_id}{$vcpu_id} - $time_us)\n" if $exec_time_for_ipi > 10000;
        $vec = $ipi_vector{$vm_id}{$vcpu_id};

        $total_exec_time{$vec} += $exec_time_for_ipi;
        $max_exec_time{$vec} = $exec_time_for_ipi if $exec_time_for_ipi > $max_exec_time{$vec};
        $nr_exec_time{$vec}++;

        if ($vec eq "e1") {
                $e1_total_exec_time{$id} += $exec_time_for_ipi;
                $e1_max_exec_time{$id} = $exec_time_for_ipi if $exec_time_for_ipi > $e1_max_exec_time{$id};
                $e1_nr_exec_time{$id}++;
        }
        elsif ($vec eq "d1") {
                $d1_total_exec_time{$id} += $exec_time_for_ipi;
                $d1_max_exec_time{$id} = $exec_time_for_ipi if $exec_time_for_ipi > $d1_max_exec_time{$id};
                $d1_nr_exec_time{$id}++;
        }

        $synced = 1;
        foreach $dst_vcpu_id (keys %{$ipi_pending{$vm_id}{$vcpu_id}}) {
                if ($ipi_pending{$vm_id}{$vcpu_id}{$dst_vcpu_id}) {
                        print "--- $vec (v$dst_vcpu_id): Non synced! ($ipi_send_time{$vm_id}{$vcpu_id} - $time_us)\n" if $vec eq "e1";
                        $synced = 0;
                }
        }
        #print "+++ $vec: synced! ($ipi_send_time{$vm_id}{$vcpu_id} - $time_us)\n" if $synced;

        $ipi_send_time{$vm_id}{$vcpu_id} = 0;
}

while(<>) {
        if (/(\d+) GA (\d+) (\d+) \d+ (\S+) \d+/) {
                if ($ipi_send_time{$2}{$3} && defined($cur_gtask{$2}{$3}) && $cur_gtask{$2}{$3} ne $4) {
                        update_exec_time($1, $2, $3);
                }
                $cur_gtask{$2}{$3} = $4;
        }
        elsif (/(\d+) VA (\d+) (\d+) \d+/) {
                $vm_id = $2;
                $vcpu_id = $3;

                $vcpu_running{$vm_id}{$vcpu_id} = 1;

                for ($src_vcpu_id = 0 ; $src_vcpu_id < 8; $src_vcpu_id++) {     # FIXME: hardcoded 8
                        next if $src_vcpu_id == $vcpu_id;
                        foreach $dst_vcpu_id (keys %{$ipi_pending{$vm_id}{$src_vcpu_id}}) {
                                $ipi_pending{$vm_id}{$src_vcpu_id}{$dst_vcpu_id} = 0 if ($dst_vcpu_id == $vcpu_id);
                        }
                }
        }
        elsif (/(\d+) VD (\d+) (\d+) \d+ (\d+)/) {
                ###$flags = $4;
                ###if ($ipi_send_time{$2}{$3} && $flags == 0) {
                ###        update_exec_time($1, $2, $3);
                ###}
                $vcpu_running{$2}{$3} = 0;
        }
        elsif (/(\d+) HLT (\d+) (\d+)/) {
                if ($ipi_send_time{$2}{$3}) {
                        update_exec_time($1, $2, $3);
                }
        }
        elsif (/(\d+) IPI (\d+) (\d+) \d+ icr_low=[0-9a-f]+ sh=\S+ vec=([0-9a-f]+)/) {
                $time_us = $1;
                $vm_id = $2;
                $vcpu_id = $3;
                $vec = $4;
                #if (($vec eq "e1" || $vec eq "d1") && defined($cur_gtask{$vm_id}{$vcpu_id}) && ($cur_gtask{$vm_id}{$vcpu_id} =~ /00187/)) {
                #if (($vec eq "e1" || $vec eq "d1") && defined($cur_gtask{$vm_id}{$vcpu_id})) {
                if (($vec eq "e1") && defined($cur_gtask{$vm_id}{$vcpu_id})) {
                        $ipi_send_time{$vm_id}{$vcpu_id} = $time_us;
                        $ipi_vector{$vm_id}{$vcpu_id} = $vec;
                        $max_exec_time{$vec} = 0 unless defined($max_exec_time{$vec});

                        $id = defined($ui_id{$vm_id}) ? $ui_id{$vm_id} : 0;
                        $e1_max_exec_time{$id} = 0 unless defined($e1_max_exec_time{$id});
                        $d1_max_exec_time{$id} = 0 unless defined($d1_max_exec_time{$id});
                }
        }
        elsif (/\d+ IP (\d+) (\d+) (\d+)/) {
                $vm_id = $1;
                $src_vcpu_id = $2;
                $dst_vcpu_id = $3;

                if ($ipi_send_time{$vm_id}{$src_vcpu_id}) {
                        if ($vcpu_running{$vm_id}{$dst_vcpu_id}) {
                                $ipi_pending{$vm_id}{$src_vcpu_id}{$dst_vcpu_id} = 0;
                        }
                        else {  # not running, so pending ipi
                                $ipi_pending{$vm_id}{$src_vcpu_id}{$dst_vcpu_id} = 1;
                        }
                }
        }
        elsif (/\d+ UI (\d+) (\d+) (\d+)/) {
                $vm_id = $1;
                $event_type = $2;
                $event_info = $3;
                if ($event_type == 3 || ($event_type == 0 && $event_info == 28)) {
                        $ui_id{$vm_id}++;
                        delete($ipi_send_time{$vm_id});
                }
        }
}

print "\nTotal statistics (usec):\n";
foreach $vec (keys %total_exec_time) {
        printf "vector=$vec: avg=%d max=%d\n", $total_exec_time{$vec} / $nr_exec_time{$vec}, $max_exec_time{$vec};
}
print "\nVector e1 statistics (usec):\n";
foreach $id (sort {$a<=>$b} keys %e1_total_exec_time) {
        printf "id=$id: avg=%d max=%d\n", $e1_total_exec_time{$id} / $e1_nr_exec_time{$id}, $e1_max_exec_time{$id};
}
print "\nVector d1 statistics (usec):\n";
foreach $id (sort {$a<=>$b} keys %d1_total_exec_time) {
        printf "id=$id: avg=%d max=%d\n", $d1_total_exec_time{$id} / $d1_nr_exec_time{$id}, $d1_max_exec_time{$id};
}
