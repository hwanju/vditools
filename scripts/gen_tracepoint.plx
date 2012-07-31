#!/usr/bin/perl -w

$proto = "TP_PROTO(";
$args  = "TP_ARGS(";
$struct = "TP_STRUCT__entry(\n";
$assign = "TP_fast_assign(\n";
$printk = "TP_printk(";
$printk_args = "\t";
$first = 1;
%fmt = (
        "int" => "%d",
        "long" => "%ld",
        "s64" => "%lld",
        "long long" => "%lld",
        "unsigned long" => "%lu",
        "unsigned int" => "%u",
        "unsigned long long" => "%llu",
        "u64" => "%llu",
        "u32" => "%u",
);
while(<>) {
        if( /(.+)\s+(\w+)/ ) {
                $type = $1;
                $var  = $2;
                $ifs1 = $first ? "" : ", ";
                $ifs2 = $first ? "\"" : " ";
                $first = 0;

                $proto .= "$ifs1$type $var";
                $args  .= "$ifs1$var";
                $struct .= "\t__field( $type,\t$var)\n";
                $assign .= "\t__entry->$var\t= $var;\n";
                $printk .= "$ifs2$var=$fmt{$type}";
                $printk_args .= "${ifs1}__entry->$var";
        }
}

print "$proto),\n\n";
print "$args),\n\n";
print "$struct),\n\n";
print "$assign),\n\n";
print "$printk\",\n";
print "$printk_args)\n";


