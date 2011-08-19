#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>

#define MB              (1024*1024)
#define DEFAULT_MEM     (128)
#define DEFAULT_CHUNK   (5)
#define DEFAULT_SLEEP (1)

int main(int argc, char **argv) 
{
    int i, j;
    int mem_size = DEFAULT_MEM;
    int alloc_chunk_size = DEFAULT_CHUNK;
    int buf_size;
    long **buffer;
	unsigned int sleep_time;
	unsigned long chunk_size;

	srand(time(NULL));

    if( argc > 1 ) {
        if( !strcmp( argv[1], "-h" ) || !strcmp( argv[1], "--help" ) ) {
            fprintf( stderr, "Usage: %s [mem_size_in_MB(default=128)] [allocated chunk size MB(default=5)]\
							[sleep time in secs(default=1)]\n", argv[0] );
            return -1;
        }
        mem_size = atoi(argv[1]);
    }
    if( argc > 2 ) {
        alloc_chunk_size = atoi(argv[2]);
    }
	if( argc > 3 ) {
		sleep_time = atoi(argv[3]);
	}
    buf_size = (mem_size/alloc_chunk_size);
	chunk_size = alloc_chunk_size*MB

    fprintf( stderr,"malloc start with the unit of %d MB for total %d MB (bufptr size=%d)\n", alloc_chunk_size, mem_size, buf_size );
    if( ( buffer = (long **)malloc( buf_size * sizeof(long *) ) ) == NULL ) {
        fprintf( stderr, "buffer malloc error\n" );
        return -1;
    }
    mlockall(MCL_FUTURE);

    for( i=0 ; i < buf_size ; i++ ) {
   	    buffer[i] = (long *)malloc(chunk_size);
    	if( buffer[i] ) {
       		fprintf( stderr,"%d / %d MB allocated\n", (i+1) * alloc_chunk_size, mem_size );
       	}
       	else {
        	fprintf( stderr, "data allocation error\n" );
			return -1;
        }
	}
	
	alloc_size /= sizeof(long);
	while(1){
		printf("mem write start\n");
		for(j=0 ; j<chunk_size ; j++){
			buffer[i][j] = rand();
		}
		printf("mem write end\n");
		sleep(sleep_time);
	}
    	
	for( i=0 ; i < buf_size ; i++ ) {
        free( buffer[i] );
    }

    return 0;
}
