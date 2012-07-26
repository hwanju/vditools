#!/usr/bin/perl -w

die "Usage: $0 <debug log fn> <vcpu_id> <pcpu_id>\n" unless @ARGV == 3;
$fn = shift(@ARGV);
$vcpu_id = shift(@ARGV);
$pcpu_id = shift(@ARGV);

open FD, $fn or die "file open erorr:$fn\n";

while(<FD>) {
        if (/d\d+-v${vcpu_id}p${pcpu_id}/) {
                printf( "$_" );
        }
        elsif (/QI d\d+-v.{1}p${pcpu_id}/) {
                printf( "$_" );
        }
        elsif (/WPE/) {
                printf( "$_" );
        }
        elsif (/PN p$pcpu_id/) {
                printf( "$_" );
        }
}
