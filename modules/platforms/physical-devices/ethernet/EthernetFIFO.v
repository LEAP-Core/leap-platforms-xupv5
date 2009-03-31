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
//	Module:		EthernetFIFO
//	Description:	This module connects to the Ethernet PHY and provides a 64
//			bit wide FIFO interface.
//	Parameters:	MACAddress:		The hardware MAC address assigned to this device
//			HostBufferSize:		The depth of the FIFO on the remote end of
//						the Ethernet link
//			FIFO_FWFT		Sets whether the output of the FIFO
//						interface uses First Word Fall Through
//	Author:		Rimas Avizienis
//	Version:	
//------------------------------------------------------------------------------

module	EthernetFIFO(
			//------------------------------------------------------------------
			//	FIFO Interface
			//------------------------------------------------------------------
			CLK,	
			RST_N,
			D_IN,
			ENQ,
			FULL_N,
			D_OUT,
			DEQ,
			EMPTY_N,
			//------------------------------------------------------------------

			//------------------------------------------------------------------
			//	Clock Input
			//------------------------------------------------------------------
			CLK_100,
			//------------------------------------------------------------------

			//------------------------------------------------------------------
			//	Ethernet GMII Interface
			//------------------------------------------------------------------
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
			//------------------------------------------------------------------

			//------------------------------------------------------------------
			//	Status Output
			//------------------------------------------------------------------
			RX_ERROR
);

	//--------------------------------------------------------------------------
	//	Parameters
	//--------------------------------------------------------------------------
	
	parameter		MACAddress = 		48'h112233445566;
	parameter		HostBufferSize = 	512;
	parameter		FIFO_FWFT = 		"TRUE";

	//--------------------------------------------------------------------------
	//	FIFO Interface
	//--------------------------------------------------------------------------

	input 			CLK;	
	input			RST_N;
	input	[63:0]		D_IN;
	input			ENQ;
	output			FULL_N;
	output	[63:0]		D_OUT;
	input			DEQ;
	output			EMPTY_N; 

	//--------------------------------------------------------------------------
	//	100 MHz clock input (used to generate 125 MHz clock for PHY)
	//--------------------------------------------------------------------------
	
	input			CLK_100; 
	
	//--------------------------------------------------------------------------
	//	Ethernet GMII Interface
	//--------------------------------------------------------------------------

	output	[7:0]		PHY_TXD;
	output			PHY_TXEN;
	output			PHY_TXER;
	output			PHY_GTXCLK;
	input	[7:0]		PHY_RXD;
	input			PHY_RXDV;
	input			PHY_RXER;
	input			PHY_RXCLK;
	input			PHY_TXCLK;
	input			PHY_COL;
	input			PHY_CRS;	 
	output			PHY_RESET;

	//--------------------------------------------------------------------------
	//	Status output
	//--------------------------------------------------------------------------
	 
	output			RX_ERROR;

	//--------------------------------------------------------------------------
	//	Wires & Regs
	//--------------------------------------------------------------------------
	
	wire 			reset;
	wire 			rxfifo_full, rxfifo_empty, rxfifo_we;
	wire 			txfifo_full, txfifo_empty, txfifo_re;

	wire 			rx_token_decr;
	wire 			tx_credit_incr, tx_credit_decr, tx_credit_avail;
	wire 			tx_send_ack, tx_send_token;

	wire [63:0]		rx_dout, txfifo_dout;
	wire [47:0]		rx_source_mac;

	wire [7:0]		rx_data, tx_data; 	 
	wire			rx_data_valid, tx_data_valid, tx_ack;
	wire 			rx_good_frame, rx_bad_frame;

	wire			rx_clk_0_i;
	wire			tx_client_clk_0_o;
	wire			tx_client_clk_0;
	wire			rx_client_clk_0_o;
	wire			rx_client_clk_0;
	wire			tx_phy_clk_0_o;
	wire			tx_phy_clk_0;
	wire			gtx_clk_0_i;
	wire			refclk, refclk_bufg_i;

	reg [12:0]		idelayctrl_reset_0_r;
	wire			idelayctrl_reset_0_i;	 	
	 
	reg [5:0]		tx_pre_reset_0_i;
	reg			tx_reset_0_i;

	reg [5:0]		rx_pre_reset_0_i;
	reg			rx_reset_0_i;

	//--------------------------------------------------------------------------
	//	Assigns
	//--------------------------------------------------------------------------

	assign	reset = 	~RST_N;
	assign	PHY_RESET = 	RST_N;
	assign	FULL_N = 	~txfifo_full;
	assign	EMPTY_N = 	~rxfifo_empty;
	assign	idelayctrl_reset_0_i = idelayctrl_reset_0_r[12];	

	//--------------------------------------------------------------------------
	//	Ethernet RX control
	//--------------------------------------------------------------------------

	EthernetFIFORx	#(
			.MACAddress(MACAddress)
			) EthernetFIFORx_if (
			.clk				(rx_client_clk_0),
			.reset				(rx_reset_0_i),
			.rxd				(rx_data),
			.rxdv				(rx_data_valid),
			.rx_good_frame			(rx_good_frame),
			.rx_bad_frame			(rx_bad_frame),
			.rxfifo_full			(rxfifo_full),
			.rxfifo_we			(rxfifo_we),
			.rx_dout			(rx_dout),
			.tx_send_ack			(tx_send_ack),
			.tx_credit_incr			(tx_credit_incr),
			.rx_source_mac			(rx_source_mac),
			.rx_error			(RX_ERROR));
		
	//--------------------------------------------------------------------------
	//	Asynchronous semaphore to track transmit credits
	//--------------------------------------------------------------------------

	FIFOSemaphore	#(
			.Asynchronous			(1),
			.Buffering			(HostBufferSize)
			) TXCredit_Semaphore (
			.Reset				(reset),
			.InClock			(tx_client_clk_0),
			.InReset			(tx_reset_0_i),
			.InValid			(tx_credit_decr),
			.InReady			(tx_credit_avail),
			.OutClock			(rx_client_clk_0),
			.OutReset			(rx_reset_0_i),	
			.OutValid			(),
			.OutReady			(tx_credit_incr));		

	//--------------------------------------------------------------------------
	//	Ethernet TX control
	//--------------------------------------------------------------------------

	EthernetFIFOTx	#(
			.MACAddress			(MACAddress)
			) EthernetFIFOTx_if (
			.clk				(tx_client_clk_0),
			.reset				(tx_reset_0_i),
			.txd				(tx_data),
			.txen				(tx_data_valid),
			.tx_ack				(tx_ack),
			.txfifo_empty			(txfifo_empty),
			.txfifo_re			(txfifo_re),	
			.txfifo_data			(txfifo_dout),
			.tx_credit_avail		(tx_credit_avail),
			.tx_credit_decr			(tx_credit_decr),
			.tx_send_token			(tx_send_token),
			.tx_send_ack			(tx_send_ack),
			.rx_token_decr			(rx_token_decr),
			.tx_dest_mac			(rx_source_mac));

	//--------------------------------------------------------------------------
	//	Asynchronous semaphore to track receive credit tokens to send
	//--------------------------------------------------------------------------

	FIFOSemaphore 	#(
			.Asynchronous			(1),
			.Buffering			(512) 
			) RXToken_Semaphore (
			.Reset				(reset),
			.InClock			(CLK),
			.InReset			(reset),
			.InValid			(DEQ),
			.InReady			(),
			.OutClock			(tx_client_clk_0),
			.OutReset			(tx_reset_0_i),	
			.OutValid			(tx_send_token),
			.OutReady			(rx_token_decr));	
					 
	//--------------------------------------------------------------------------
	//	RX Fifo (512 entries deep x 64 bits wide)
	//--------------------------------------------------------------------------
	
	FIFO36_72 	#(
			.DO_REG				(1),
			.EN_ECC_READ			("FALSE"),
			.EN_ECC_WRITE			("FALSE"),
			.EN_SYN				("FALSE"),
			.FIRST_WORD_FALL_THROUGH	(FIFO_FWFT)
			) rxfifo (
			.DO				(D_OUT),
			.EMPTY				(rxfifo_empty),
			.FULL				(rxfifo_full),
			.DI				(rx_dout),
			.DIP				(8'b0),
			.RDCLK				(CLK),
			.RDEN				(DEQ),
			.RST				(rx_reset_0_i),
			.WRCLK				(rx_client_clk_0),
			.WREN				(rxfifo_we));

	//--------------------------------------------------------------------------
	//	TX Fifo (512 entries deep x 64 bits wide)
	//--------------------------------------------------------------------------

	FIFO36_72 	#(
			.DO_REG				(1),
			.EN_ECC_READ			("FALSE"),
			.EN_ECC_WRITE			("FALSE"),
			.EN_SYN				("FALSE"),
			.FIRST_WORD_FALL_THROUGH	("TRUE")
			) txfifo (
			.DO				(txfifo_dout),
			.EMPTY				(txfifo_empty),
			.FULL				(txfifo_full),
			.DI				(D_IN),
			.DIP				(8'b0),
			.RDCLK				(tx_client_clk_0),
			.RDEN				(txfifo_re),
			.RST				(tx_reset_0_i),
			.WRCLK				(CLK),
			.WREN				(ENQ));
		
	//--------------------------------------------------------------------------
	//	DCM to generate 125 MHz GTXCLK and 200 MHZ REFCLK from 100MHz clock input
	//--------------------------------------------------------------------------

	 DCM_ADV 	#(
			.CLKFX_DIVIDE			(4),
			.CLKFX_MULTIPLY			(5),
			.CLKIN_PERIOD			(10),
			.CLK_FEEDBACK			("NONE")
			) gtxclk_dcm (
			.CLKIN				(CLK_100),
			.CLK2X				(refclk),
			.CLKFX				(gtx_clk_0),
			.RST				(reset));
			
	BUFG bufg_gtx_clk_0 (.I(gtx_clk_0), .O(gtx_clk_0_i));	
	BUFG bufg_refclk (.I(refclk), .O(refclk_bufg_i));		

	//--------------------------------------------------------------------------
	//	Create synchronous reset signals
	//--------------------------------------------------------------------------

	always @(posedge tx_client_clk_0_o, posedge reset)
	begin
	if (reset == 1'b1)
		begin
		tx_pre_reset_0_i <= 6'h3F;
		tx_reset_0_i     <= 1'b1;
		end
	else
		begin
		tx_pre_reset_0_i[0]   <= 1'b0;
		tx_pre_reset_0_i[5:1] <= tx_pre_reset_0_i[4:0];
		tx_reset_0_i          <= tx_pre_reset_0_i[5];
		end
	end

	always @(posedge rx_client_clk_0_o, posedge reset)
	begin
	if (reset == 1'b1)
		begin
		rx_pre_reset_0_i <= 6'h3F;
		rx_reset_0_i     <= 1'b1;
		end
	else
		begin
		rx_pre_reset_0_i[0]   <= 1'b0;
		rx_pre_reset_0_i[5:1] <= rx_pre_reset_0_i[4:0];
		rx_reset_0_i          <= rx_pre_reset_0_i[5];
		end
	end  
					
	always @(posedge refclk_bufg_i, posedge reset)
	begin
	if (reset  == 1'b1)
		begin
		idelayctrl_reset_0_r[0]    <= 1'b0;
		idelayctrl_reset_0_r[12:1] <= 12'b111111111111;
		end
	else
		begin
		idelayctrl_reset_0_r[0]    <= 1'b0;
		idelayctrl_reset_0_r[12:1] <= idelayctrl_reset_0_r[11:0];
		end
	end
			
	//--------------------------------------------------------------------------
	//	EMAC0 Clocking
	//	Instantiate IDELAYCTRL for the IDELAY in Fixed Tap Delay Mode
	//--------------------------------------------------------------------------

	IDELAYCTRL dlyctrl0 (
			.RDY				(),
			.REFCLK			(refclk_bufg_i),
	      .RST				(idelayctrl_reset_0_i)) /* synthesis syn_noprune = 1 */;
    	

	IODELAY #(
			.IDELAY_TYPE			("FIXED"),
			.IDELAY_VALUE			(0)
			) gmii_rxc0_delay (
			.IDATAIN				(PHY_RXCLK),
			.DATAOUT				(gmii_rx_clk_0_delay),
			.ODATAIN				(1'b0),
			.T						(1'b1), 
			.C						(1'b0), 
			.CE					(1'b0), 
			.INC					(1'b0), 
			.RST					(1'b0));

	//--------------------------------------------------------------------------
	//	Put the PHY clocks from the EMAC through BUFGs.
	//	Used to clock the PHY 	side of the EMAC wrappers.
	//--------------------------------------------------------------------------
	 
	BUFG bufg_phy_tx_0 (.I(tx_phy_clk_0_o), .O(tx_phy_clk_0));
	BUFG bufg_phy_rx_0 (.I(gmii_rx_clk_0_delay), .O(rx_clk_0_i));

	//--------------------------------------------------------------------------
	//	Put the client clocks from the EMAC through BUFGs.
	//	Used to clock the client side of the EMAC wrappers.
	//--------------------------------------------------------------------------

	BUFG bufg_client_tx_0 (.I(tx_client_clk_0_o), .O(tx_client_clk_0));
	BUFG bufg_client_rx_0 (.I(rx_client_clk_0_o), .O(rx_client_clk_0));
								
	//--------------------------------------------------------------------------
	//	Instantiate the EMAC Wrapper
	//--------------------------------------------------------------------------

	v5_emac_v1_5_block EMac0_block (
			.TX_CLIENT_CLK_OUT_0		(tx_client_clk_0_o),
			.RX_CLIENT_CLK_OUT_0		(rx_client_clk_0_o),
			.TX_PHY_CLK_OUT_0		(tx_phy_clk_0_o),
			.TX_CLIENT_CLK_0		(tx_client_clk_0),
			.RX_CLIENT_CLK_0		(rx_client_clk_0),
			.TX_PHY_CLK_0			(tx_phy_clk_0),
			.EMAC0CLIENTRXD			(rx_data),
			.EMAC0CLIENTRXDVLD		(rx_data_valid),
			.EMAC0CLIENTRXGOODFRAME		(rx_good_frame),
			.EMAC0CLIENTRXBADFRAME		(rx_bad_frame),
			.CLIENTEMAC0TXD			(tx_data),
			.CLIENTEMAC0TXDVLD		(tx_data_valid),
			.EMAC0CLIENTTXACK		(tx_ack),
			.CLIENTEMAC0TXFIRSTBYTE		(1'b0),
			.CLIENTEMAC0TXUNDERRUN		(1'b0),
			.CLIENTEMAC0TXIFGDELAY		(8'b0),
			.CLIENTEMAC0PAUSEREQ		(1'b0),
			.CLIENTEMAC0PAUSEVAL		(16'b0),
			.GTX_CLK_0			(gtx_clk_0_i),
			.GMII_TXD_0			(PHY_TXD),
			.GMII_TX_EN_0			(PHY_TXEN),
			.GMII_TX_ER_0			(PHY_TXER),
			.GMII_TX_CLK_0			(PHY_GTXCLK),
			.GMII_RXD_0			(PHY_RXD),
			.GMII_RX_DV_0			(PHY_RXDV),
			.GMII_RX_ER_0			(PHY_RXER),
			.GMII_RX_CLK_0			(rx_clk_0_i),
			.MII_TX_CLK_0			(PHY_TXCLK),
			.GMII_COL_0			(PHY_COL),
			.GMII_CRS_0			(PHY_CRS),
			.RESET				(reset));
						
endmodule
		

