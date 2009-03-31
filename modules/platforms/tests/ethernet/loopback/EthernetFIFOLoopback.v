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
//	Module:		EthernetFIFOLoopback
//	Description:	This module sets up the EthernetFIFO module in a loopback
//			configuration
//	Author:		Rimas Avizienis
//	Version:	
//------------------------------------------------------------------------------

module EthernetFIFOLoopback(
				CLK_100,
				RESET,

				PHY_TXD,
				PHY_TXEN,
				PHY_TXER,
				PHY_GTXCLK,
				PHY_RXD,
				PHY_RXDV,
				PHY_RXER,
				PHY_RXCLK,
				PHY_TXCLK,
				PHY_COL,
				PHY_CRS,
				PHY_RESET,
	
				GPIO_LED_0,
				GPIO_LED_1);

	//--------------------------------------------------------------------------
	//	100 MHz clock input
	//--------------------------------------------------------------------------
	input			CLK_100; 

	//--------------------------------------------------------------------------
	//	Reset button (center pushbutton on ML505)
	//--------------------------------------------------------------------------
	input			RESET;

	//--------------------------------------------------------------------------
	//	GMII interface to Marvell 88E1111 PHY
	//--------------------------------------------------------------------------
	output [7:0]		PHY_TXD;
	output			PHY_TXEN;
	output			PHY_TXER;
	output			PHY_GTXCLK;
	input  [7:0]		PHY_RXD;
	input			PHY_RXDV;
	input			PHY_RXER;
	input			PHY_RXCLK;
	input			PHY_TXCLK;
	input			PHY_COL;
	input			PHY_CRS;	 
	output			PHY_RESET; 

	//--------------------------------------------------------------------------
	//	LEDs
	//--------------------------------------------------------------------------
	output			GPIO_LED_0;
	output			GPIO_LED_1;	 

	//--------------------------------------------------------------------------
	//	Wires & Regs
	//--------------------------------------------------------------------------

	wire [63:0] 		data_out;
	wire			empty_n;
	wire			rst_n;
	wire			rx_error;
	wire			full_n;
   wire			deq;

	//--------------------------------------------------------------------------
	//	Assigns
	//--------------------------------------------------------------------------
 
	assign	rst_n = 	~RESET;
	assign	GPIO_LED_0 =	 ~empty_n;
	assign	GPIO_LED_1 = 	rx_error;
	assign	deq = 		empty_n & full_n;
	 
	EthernetFIFO 	#(
			.MACAddress			(48'h112233445566),
			.HostBufferSize			(512),
			.FIFO_FWFT			("TRUE")
			) EthernetFIFO_if (
			.CLK				(CLK_100),
			.RST_N				(rst_n),
			.D_IN				(data_out),
			.ENQ				(deq),
			.FULL_N				(full_n),
			.D_OUT				(data_out),
			.DEQ				(deq),
			.EMPTY_N			(empty_n),
			.CLK_100			(CLK_100),
			.PHY_TXD			(PHY_TXD),
			.PHY_TXEN			(PHY_TXEN),
			.PHY_TXER			(PHY_TXER),
			.PHY_GTXCLK			(PHY_GTXCLK),
			.PHY_RXD			(PHY_RXD),
			.PHY_RXDV			(PHY_RXDV),
			.PHY_RXER			(PHY_RXER),
			.PHY_RXCLK			(PHY_RXCLK),
			.PHY_TXCLK			(PHY_TXCLK),
			.PHY_COL			(PHY_COL),
			.PHY_CRS			(PHY_CRS),
			.PHY_RESET			(PHY_RESET),
			.RX_ERROR			(rx_error));
	
endmodule
