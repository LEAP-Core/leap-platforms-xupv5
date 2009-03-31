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
//	Module:		EthernetFIFOTx
//	Description:	This module implements the datapath & control for the transmit side
//			of the EthernetFIFO interface
//			
//	Parameters:	MACAddress:		The hardware MAC address assigned to this device
//
//	Author:		Rimas Avizienis
//	Version:	
//------------------------------------------------------------------------------

module EthernetFIFOTx(
			//------------------------------------------------------------------
			//	System Inputs
			//------------------------------------------------------------------
			clk,
			reset,
			//------------------------------------------------------------------
			//	Interface to Ethernet MAC TX path
			//------------------------------------------------------------------
			txd,
			txen,
			tx_ack,
			//------------------------------------------------------------------
			//	Interface to TX FIFO
			//------------------------------------------------------------------
			txfifo_empty,
			txfifo_re,
			txfifo_data,
			//------------------------------------------------------------------
			//	Control signals
			//------------------------------------------------------------------
			tx_credit_avail,
			tx_credit_decr,
			tx_send_token,
			tx_send_ack,
			rx_token_decr,
			tx_dest_mac

);

	//--------------------------------------------------------------------------
	//	Parameters
	//--------------------------------------------------------------------------

	parameter		MACAddress = 	48'h112233445566;

	//--------------------------------------------------------------------------
	//	System inputs
	//--------------------------------------------------------------------------

	input			clk;
	input			reset;

	//--------------------------------------------------------------------------
	//	Interface to Ethernet MAC TX path
	//--------------------------------------------------------------------------

	output [7:0]		txd;
	output 			txen;
	input			tx_ack;

	//--------------------------------------------------------------------------
	//	Interface to TX FIFO
	//--------------------------------------------------------------------------

	input			txfifo_empty;
	output 			txfifo_re;
	input [63:0] 		txfifo_data;

	//--------------------------------------------------------------------------
	//	Control signals
	//--------------------------------------------------------------------------

	input   		tx_credit_avail;	// high when there is TX credit available
	output			tx_credit_decr;		// high to decrement TX credit count
	input			tx_send_token;		// high when an RX credit token should be sent
	input			tx_send_ack;		// high when an ACK packet should be sent
	input [47:0]		tx_dest_mac;		// destination MAC address
	output 			rx_token_decr;		// high to decrement count of RX credit tokens to send

	//--------------------------------------------------------------------------
	//	Constants
	//--------------------------------------------------------------------------

	localparam		STATE_Idle =	3'b000,
				STATE_Start =	3'b001,
				STATE_Header = 	3'b010,
				STATE_Data = 	3'b011,
				STATE_Token = 	3'b100,
				STATE_Ack = 	3'b101;

	//--------------------------------------------------------------------------
	//	Wires & Regs
	//--------------------------------------------------------------------------

	reg [2:0]		state, nstate;

	reg			txcount_rst; 
	reg [3:0]		txcount;
	reg [2:0]		tx_sel;

	reg [7:0]		fifo_data, tx_data, mac_data, rom_data;
	reg [1:0]		send_ack_reg;	
	reg			send_ack, clear_ack;
	
	reg			txfifo_re_reg;
	reg			rx_token_decr_reg;
	reg			txen_reg;

	//--------------------------------------------------------------------------
	//	Assigns
	//--------------------------------------------------------------------------

	assign	txd = 		tx_data;
	assign	txen = 		txen_reg;	
	assign	txfifo_re = 	txfifo_re_reg;
	assign	rx_token_decr = rx_token_decr_reg;
	assign	tx_credit_decr = txfifo_re_reg;

	//--------------------------------------------------------------------------
	//	Packet header ROM
	//--------------------------------------------------------------------------

	always @ (*) begin
		case(txcount)
			4'b0110: rom_data = MACAddress[47:40];
			4'b0111: rom_data = MACAddress[39:32];
			4'b1000: rom_data = MACAddress[31:24];
			4'b1001: rom_data = MACAddress[23:16];
			4'b1010: rom_data = MACAddress[15:8];
			4'b1011: rom_data = MACAddress[7:0];
			4'b1100: rom_data = 8'h88;
			4'b1101: rom_data = 8'h88;
			4'b1110: rom_data = 8'h00;
			4'b1111: rom_data = 8'h08;
			default: rom_data = 8'hxx;
		    endcase
		end

	//--------------------------------------------------------------------------
	//	Multiplexers
	//--------------------------------------------------------------------------

	always @(*)
		case (tx_sel)
			3'b000: tx_data = mac_data;
			3'b001: tx_data = rom_data;
			3'b010: tx_data = fifo_data;
			3'b011: tx_data = 8'hFF;
			3'b100: tx_data = 8'hFE;
			default: tx_data = 8'hxx;		
		endcase

	always @(*)
		case (txcount[2:0])
			3'b000: fifo_data = txfifo_data[63:56];
			3'b001: fifo_data = txfifo_data[55:48];
			3'b010: fifo_data = txfifo_data[47:40];
			3'b011: fifo_data = txfifo_data[39:32];
			3'b100: fifo_data = txfifo_data[31:24];
			3'b101: fifo_data = txfifo_data[23:16];
			3'b110: fifo_data = txfifo_data[15:8];
			3'b111: fifo_data = txfifo_data[7:0];
		endcase

	always @(*)
		case (txcount[2:0])
			3'b000: mac_data = tx_dest_mac[47:40];
			3'b001: mac_data = tx_dest_mac[39:32];
			3'b010: mac_data = tx_dest_mac[31:24];
			3'b011: mac_data = tx_dest_mac[23:16];
			3'b100: mac_data = tx_dest_mac[15:8];
			3'b101: mac_data = tx_dest_mac[7:0];
			default: mac_data = 8'hxx;
		endcase  		
	 
	//--------------------------------------------------------------------------
	//	TX state machine logic
	//--------------------------------------------------------------------------	 
	 
	always @ (*) begin
		txen_reg = 		1'b1;
		txfifo_re_reg = 	1'b0;
		rx_token_decr_reg = 	1'b0;
		tx_sel = 		3'b000;
		txcount_rst = 		1'b0;
		clear_ack = 		1'b0;
		nstate = 		state;
		
		case (state)
			STATE_Idle: begin
				txen_reg = 1'b0;
				txcount_rst = 1'b1;
				if (tx_send_token | (~txfifo_empty & tx_credit_avail) | send_ack) 
					nstate = STATE_Start;
			end
			STATE_Start: begin
				txcount_rst = 1'b1;
				if (tx_ack) begin
					txcount_rst = 1'b0;
					nstate = STATE_Header;
				end
			end
			STATE_Header: begin
				if (txcount > 5)
					tx_sel = 3'b001;
				if (txcount == 13) begin
					if (send_ack)
						nstate = STATE_Ack;
					else if (tx_send_token)
						nstate = STATE_Token;
				end
				if (txcount == 15)
					nstate = STATE_Data;
			end
			STATE_Data: begin
				tx_sel = 3'b010;
				if (txcount == 7) begin
					nstate = STATE_Idle;
					txfifo_re_reg = 1'b1;
				end
			end
			STATE_Token: begin
				tx_sel = 3'b011;
				if (txcount == 15) begin
					nstate = STATE_Idle;
					rx_token_decr_reg = 1'b1;
				end
			end
			STATE_Ack: begin		
				if (txcount == 14)
					tx_sel = 3'b011;		
				if (txcount == 15) begin
					tx_sel = 3'b100;
					clear_ack = 1'b1;
					nstate = STATE_Idle;
				end
			end
		endcase
	end

	//--------------------------------------------------------------------------
	//	Registers
	//--------------------------------------------------------------------------

	always @(posedge clk) begin
		if (reset) 
			state <= STATE_Idle;
		else 
			state <= nstate;

		if (txcount_rst) 
			txcount <= 4'b0000;
		else 
			txcount <= txcount + 1;
		
		if (reset) 
			send_ack_reg <= 2'b00;
		else 
			send_ack_reg <= {send_ack_reg[0], tx_send_ack};
		
		if (reset | clear_ack) 
			send_ack <= 1'b0;
		else if (send_ack_reg[1]) 
			send_ack <= 1'b1;
   end
	
endmodule
