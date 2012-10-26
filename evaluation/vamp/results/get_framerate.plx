#!/usr/bin/perl -w

my $orig_fps = 23.976024;
my $usec = 1000000;

die "Usage: $0 <result file> [N: FRAMETIMEN (=1)]\n" unless @ARGV >= 1;
$res_fn = shift(@ARGV);
$frametime_idx = @ARGV ? shift(@ARGV) : 1;
$fps_fn = $res_fn;
$fps_fn =~ s/\.result$/\.fps/g;
open FD, $res_fn or die "file open error: $res_fn\n";
open FPS, ">$fps_fn";

while(<FD>) {
	if (/FRAMETIME$frametime_idx/) {
		while(<FD>) {
			last unless (/^\d+$/);
			chomp;
			$curr_us = $_;
			$start_us = $curr_us unless defined($start_us);
			$progress = $curr_us - $start_us;
			if( $progress >= $usec ) {

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
				#$sum += $frame;
				#$sqsum += $frame * $frame;
				$frame = 0;
				$usec += 1000000;
			}
			$frame++;
			$displayed_frame++;
		}
	}
}
$avg_fps = $displayed_frame / (($curr_us - $start_us) / 1000000);
$dropratio = ($orig_fps - $avg_fps) * 100 / $orig_fps;
$dropratio = 0 if $dropratio < 0;
printf "%.2lf\t%.2lf\n", $avg_fps, $dropratio;
