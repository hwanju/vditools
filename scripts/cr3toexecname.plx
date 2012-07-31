#!/usr/bin/perl -w

$default_procinfo_fn = "procinfo.txt";
die "Usage: $0 <log file> [procinfo file (default=$default_procinfo_fn)]\n" unless @ARGV >= 1;
$logfn = shift(@ARGV);
$procfn = @ARGV ? shift(@ARGV) : $default_procinfo_fn;

open FD, "$procfn" or die "file open error: $procfn\n";
while(<FD>) {
        if( /DirBase: ([0-9a-f]{8})/ ) {
                $cr3 = $1;
                $next_line = <FD>;
                if( $next_line =~ /Image: (\w+)/ ) {
                        $execname = $1;
                        chomp($execname);
                        $cr3map{$cr3} = $execname;
                }
        }
}
foreach $cr3 (keys %cr3map) {
        print "$cr3     $cr3map{$cr3}\n";
}

close FD;

open FD, "$logfn" or die "file open error: $logfn\n";
open OFD, ">$logfn.tmp"; 
while(<FD>) {
        #if( /T ([0-9a-f]{8})/ or /VS \d+ ([0-9a-f]{8})/ ) {
        if (/^plot/ ) {
                @tmp = split( /,/ );
                foreach $p (@tmp) {
                        if( $p =~ /\'([0-9a-f]+)\/[A-Z]\'/) {
                                $cr3 = $1;
                                $full_cr3 = $cr3 . "000";
                                if( defined($cr3map{$full_cr3}) ) {
                                        $p =~ s/$cr3/$cr3map{$full_cr3}/;
                                }
                                print OFD ", " unless $p =~ /^plot/;
                                print OFD $p;
                        }
                }
                print OFD "\n";
        }
        elsif (/^background:/ || /^interactive:/ || /^ambiguous:/) {
                @tmp = split( / / );
                foreach $p (@tmp) {
                        if( $p =~ /([0-9a-f]+)/) {
                                $cr3 = $1;
                                $full_cr3 = $cr3 . "000";
                                if( defined($cr3map{$full_cr3}) ) {
                                        $p =~ s/$cr3/$cr3map{$full_cr3}($cr3)/g;
                                }
                                print OFD "$p ";
                        }
                }
                print OFD "\n";
        }
        elsif (/GA/ || /GD/) {
                if( / ([0-9a-f]{5}) \d$/) {
                        $cr3 = $1;
                        $full_cr3 = $cr3 . "000";
                        if( defined($cr3map{$full_cr3}) ) {
                                s/$cr3/$cr3map{$full_cr3}($cr3)/g;
                        }
                }
                print OFD "$_";
        }
        else {
                print OFD $_;
        }
}
close OFD;
close FD;
unlink( $logfn );
rename( "$logfn.tmp", $logfn );

