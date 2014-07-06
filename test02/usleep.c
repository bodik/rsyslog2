//gcc usleep.c -o usleep
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv) {
	long i = 500;
	if (argc == 2) {
		i = atol(argv[1]);
//		printf("%ld\n", i);
	}
	usleep(i);
	exit(0);
}
