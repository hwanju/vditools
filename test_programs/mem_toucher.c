#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>

#define LENGTH 2621440

int m = 0;

void handler (void);

void handler (void)
{
	puts("alarm called");
	m++;
	signal(SIGALRM, handler);
	alarm(10);
}

int main(void)
{	
	int *parr[10];

	unsigned long i,j;

	for(i=0 ; i<10 ; i++)
		parr[i] = (int*) malloc(sizeof(int)*LENGTH);
		
	signal(SIGALRM, handler);
	alarm(10);

	while (1) {
		printf("i=%lu, j=%lu, m=%d\n", i, j, m);
		if(m == 9)
			break;
		for(i=0 ; i <= m; i++) {
			for(j=0 ; j < LENGTH ; j++) {
				parr[i][j] = 1;
			}
		}
	}

	return 0;
}
