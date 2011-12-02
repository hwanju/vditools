#!/usr/bin/perl -w

system( "rm -f sched-vm*.dat" );
$shift_y = 0.12;
while(<>) {
        if (/(\d+) GA (\d+) (\d+) (\d+) [0-9a-f]{5} (\d+)/) {
                #$profile_id{$2} = 0 unless defined($profile_id{$2});
                $id = $profile_id{$2};
                #$start_time_ms{$2} = $1/1000 if !defined($start_time_ms{$2}) || !$start_time_ms{$2};
                $time_ms = $1/1000;
                $time_offset_ms = int($time_ms - $start_time_ms{$2});

                $fn = $5 == 2 ? "sched-vm$2-vcpu$3-id$id-bg.dat" : ($5 == 1 ? "sched-vm$2-vcpu$3-id$id-fg.dat" : "sched-vm$2-vcpu$3-id$id.dat");
                open FD, ">>$fn";
                printf FD "%d %.2lf\n", $time_offset_ms, $5 == 2 ? $4 : ($5 == 1 ? $4 + ($shift_y*2) : $4 + $shift_y);
                close FD;

                $last_time_offset_ms{$2}{$3} = $time_offset_ms;

                $max_vcpu_id{$2} = $3 if !defined($max_vcpu_id{$2}) || $3 > $max_vcpu_id{$2};
                $max_time_offset{$2}{$id} = $time_offset_ms if !defined($max_time_offset{$2}{$id}) || $time_offset_ms > $max_time_offset{$2}{$id};
        }
        elsif (/(\d+) GD (\d+) (\d+) (\d+) [0-9a-f]{5} (\d+)/) {
                #$start_time_ms{$2} = $1/1000 if !defined($start_time_ms{$2}) || !$start_time_ms{$2};
                $time_ms = $1/1000;
                $time_offset_ms = int($time_ms - $start_time_ms{$2});
                $last_sched_time_ms = $last_time_offset_ms{$2}{$3}; 

                if (defined($last_sched_time_ms) && $last_sched_time_ms != 0 && $time_offset_ms > $last_sched_time_ms) {
                        $fn = $5 == 2 ? "sched-vm$2-vcpu$3-id$id-bg.dat" : ($5 == 1 ? "sched-vm$2-vcpu$3-id$id-fg.dat" : "sched-vm$2-vcpu$3-id$id.dat");
                        open FD, ">>$fn";
                        foreach $t (($last_sched_time_ms + 1) .. $time_offset_ms) {
                                printf FD "%d %.2lf\n", $t, $5 == 2 ? $4 : ($5 == 1 ? $4 + ($shift_y*2) : $4 + $shift_y);
                                #print "debug: $fn:\t $t $4\n";
                        }
                        close FD;
                }
        }
        elsif (/(\d+) VD (\d+) (\d+) \d+ 1/) {          # waiting on rq
                $time_ms = $1/1000;
                $last_depart_offset_ms{$2}{$3} = int($time_ms - $start_time_ms{$2});
        }
        elsif (/(\d+) VA (\d+) (\d+) (\d+)/) {
                $time_ms = $1/1000;
                $time_offset_ms = int($time_ms - $start_time_ms{$2});
                $last_depart_time_ms = $last_depart_offset_ms{$2}{$3};

                if (defined($last_depart_time_ms) && $last_depart_time_ms != 0 && $time_offset_ms >= $last_depart_time_ms) {
                        $fn = "sched-vm$2-vcpu$3-id$id-wait.dat";
                        open FD, ">>$fn";
                        foreach $t ($last_depart_time_ms .. $time_offset_ms) {
                                printf FD "%d %.2lf\n", $t, $4 - $shift_y;
                                #print "debug: $fn:\t $t $4\n";
                        }
                        close FD;
                }
                $last_depart_offset_ms{$2}{$3} = 0;

        }
        elsif (/(\d+) UI (\d+) (\d+) (\d+)/) {
                if (($3 == 0 && $4 == 28) || $3 == 3) {
                        $profile_id{$2}++;
                        $start_time_ms{$2} = $1 / 1000;
                }
        }
}

$pltstr = '
set terminal postscript eps enhanced color
set terminal post "Times-Roman" 10
#set key outside horizontal
set ytic 1
set grid x
set grid y
set xlab "Time (msec)"
set ylab "PCPU ID"
';
$size_x = 1.4;
$h = 0.5;
$ps = 0.4;
foreach $vm_id (keys %profile_id) {
        $nr_vcpus = $max_vcpu_id{$vm_id} + 1;
        $total_h = $nr_vcpus * $h; 

        $max_y = $max_vcpu_id{$vm_id} + 0.3;
        $pltstr .= "set yran [-0.3:$max_y]\n";
        foreach $id ( 1 .. $profile_id{$vm_id} ) {
                $max_x = $max_time_offset{$vm_id}{$id} + 200;
                $pltstr .= "set xran [0:$max_x]\n";
                $pltstr .= "set output 'sched-vm$vm_id-id$id.eps'\n";
                $pltstr .= "set size $size_x,$total_h\n";
                $pltstr .= "set multiplot layout $nr_vcpus,1\n";

                $origin = $total_h;
                foreach $vcpu_id ( 0 .. $max_vcpu_id{$vm_id} ) {
                        $bg_fn = "sched-vm$vm_id-vcpu$vcpu_id-id$id-bg.dat";
                        $fg_fn = "sched-vm$vm_id-vcpu$vcpu_id-id$id-fg.dat";
                        $normal_fn = "sched-vm$vm_id-vcpu$vcpu_id-id$id.dat";
                        $wait_fn = "sched-vm$vm_id-vcpu$vcpu_id-id$id-wait.dat";

                        system( "echo 0 0 > $bg_fn" ) if ( ! -e $bg_fn );
                        system( "touch $fg_fn" ) if ( ! -e $fg_fn );
                        system( "touch $normal_fn" ) if ( ! -e $normal_fn );
                        system( "touch $wait_fn" ) if ( ! -e $wait_fn );

                        $origin -= $h;
                        $pltstr .= "set title 'VM$vm_id-VCPU$vcpu_id'\n";
                        $pltstr .= "set origin 0, $origin\n";
                        $pltstr .= "set size $size_x, $h\n";
                        $pltstr .= "plot '$bg_fn' u 1:2 t 'bg' pt 5 ps $ps lc 1, '$fg_fn' u 1:2 t 'fg' pt 5 ps $ps lc 3, '$normal_fn' u 1:2 t 'normal' pt 5 ps $ps lc 2, '$wait_fn' u 1:2 t 'wait' pt 5 ps $ps lc 7\n";
                }
                $pltstr .= "unset multiplot\n";
        }
}
open FD, ">.plt.tmp";
print FD $pltstr;
close FD;
system("gnuplot .plt.tmp 2> /dev/null");
system("rm -f sched-vm*.dat .plt.tmp");
system("rm -f .plt.tmp");
