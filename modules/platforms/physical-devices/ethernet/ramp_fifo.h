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

#ifndef _RAMP_FIFO_H
#define _RAMP_FIFO_H

#include <netpacket/packet.h>
#include <stdint.h>
#include <pthread.h>

#define INITIAL_TX_CREDIT 	512	// size of receive buffer on FPGA side
#define	RX_BUFFER_SIZE 		512	// size of local receive buffer (must be set on FPGA too!)
#define RAMP_ETHERTYPE 		0x8888	// ethertype of packets sent to/from FPGA
#define RAMP_DATATYPE 		0x0008	// indicates the packet contains 8 bytes of data
#define RAMP_TOKENTYPE 		0xFFFF	// indicates the packet is a credit token (for flow control)
#define RAMP_PINGTYPE 		0xFFFE	// indicates the packet is a ping request or response
#define MAX_FRAME_SIZE 		1518	// maximum size of an ethernet frame (assuming no jumbo frames)
#define RAMP_PACKET_LEN 	60	// the size of all incoming packets we are interested in
#define MAC_ADDR_LEN 		6	// MAC address length in bytes
#define TOKEN_PACKET_LEN 	16	// length of a token packet
#define PING_PACKET_LEN 	16	// length of a ping packet
#define DATA_PACKET_LEN 	24	// length of a data packet
#define RCV_SOCKBUFLEN		262144	// length of the socket receive buffer to avoid dropped packets

typedef struct {
	uint64_t buf[RX_BUFFER_SIZE+1];
	uint32_t head;
	uint32_t tail;
} ramp_rxbuf_t;

typedef struct {
	uint8_t dest_mac_addr[MAC_ADDR_LEN];
	uint8_t src_mac_addr[MAC_ADDR_LEN];
	uint16_t ether_type;
	uint16_t packet_type;
	uint64_t data;
} ramp_packet_t;

typedef struct {
	int socket;
	uint32_t tx_credit;
	struct sockaddr_ll myaddr;
	ramp_packet_t packet;	
	pthread_cond_t tx_credit_cond;
	pthread_mutex_t tx_credit_mutex;
	ramp_rxbuf_t rx_buffer;
	pthread_t rx_thread;
} ramp_chan_t;


int ramp_chan_init(ramp_chan_t *chanp, const char *eth_device);
int ramp_chan_close(ramp_chan_t *chanp);
int ramp_chan_read8B(ramp_chan_t *chanp, void *bufp);
int ramp_chan_write8B(ramp_chan_t *chanp, const void *bufp);

void *ramp_rx_thread(void *arg);
int ramp_send_rx_token(ramp_chan_t *chanp);
int ramp_fifo_enq(uint64_t val, ramp_chan_t *chanp);
int ramp_fifo_deq(uint64_t *val, ramp_chan_t *chanp);

#endif
