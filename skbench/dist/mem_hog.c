#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>

#define MB              (1024*1024)
#define DEFAULT_MEM     (128)
#define DEFAULT_CHUNK   (5)

int main(int argc, char **argv) 
{
    int i, j;
    int mem_size = DEFAULT_MEM;
    int alloc_chunk_size = DEFAULT_CHUNK;
    int buf_size;
    char **buffer;
	srand(time(NULL));

    if( argc > 1 ) {
        if( !strcmp( argv[1], "-h" ) || !strcmp( argv[1], "--help" ) ) {
            fprintf( stderr, "Usage: %s [mem_size_in_MB(default=128)] [allocated MB(default=5)]\n", argv[0] );
            return -1;
        }
        mem_size = atoi(argv[1]);
    }
    if( argc > 2 ) {
        alloc_chunk_size = atoi(argv[2]);
    }
    buf_size = (mem_size/alloc_chunk_size);
    fprintf( stderr,"malloc start with the unit of %d MB for total %d MB (bufptr size=%d)\n", alloc_chunk_size, mem_size, buf_size );
    if( ( buffer = (char **)malloc( buf_size * sizeof(char *) ) ) == NULL ) {
        fprintf( stderr, "buffer malloc error\n" );
        return -1;
    }
    mlockall(MCL_FUTURE);
    for( i=0 ; i < buf_size ; i++ ) {
        buffer[i] = (char *)malloc(alloc_chunk_size * MB);
        if( buffer[i] ) {
            fprintf( stderr,"%d / %d MB allocated\n", (i+1) * alloc_chunk_size, mem_size );
        }
        else {
            fprintf( stderr, "data allocation error\n" );
        }
        
		for(j=0 ; j<alloc_chunk_size*MB ; j++){
			buffer[i][j] = rand() % 128;
		}
    }

    for( i=0 ; i < buf_size ; i++ ) {
        free( buffer[i] );
    }

    return 0;
}
