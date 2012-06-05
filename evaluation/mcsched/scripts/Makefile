all:
	./gen_prolog.plx
	make -C ubuntu/parsec
	make -C ubuntu/interactive

clean:
	./gen_prolog.plx -c
	make -C ubuntu/parsec clean
	make -C ubuntu/interactive clean
