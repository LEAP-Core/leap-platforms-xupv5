/* Author: Rimas Avizienis
 *         Parallel Computing Laboratory
 *         Electrical Engineering and Computer Sciences
 *         University of California, Berkeley
 *
 * Copyright (c) 2009, The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the University of California, Berkeley nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS ''AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE REGENTS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "ramp_fifo.h"

#include <sys/socket.h>
#include <net/ethernet.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <sys/fcntl.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
					
/**
 * ramp_chan_init - opens the network channel and initializes the channel
 * structure
 * @chanp: ramp channel struct
 * @eth_device: name of the ethernet device to use
 *
 * ramp_chan_init returns 0 if it successfully opens the channel,
 * returns -1 on failure;
 **/

int ramp_chan_init(ramp_chan_t *chanp, const char *eth_device)
{
	int sock, ret, flags, optval;
	ssize_t len;
	struct ifreq ifr;
	uint8_t buf[MAX_FRAME_SIZE];
	uint8_t broadcast_addr[] = { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };
	ramp_packet_t *rx_packet;
	socklen_t optlen;

	rx_packet = (ramp_packet_t *) buf;	

	sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
	if (sock == -1) {
		perror("socket:");
		return -1;
	}

	optlen = sizeof(const void *);
	optval = RCV_SOCKBUFLEN;

	ret = setsockopt(sock, SOL_SOCKET, SO_RCVBUF, &optval, optlen);
	if (ret == -1) {
		perror("setsockopt");
		goto exit;
	}

	ret = getsockopt(sock, SOL_SOCKET, SO_RCVBUF, &optval, &optlen);
	if (ret == -1) {
		perror("getsockopt");
		goto exit;
	}

	if (optval != RCV_SOCKBUFLEN*2) {
		fprintf(stderr, "Unable to set receive socket buffer size to %d\n", RCV_SOCKBUFLEN);
		fprintf(stderr, "Increase kernel parameter net.core.rmem_max\n");
		goto exit;
	}

	// get MAC address of local ethernet device
	strcpy(ifr.ifr_name, eth_device);
	ret = ioctl(sock, SIOCGIFHWADDR, (char *)&ifr);
	if (ret < 0) {
		perror("ioctl");
	        goto exit;
	}

	memset(&chanp->myaddr, '\0', sizeof(struct sockaddr_ll));
	chanp->myaddr.sll_ifindex = if_nametoindex(eth_device);
	chanp->myaddr.sll_family = AF_PACKET;
   
	ret = bind(sock, (struct sockaddr *)&chanp->myaddr, sizeof(struct sockaddr_ll));
	if (ret == -1) {
		perror("bind:");
		goto exit;
	}

	// make socket non-blocking
	flags = fcntl(sock, F_GETFL,0);
	if (flags == -1) flags = 0;

	ret = fcntl(sock, F_SETFL, flags | O_NONBLOCK);
	if (ret == -1) {
		perror("fcntl");
		goto exit;
	}

	// construct a ping packet to test for the presence of a RAMP board
	memcpy(&chanp->packet.dest_mac_addr, broadcast_addr, MAC_ADDR_LEN);
	memcpy(&chanp->packet.src_mac_addr, &ifr.ifr_ifru.ifru_hwaddr.sa_data, MAC_ADDR_LEN);
	chanp->packet.ether_type = htons(RAMP_ETHERTYPE);
	chanp->packet.packet_type = htons(RAMP_PINGTYPE);

	// send a ping packet and listen for a response
	// if we get a response, record the source MAC address of the packet
	len = sendto(sock, &chanp->packet, PING_PACKET_LEN, 0, (struct sockaddr *) &chanp->myaddr, sizeof(struct sockaddr_ll));
	if (len == -1) {
		perror("sendto");
		goto exit;
	}

	usleep(200000);
	len = 0;
	
	while (len != -1) {
		len = read(sock, buf, MAX_FRAME_SIZE);
		if (len == RAMP_PACKET_LEN) {
			if (rx_packet->ether_type == ntohs(RAMP_ETHERTYPE) &&
			    rx_packet->packet_type == ntohs(RAMP_PINGTYPE)) {
				memcpy(&chanp->packet.dest_mac_addr, &rx_packet->src_mac_addr, MAC_ADDR_LEN);
				ret = 1;
			}
		}
	}
		
	if (ret == 0) {
		fprintf(stderr, "Couldn't detect a remote host on the link.\n");
		goto exit;
	}	

	// make socket blocking
	ret = fcntl(sock, F_SETFL, flags & ~O_NONBLOCK);
	if (ret == -1) {
		perror("fcntl");
		goto exit;
	}

	pthread_mutex_init(&chanp->tx_credit_mutex, NULL);
	pthread_cond_init(&chanp->tx_credit_cond, NULL);
	chanp->rx_buffer.head = 0;
	chanp->rx_buffer.tail = 0;
	chanp->tx_credit = INITIAL_TX_CREDIT;
	chanp->socket = sock;
	
	// spawn thread to receive and process packets
	ret = pthread_create(&chanp->rx_thread, NULL, ramp_rx_thread, (void *) chanp);
	
	if (ret != 0) {
		perror("pthread_create");
		goto exit;
	}

	return 0;

exit:
	close(sock);
	return -1;
}

/**
 * ramp_chan_init - closes the network channel
 * @chanp: ramp channel channel struct
 *
 * ramp_chan_init returns 0 if it successfully closes the channel,
 * returns -1 on failure;
 **/

int ramp_chan_close(ramp_chan_t *chanp)
{
	if (chanp == NULL)
		return -1;
	else {
		close(chanp->socket);
		pthread_cancel(chanp->rx_thread);
		pthread_join(chanp->rx_thread, 0);
		pthread_mutex_destroy(&chanp->tx_credit_mutex);
		pthread_cond_destroy(&chanp->tx_credit_cond);
	}
	return 0;
}

/**
 * ramp_chan_read8B - non blocking read of 8 bytes of data from the network channel
 * @chanp: ramp channel struct pointer
 * @bufp: pointer to buffer where data will be written
 *
 * ramp_chan_read8B returns 8 if it successfully reads 8 bytes of data,
 * returns 0 if the receive queue is empty, returns -1 if the channel is invalid.
 * 
 **/

int ramp_chan_read8B(ramp_chan_t *chanp, void *bufp)
{
	if (chanp == NULL)
		return -1;
	
	if (ramp_fifo_deq(bufp, chanp)) {
		if (ramp_send_rx_token(chanp) != 0)
			fprintf(stderr, "Couldn't send rx credit token!\n");
		return 8;
	} else
		return 0;
}

/**
 * ramp_chan_write8B - blocking write of 8 bytes of data to the network channel
 * @chanp: ramp channel struct pointer
 * @bufp: pointer to buffer from which data will be read
 *
 * ramp_chan_write8B returns 8 if it data is successfully written,
 * returns -1 on an error.
 * 
 **/

int ramp_chan_write8B(ramp_chan_t *chanp, const void *bufp)
{
	ssize_t len;

	if (chanp == NULL)
		return -1;

	if (chanp->tx_credit == 0) {
		pthread_mutex_lock(&chanp->tx_credit_mutex);
		while (chanp->tx_credit == 0)
			pthread_cond_wait(&chanp->tx_credit_cond, &chanp->tx_credit_mutex);
		pthread_mutex_unlock(&chanp->tx_credit_mutex);
	}

	chanp->packet.packet_type = htons(RAMP_DATATYPE);
	memcpy(&chanp->packet.data, bufp, 8);

	pthread_mutex_lock(&chanp->tx_credit_mutex);
	chanp->tx_credit--;
	pthread_mutex_unlock(&chanp->tx_credit_mutex);
	
	len = sendto(chanp->socket, &chanp->packet, DATA_PACKET_LEN, 0, (struct sockaddr *) &chanp->myaddr, sizeof(struct sockaddr_ll));
	if (len == -1) {
		perror("sendto");
		return -1;
	}

	return 8;
}

int ramp_send_rx_token(ramp_chan_t *chanp)
{
	ssize_t len;

	chanp->packet.packet_type = htons(RAMP_TOKENTYPE);

	len = sendto(chanp->socket, &chanp->packet, TOKEN_PACKET_LEN, 0, (struct sockaddr *) &chanp->myaddr, sizeof(struct sockaddr_ll));
	if (len == -1) {
		perror("sendto");
		return -1;
	}
	return 0;
}

int ramp_fifo_enq(uint64_t val, ramp_chan_t *chanp)
{
	int ret = 0;
	
	if ((chanp->rx_buffer.head+1) % (RX_BUFFER_SIZE+1) == chanp->rx_buffer.tail) 
		ret = -1;
	else {
		chanp->rx_buffer.buf[chanp->rx_buffer.head] = val;
		chanp->rx_buffer.head = (chanp->rx_buffer.head+1) % (RX_BUFFER_SIZE+1);
	}
	return ret;
}

int ramp_fifo_deq(uint64_t *val, ramp_chan_t *chanp)
{
	int ret;
	
	if (chanp->rx_buffer.tail == chanp->rx_buffer.head)
		ret = 0;
	else {
		*val = chanp->rx_buffer.buf[chanp->rx_buffer.tail];
		chanp->rx_buffer.tail = (chanp->rx_buffer.tail + 1) % (RX_BUFFER_SIZE+1);
		ret = 1;
	}
	return ret;
}

void *ramp_rx_thread(void *arg)
{
	ramp_chan_t *chanp = (ramp_chan_t *) arg;
	ssize_t len = 0;
	uint8_t buf[MAX_FRAME_SIZE];
	ramp_packet_t *rx_packet;

	rx_packet = (ramp_packet_t *) buf;
	
	while (len != -1) {
		len = read(chanp->socket, buf, MAX_FRAME_SIZE);
		if (len == RAMP_PACKET_LEN && 
		   (memcmp(&chanp->packet.src_mac_addr, &rx_packet->dest_mac_addr, MAC_ADDR_LEN) == 0) &&
		    ntohs(rx_packet->ether_type) == RAMP_ETHERTYPE) {
			switch (ntohs(rx_packet->packet_type)) {
				case RAMP_TOKENTYPE: 
					if (chanp->tx_credit == INITIAL_TX_CREDIT)
						fprintf(stderr, "TX credit token overflow!\n");
					else {
						pthread_mutex_lock(&chanp->tx_credit_mutex);
						if (chanp->tx_credit == 0) {
							chanp->tx_credit++;
							pthread_cond_signal(&chanp->tx_credit_cond);
						} else
							chanp->tx_credit++;
						pthread_mutex_unlock(&chanp->tx_credit_mutex);
					}														
					break;
				case RAMP_DATATYPE: 
					if (ramp_fifo_enq(rx_packet->data, chanp) != 0) 
						fprintf(stderr, "RX buffer overflow!\n");
					break;
			}
		}
	}
	pthread_exit(NULL);
}
