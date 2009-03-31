
// ETHERET_DRIVER

// The Ethernet platform supports enquing and dequeing from FIFOs.

interface ETHERNET_DRIVER;

    // FIFO from host
    method Bit#(64) first();
    method Action deq();
    
    // FIFO to host
    method Action enq(Bit#(64) d);
    
endinterface

// ETHERNET_WIRES

// These are wires which are simply passed up to the toplevel,
// where the UCF file ties them to pins.

interface ETHERNET_WIRES;

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

// ETHERNET_DEVICE

// By convention a Device is a Driver and a Wires

interface ETHERNET_DEVICE;

  interface ETHERNET_DRIVER driver;
  interface ETHERNET_WIRES  wires;

endinterface


// mkEthernetDevice

// Take the primitive Ethernet import and wrap it up nicely.

module mkEthernetDevice
    // interface:
                 (ETHERNET_DEVICE);

    // Instantiate the primitive device.

    PRIMITIVE_ETHERNET_DEVICE primEth <- mkPrimitiveEthernetDevice();
    
    interface ETHERNET_DRIVER driver;
    
        method first = primEth.first;
        method deq   = primEth.deq;
        method enq   = primEth.enq;
    
    endinterface
    
    interface ETHERNET_WIRES wires;

        method phy_rxd    = primEth.phy_rxd;
        method phy_rxdv   = primEth.phy_rxdv;
        method phy_rxer   = primEth.phy_rxer;
        method phy_rxclk  = primEth.phy_rxclk;
        method phy_txclk  = primEth.phy_txclk;
        method phy_col    = primEth.phy_col;
        method phy_crs    = primEth.phy_crs;
        method phy_txd    = primEth.phy_txd;
        method phy_txen   = primEth.phy_txen;
        method phy_txer   = primEth.phy_txer;
        method phy_gtxclk = primEth.phy_gtxclk;
        method phy_reset  = primEth.phy_reset;

    endinterface

endmodule

