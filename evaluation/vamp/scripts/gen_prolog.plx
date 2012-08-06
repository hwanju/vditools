#!/usr/bin/perl -w

$templ = @ARGV ? shift(@ARGV) : "prolog_template";
$clean = $templ eq "-c" ? 1 : 0;

%mode_to_id = (
	"baseline"		=> 0,
);
@submodes = qw( orig );
foreach $m (keys %mode_to_id) {
	`rm -f ${m}_prolog*` if $clean;
	foreach $sm (@submodes) {
		$prolog = "${m}_prolog.$sm";
		if ($clean) {
			unlink($prolog);
			next;
		}
		`rm -f $prolog.tmp*`;
                `cat $templ > $prolog`;
		`cat ${sm}_script >> $prolog` if (-e "${sm}_script"); 
	}
}
`./set_mode.sh orig` unless $clean;
