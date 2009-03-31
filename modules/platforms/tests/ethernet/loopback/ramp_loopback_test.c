#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "ramp_fifo.h"

int main(int argc, char **argv)
{
	ramp_chan_t channel;
	int ret;
	uint64_t i, j;

	if (argc != 2) {
		printf("Usage: %s <ethernet device>, i.e. %s eth0\n", argv[0], argv[0]);
		return -1;
	}

	if (ramp_chan_init(&channel, argv[1]) != 0) {
		fprintf(stderr, "Error initializing channel\n");
		return -1;
	}

	printf("About to write 1536 values to target\n");

	for (i=0;i<1536;i++) {
		ret = ramp_chan_write8B(&channel, &i);
		if (ret != 8) 
			fprintf(stderr, "Couldn't write to channel!\n");
	}
	
	sleep(1);

	printf("About to read back values\n");

	for (i=0;i<1536;i++) {
		ret = 0;
		while (ret != 8) {
			ret = ramp_chan_read8B(&channel, &j);
			if (ret == -1)
				fprintf(stderr, "Error reading from channel!\n");
		}
		if (i != j) {
			fprintf(stderr, "Error: incorrect value read from FIFO! %ld != %ld\n", i, j);
			break;
		}
	} 

	sleep(1);

	if (i == 1536)
		printf("Test succeeded\n");

	ramp_chan_close(&channel);
	return 0;
}
