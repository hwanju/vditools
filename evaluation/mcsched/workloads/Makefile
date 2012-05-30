all:
	./gen_homo_workloads.sh 1
	./gen_hetero_workloads.sh 1 1 cpubound
	./gen_hetero_workloads.sh 1 1 streamcluster
	./gen_hetero_workloads.sh 1 4 cpuboundx1
clean: 
	rm -f *@*
