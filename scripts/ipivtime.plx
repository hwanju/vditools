#!/usr/bin/perl -w

$max = 0;
$min = 10000000000;
@vdiffs=`grep "ILD -1 -1" vcpusched.log | grep picked | awk '{print \$8}' | sed 's/c2=//g' | sort -n`;
foreach $vdiff (@vdiffs) {
        $total += $vdiff;
        $n++;
        $max = $vdiff if $vdiff > $max;
        $min = $vdiff if $vdiff < $min;
}
printf "avg=%.2lf min=%d max=%d med=%d\n", $total / $n, $min, $max, $vdiffs[$n/2];
