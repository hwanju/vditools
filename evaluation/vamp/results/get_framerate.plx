#!/usr/bin/perl -w

# Simpson 1080p
my $total_frames = 3270;
my $orig_fps = 23.976024;
my $usec;

die "Usage: $0 <result file> [N: FRAMETIMEN (=1)]\n" unless @ARGV >= 1;
$res_fn = shift(@ARGV);
$frametime_idx = @ARGV ? shift(@ARGV) : 0;
$fps_fn = $res_fn;
$fps_fn =~ s/\.result$/\.fps/g;

$last_frame_str = `grep FRAMETIME $res_fn | tail -1`;
$last_frame_idx = $1 if ($last_frame_str =~ /FRAMETIME(\d+)/);
printf "last_frame_idx=$last_frame_idx valid_last_frame_idx=%d\n", $last_frame_idx - 2;
$last_frame_idx -= 2 if $last_frame_idx > 2;

# exceptional case: only consider the first three 
if ($frametime_idx == -1) {
	$frametime_idx = 0;
	$last_frame_idx = 3;
}

open FD, $res_fn or die "file open error: $res_fn\n";
while(<FD>) {
retry:
	if (/FRAMETIME(\d+)/) {
		$idx = $1;
		next if $frametime_idx && $frametime_idx != $idx;
		next if !$frametime_idx && $idx > $last_frame_idx;

		$sum = $sqsum = $n = 0;
		$usec = 1000000;
		undef($start_us);
		open FPS, ">$fps_fn.$idx";
		while(<FD>) {
			#goto retry unless (/^\d+$/);
			unless (/^\d+$/) {
				close FPS;
				#print "$idx: sum=$sum n=$n\n";
				$avg = $sum / $n;
				$sd = sqrt(($sqsum / $n) - ($avg*$avg));
				printf "FRAMETIME$idx: frames=$sum avg=%.3lf sd=%.3lf drop_rate=%.3lf\n", $avg, $sd, ($total_frames - $sum) * 100 / $total_frames;

				$total_sum += $sum;
				$total_sqsum += $sqsum;
				$total_n += $n;
				$nr_plays++;
				goto retry;
			}
			chomp;
			$curr_us = $_;
			$start_us = $curr_us unless defined($start_us);
			$progress = $curr_us - $start_us;
			if( $progress >= $usec ) {
				printf FPS "%.2lf\t$frame\n", $usec / 1000000;
				$sum += $frame;
				$sqsum += $frame * $frame;
				$n++;

				if ($progress - $usec >= 1000000) {
					do {
						$usec += 1000000;
						printf FPS "%.2lf\t0\n", $usec / 1000000;
						$n++;
					} while( $progress - $usec > 1000000 );
				}
				$frame = 0;
				$usec += 1000000;

=pod	# old code
				if( $progress - $usec < 1000000 ) {
					printf FPS "%.2lf\t$frame\n", $progress / 1000000;
				}
				else {
					printf FPS "%.2lf\t$frame\n", $usec / 1000000;
					do {
						$usec += 1000000;
						printf FPS "%.2lf\t0\n", $usec / 1000000;
					} while( $progress - $usec > 1000000 );
				}
=cut
			}
			$frame++;
		}
	}
}
print "total: sum=$total_sum total_n=$total_n\n";
$total_avg = $total_sum / $total_n;
$total_sd = sqrt(($total_sqsum / $total_n) - ($total_avg * $total_avg));
printf "Total: avg=%.3lf sd=%.3lf drop_rate=%.3lf\n", $total_avg, $total_sd, ($total_frames * $nr_plays - $total_sum) * 100 / ($total_frames * $nr_plays); 
=pod
$avg_fps = $displayed_frame / (($curr_us - $start_us) / 1000000);
$dropratio = ($orig_fps - $avg_fps) * 100 / $orig_fps;
$dropratio = 0 if $dropratio < 0;
printf "%.2lf\t%.2lf\n", $avg_fps, $dropratio;
=cut
