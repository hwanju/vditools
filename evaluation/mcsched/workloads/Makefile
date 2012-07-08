all:
	./gen_homo_workloads.sh 1
	./gen_homo_workloads.sh 2
	./gen_hetero_workloads.sh 1 1 streamcluster
	./gen_hetero_workloads.sh 1 1 facesim 
	./gen_hetero_workloads.sh 1 1 freqmine
	./gen_hetero_workloads.sh 1 2 streamcluster
	./gen_hetero_workloads.sh 1 2 x264
	./gen_hetero_workloads.sh 1 4 x264
	./gen_hetero_workloads.sh 1 7 x264
	./gen_hetero_workloads.sh 2 4 x264
clean: 
	rm -f *@*
