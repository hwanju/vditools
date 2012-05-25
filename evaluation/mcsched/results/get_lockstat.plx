#!/usr/bin/perl -w

$nr_top = 10;
die "$0 <mode>\n" unless @ARGV;
$mode = shift(@ARGV);
@res_files = `ls *\@$mode.result*`;
foreach $res_file (@res_files) {
    open FD, $res_file;
    $i = 0;
    print "\n$res_file";
    while(<FD>) {
        if (/Guest1:/) {
            while(<FD>) {
                if (/lock_stat/) {
                    $label = <FD>;
                    $label = <FD>;
                    $label =~ s/^\s+class\s+//g;
                    $label =~ s/\s+/\t/g;
                    print "$label\n";
                    while(<FD>) {
                        if ( /:/ ) {
                            s/^\s+//g;
                            s/\s+/\t/g;
                            print "$_\n";
                            goto finish if ++$i >= $nr_top;
                        }
                    }
                }
            }
        }
    }
finish:
    close FD;
}
