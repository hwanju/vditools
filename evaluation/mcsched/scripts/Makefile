NR_ITER := 3
THINK_TIME_MS := 1000
all:
	./gen_prolog.plx
	./gen_launch_script.plx $(NR_ITER) $(THINK_TIME_MS)
	make -C ubuntu/parsec
	make -C ubuntu/npb
clean:
	./gen_prolog.plx -c
	./gen_launch_script.plx -c
	make -C ubuntu/parsec clean
	make -C ubuntu/npb clean
