all:
	./gen_homo_workloads.sh 1	# solorun
	./gen_hetero_workloads.sh 1 1 streamcluster	# par + par
	./gen_hetero_workloads.sh 1 1 freqmine		# par + par & for user-level coordination
	./gen_hetero_workloads.sh 1 1 dedup		# par + par & for preemption delay sensitivity
	./gen_hetero_workloads.sh 1 1 facesim		# par + par & for user-level coordination
	./gen_hetero_workloads.sh 1 2 streamcluster	# par + heavy par
	./gen_hetero_workloads.sh 1 2 x264	# seq + par
	./gen_hetero_workloads.sh 1 4 x264	# seq + par
	./gen_homo_workloads.sh 3		# for urgent tslice sensitivity
	./gen_hetero_workloads.sh 1 2 facesim	# for urgent allowance sensitivity
clean: 
	rm -f *@*
