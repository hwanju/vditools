all:
	./gen_parsecs.sh 1
	./gen_parsec_corun.sh 1 1 cpubound
	./gen_parsec_corun.sh 1 1 streamcluster
	./gen_parsec_corun.sh 1 4 cpuboundx1
clean: 
	rm -f *@*
