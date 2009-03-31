import Clocks::*;

// ethernet-verilog-import

// Import the Verilog device into BSV

// PRIMITIVE_ETHERNET_DEVICE

// The primitive verilog import which we will wrap in clock-domain synchronizers.

interface PRIMITIVE_ETHERNET_DEVICE;

    // Methods for the Driver

    // FIFO Deq
    method Bit#(64) first();
    method Action deq();

    // FIFO Enq
    method Action enq(Bit#(64) d);

    // Wires to be sent to the top level.
    
    method Action phy_rxd((* port="PHY_RXD" *) Bit#(8) rxd);

    method Action phy_rxdv((* port="PHY_RXDV" *) Bit#(1) rxdv);

    method Action phy_rxer((* port="PHY_RXER" *) Bit#(1) rxer);

    method Action phy_rxclk((* port="PHY_RXCLK" *) Bit#(1) rxclk);

    method Action phy_txclk((* port="PHY_TXCLK" *) Bit#(1) txclk);

    method Action phy_col((* port="PHY_COL" *) Bit#(1) col);

    method Action phy_crs((* port="PHY_CRS" *) Bit#(1) crs);
    
    (* always_ready *)
    (* result="PHY_TXD" *)
    method Bit#(8) phy_txd;

    (* always_ready *)
    (* result="PHY_TXEN" *)
    method Bit#(1) phy_txen;

    (* always_ready *)
    (* result="PHY_TXER" *)
    method Bit#(1) phy_txer;

    (* always_ready *)
    (* result="PHY_GTXCLK" *)
    method Bit#(1) phy_gtxclk;

    (* always_ready *)
    (* result="PHY_RESET" *)
    method Bit#(1) phy_reset;

endinterface


// mkPrimitiveEthernetDevice

// Straightforward import of the Verilog into Bluespec.

import "BVI" EthernetFIFO = module mkPrimitiveEthernetDevice
    // interface:
                 (PRIMITIVE_ETHERNET_DEVICE);

    // Clocks and reset are handled by the UCF for now
    default_clock CLK;
    default_reset RST_N;
  
    method phy_rxd(PHY_RXD);

    method phy_rxdv(PHY_RXDV);

    method phy_rxer(PHY_RXER);

    method phy_rxclk(PHY_RXCLK);

    method phy_txclk(PHY_TXCLK);

    method phy_col(PHY_COL);

    method phy_crs(PHY_CRS);
    
    method PHY_TXD phy_txd;

    method PHY_TXEN phy_txen;

    method PHY_TXER phy_txer;

    method PHY_GTXCLK phy_gtxclk;

    method PHY_RESET phy_reset;


    //
    // Import the wires as Bluespec methods
    //
        
    // FIFO Deq
        
    method D_OUT first()
                      ready(EMPTY_N)
                      clocked_by(ethernet_clk)
                      reset_by(ethernet_rst);


    method deq()
                      ready(EMPTY_N)
                      enable(DEQ)
                      clocked_by(ethernet_clk)
                      reset_by(ethernet_rst);

    // FIFO Enq

    method enq(D_IN)
                      ready(FULL_N)
                      enable(ENQ)
                      clocked_by(ethernet_clk)
                      reset_by(ethernet_rst);


    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // first
    // SB with deq
    // CF with everything else, explicitly including itself.
    schedule first SB deq;
    schedule first CF (first,
                       enq,
                       phy_rxd,
                       phy_rxdv,
                       phy_rxer,
                       phy_rxclk,
                       phy_txclk,
                       phy_col,
                       phy_crs,
                       phy_txd, 
                       phy_txen, 
                       phy_txer, 
                       phy_gtxclk, 
                       phy_reset);

    // deq
    // C with itself.
    // CF with everything else.
    schedule deq C deq;
    schedule deq CF (enq,
                     phy_rxd,
                     phy_rxdv,
                     phy_rxer,
                     phy_rxclk,
                     phy_txclk,
                     phy_col,
                     phy_crs,
                     phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    // enq
    // C with itself.
    // CF with everything else.
    schedule enq C enq;
    schedule enq CF (phy_rxd,
                     phy_rxdv,
                     phy_rxer,
                     phy_rxclk,
                     phy_txclk,
                     phy_col,
                     phy_crs,
                     phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);
    
    // Everything else is CF with everything else.

    schedule phy_rxd CF (phy_rxdv,
                     phy_rxer,
                     phy_rxclk,
                     phy_txclk,
                     phy_col,
                     phy_crs,
                     phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);
        
    schedule phy_rxdv CF (phy_rxer,
                     phy_rxclk,
                     phy_txclk,
                     phy_col,
                     phy_crs,
                     phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    schedule phy_rxer CF (phy_rxclk,
                     phy_txclk,
                     phy_col,
                     phy_crs,
                     phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    schedule phy_rxclk CF (phy_txclk,
                     phy_col,
                     phy_crs,
                     phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    schedule phy_txclk CF (phy_col,
                     phy_crs,
                     phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    schedule phy_col CF (phy_crs,
                     phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    schedule phy_crs CF (phy_txd, 
                     phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    schedule phy_txd CF (phy_txen, 
                     phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    schedule phy_txen CF (phy_txer, 
                     phy_gtxclk, 
                     phy_reset);

    schedule phy_txer CF (phy_gtxclk, 
                     phy_reset);

    schedule phy_gtxclk CF phy_reset;

endmodule
