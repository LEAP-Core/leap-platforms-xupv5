//==============================================================================
//	Section:	License
//==============================================================================
//	Copyright (c) 2005-2009, Regents of the University of California
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without modification,
//	are permitted provided that the following conditions are met:
//
//		- Redistributions of source code must retain the above copyright notice,
//			this list of conditions and the following disclaimer.
//		- Redistributions in binary form must reproduce the above copyright
//			notice, this list of conditions and the following disclaimer
//			in the documentation and/or other materials provided with the
//			distribution.
//		- Neither the name of the University of California, Berkeley nor the
//			names of its contributors may be used to endorse or promote
//			products derived from this software without specific prior
//			written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//	ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//==============================================================================

//------------------------------------------------------------------------------
//	Module:		EthernetFIFORx
//	Description:	This module implements the datapath & control for the receive side
//			of the EthernetFIFO interface
//			
//	Parameters:	MACAddress:		The hardware MAC address assigned to this device
//
//	Author:		Rimas Avizienis
//	Version:	
//------------------------------------------------------------------------------

module EthernetFIFORx (
			//------------------------------------------------------------------
			//	System Inputs
			//------------------------------------------------------------------
			clk,
			reset,
			//------------------------------------------------------------------
			//	Interface to Ethernet MAC RX path
			//------------------------------------------------------------------			
			rxd,
			rxdv,
			rx_good_frame,
			rx_bad_frame,
			//------------------------------------------------------------------
			//	Interface to RX FIFO
			//------------------------------------------------------------------	
			rxfifo_full,
			rxfifo_we,
			rx_dout,
			//------------------------------------------------------------------
			//	Interface to EthernetFIFOTx module
			//------------------------------------------------------------------
			tx_send_ack,
			tx_credit_incr,	
			rx_source_mac,
			//------------------------------------------------------------------
			//	Status output
			//------------------------------------------------------------------							
			rx_error
	);

	//--------------------------------------------------------------------------
	//	Parameters
	//--------------------------------------------------------------------------

	parameter 		MACAddress = 	48'h112233445566;

	//--------------------------------------------------------------------------
	//	System inputs
	//--------------------------------------------------------------------------
	input			clk;
	input			reset;

	//--------------------------------------------------------------------------
	//	Interface to Ethernet MAC RX path
	//--------------------------------------------------------------------------
	input [7:0]		rxd; 		// RX Data from MAC
	input			rxdv;		// RX Data Valid signal
	input 			rx_good_frame;	// high for 1 cycle when a received packet passes CRC check
	input   		rx_bad_frame;  	// high for 1 cycle when a received packet fails CRC check

	//--------------------------------------------------------------------------
	//	Interface to RX FIFO
	//--------------------------------------------------------------------------
	input			rxfifo_full;
	output 			rxfifo_we;	// write enable to RX FIFO
	output [63:0]		rx_dout;	// data output to RX FIFO
	output 			tx_send_ack;	// high for 2 cycles to signal TX block to send an ACK
	output 			tx_credit_incr;	// high for 1 cycle when a TX credit token has been received
	
	output [47:0]		rx_source_mac;	// MAC address of source packets

	output			rx_error;	// goes and stays high if any packet fails CRC check
						// or if a data packet is received when the FIFO is full

	localparam 		STATE_Idle = 		3'b000,
				STATE_Header = 		3'b001,
				STATE_Data = 		3'b010,
				STATE_Framecheck = 	3'b011,
				STATE_Waiting = 	3'b100,
				STATE_Token = 		3'b101,
				STATE_Ping = 		3'b110;

	localparam		DestAddrLoc = 		5,
				EtherTypeLoc = 		13,
				PayloadStartLoc = 	15,
				PayloadEndLoc = 	23,
				RAMPEtherType = 	16'h8888,
				TokenType = 		16'hFFFF,
				PingType = 		16'hFFFE,
				DataType = 		16'h0008,
				BroadcastAddress = 	48'hFFFFFFFFFFFF;

	//--------------------------------------------------------------------------
	//	Wires & Regs
	//--------------------------------------------------------------------------

	reg [2:0] 		state, nstate;
	reg [63:0] 		rx_data;
	reg [4:0] 		rxcount;
	reg			rxcount_rst;
	reg 			rx_done;
	reg 			store_mac;
	reg			ack;
	reg [1:0] 		send_ack_reg;
	reg [47:0]		source_mac_reg;
	reg			rxfifo_we_reg;
	reg			rx_error_reg;
	reg			tx_credit_incr_reg;

	//--------------------------------------------------------------------------
	//	Assigns
	//--------------------------------------------------------------------------

	assign rx_dout = 	rx_data;
	assign tx_send_ack = 	|send_ack_reg;
	assign rx_source_mac = 	source_mac_reg;
	assign rxfifo_we = 	rxfifo_we_reg;
	assign rx_error = 	rx_error_reg;
	assign tx_credit_incr = tx_credit_incr_reg;
	assign rx_source_mac = 	source_mac_reg;

	//--------------------------------------------------------------------------
	//	RX state machine logic
	//--------------------------------------------------------------------------
	
	always @ ( * ) begin
		nstate = state;
		rxfifo_we_reg = 1'b0;
		rxcount_rst = 1'b0;
		rx_done = 1'b0;
		tx_credit_incr_reg = 1'b0;
		store_mac = 1'b0;
		ack = 1'b0;

		case (state)
			STATE_Idle : begin
				rxcount_rst = 1'b1;
				if (rxdv) nstate = STATE_Header;
			end
			STATE_Header : begin
				if (rxcount == DestAddrLoc & 
				   (rx_data[47:0] != MACAddress & 
				    rx_data[47:0] != BroadcastAddress))
					nstate = STATE_Waiting;
				if (rxcount == EtherTypeLoc) begin
					if (rx_data[15:0] != RAMPEtherType)
						nstate = STATE_Waiting;
					else
						store_mac = 1'b1;
					end
				if (rxcount == PayloadStartLoc) begin
					if (rx_data[15:0] == TokenType)
						nstate = STATE_Token;
					else if (rx_data[15:0] == DataType)
						nstate = STATE_Data;
					else if (rx_data[15:0] == PingType)
						nstate = STATE_Ping;
					else
						nstate = STATE_Waiting;
					end
				end
			STATE_Data : begin
				if (rxcount == PayloadEndLoc) begin
					nstate = STATE_Framecheck;
					rx_done = 1'b1;
				end
			end
			STATE_Framecheck : begin
				rx_done = 1'b1;
				if (rx_good_frame) begin
					rxfifo_we_reg = 1'b1;
					nstate = STATE_Idle;
				end
				if (rx_bad_frame)
					nstate = STATE_Idle;
			end
			STATE_Token : begin
				if (rx_good_frame) begin
					tx_credit_incr_reg = 1'b1;
					nstate = STATE_Idle;
				end
				if (rx_bad_frame)
					nstate = STATE_Idle;
			end
			STATE_Ping: begin
				if (rx_good_frame) begin
					ack = 1'b1;
					nstate = STATE_Idle;
				end
				if (rx_bad_frame)
					nstate = STATE_Idle;
			end	
			STATE_Waiting : begin
				if (~rxdv) nstate = STATE_Idle;
			end
		  endcase	
	end

	//--------------------------------------------------------------------------
	//	Registers
	//--------------------------------------------------------------------------

	always @ (posedge clk) begin
		if (reset) 
			state <= STATE_Idle;
		else 
			state <= nstate;

		if (reset) 
			rx_data <= {64{1'b0}};
		else if (rxdv & ~rx_done) 
			rx_data <= {rx_data[55:0], rxd};

		if (rxcount_rst) 
			rxcount <= {5{1'b0}};
		else 
			rxcount <= rxcount + 1;
		
		if (reset) 
			rx_error_reg <= 1'b0;
		else if (rx_bad_frame | (rxfifo_we_reg & rxfifo_full)) 
			rx_error_reg <= 1'b1;
  
		if (reset) 
			source_mac_reg <= {48{1'b1}};
		else if (store_mac) 
			source_mac_reg <= rx_data[63:16];
  
		if (reset) 
			send_ack_reg <= 2'b00;
		else 
			send_ack_reg <= {send_ack_reg[0], ack};  
	end

endmodule
     
	
