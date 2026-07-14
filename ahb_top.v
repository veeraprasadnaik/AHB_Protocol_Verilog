// =====================================================================
// File        : ahb_top.v
// Module      : ahb_top
// Standard    : AMBA AHB-Lite
// Description : Top-level integration of the AHB-Lite subsystem:
//               ahb_master -> ahb_decoder -> {ahb_slave0, ahb_slave1}
//               -> ahb_mux -> back to ahb_master.
//               Exposes a simple start/write/addr/wdata/rdata/done
//               interface to the outside world; the internal AHB bus
//               is fully self-contained.
//Designed and Developed by K. Veera Prasad Naik
// =====================================================================
module ahb_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                       HCLK,
    input                       HRESETn,

    input                       start,
    input                       write,
    input      [ADDR_WIDTH-1:0] addr,
    input      [DATA_WIDTH-1:0] wdata,
    output     [DATA_WIDTH-1:0] rdata,
    output                      done,
    output                      busy
);

    wire [ADDR_WIDTH-1:0] HADDR;
    wire                   HWRITE;
    wire [1:0]             HTRANS;
    wire [2:0]             HSIZE;
    wire [2:0]             HBURST;
    wire [3:0]             HPROT;
    wire [DATA_WIDTH-1:0]  HWDATA;

    wire                   HSEL0, HSEL1;

    wire [DATA_WIDTH-1:0]  HRDATA0, HRDATA1;
    wire                   HREADYOUT0, HREADYOUT1;
    wire                   HRESP0, HRESP1;

    wire [DATA_WIDTH-1:0]  HRDATA;
    wire                   HREADY;
    wire                   HRESP;

    //-----------------------------------------------------------------
    // AHB-Lite Master
    //-----------------------------------------------------------------
    ahb_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_ahb_master (
        .HCLK    (HCLK),
        .HRESETn (HRESETn),

        .start   (start),
        .write   (write),
        .addr    (addr),
        .wdata   (wdata),
        .rdata   (rdata),
        .done    (done),
        .busy    (busy),

        .HADDR   (HADDR),
        .HWRITE  (HWRITE),
        .HTRANS  (HTRANS),
        .HSIZE   (HSIZE),
        .HBURST  (HBURST),
        .HPROT   (HPROT),
        .HWDATA  (HWDATA),

        .HRDATA  (HRDATA),
        .HREADY  (HREADY),
        .HRESP   (HRESP)
    );

    //-----------------------------------------------------------------
    // AHB-Lite Decoder
    //-----------------------------------------------------------------
    ahb_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_ahb_decoder (
        .HADDR (HADDR),
        .HSEL0 (HSEL0),
        .HSEL1 (HSEL1)
    );

    //-----------------------------------------------------------------
    // AHB-Lite Slave 0
    //-----------------------------------------------------------------
    ahb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS  (4)
    ) u_ahb_slave0 (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn),
        .HADDR     (HADDR),
        .HWRITE    (HWRITE),
        .HTRANS    (HTRANS),
        .HSEL      (HSEL0),
        .HREADY    (HREADY),
        .HWDATA    (HWDATA),
        .HRDATA    (HRDATA0),
        .HREADYOUT (HREADYOUT0),
        .HRESP     (HRESP0)
    );

    //-----------------------------------------------------------------
    // AHB-Lite Slave 1
    //-----------------------------------------------------------------
    ahb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS  (4)
    ) u_ahb_slave1 (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn),
        .HADDR     (HADDR),
        .HWRITE    (HWRITE),
        .HTRANS    (HTRANS),
        .HSEL      (HSEL1),
        .HREADY    (HREADY),
        .HWDATA    (HWDATA),
        .HRDATA    (HRDATA1),
        .HREADYOUT (HREADYOUT1),
        .HRESP     (HRESP1)
    );

    //-----------------------------------------------------------------
    // AHB-Lite Response Mux
    //-----------------------------------------------------------------
    ahb_mux #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_ahb_mux (
        .HSEL0      (HSEL0),
        .HSEL1      (HSEL1),

        .HRDATA0    (HRDATA0),
        .HREADYOUT0 (HREADYOUT0),
        .HRESP0     (HRESP0),

        .HRDATA1    (HRDATA1),
        .HREADYOUT1 (HREADYOUT1),
        .HRESP1     (HRESP1),

        .HRDATA     (HRDATA),
        .HREADY     (HREADY),
        .HRESP      (HRESP)
    );

endmodule
