// =====================================================================
// File        : ahb_decoder.v
// Module      : ahb_decoder
// Standard    : AMBA AHB-Lite
// Description : Combinational address decoder. Generates per-slave
//               HSEL lines from HADDR.
//
// Address map
//   Slave0 : 0x0000_0000 - 0x0000_00FF  (HADDR[8] = 0)
//   Slave1 : 0x0000_0100 - 0x0000_01FF  (HADDR[8] = 1)
//Designed and Developed by K. Veera Prasad Naik
// =====================================================================
module ahb_decoder #(
    parameter ADDR_WIDTH = 32
)(
    input      [ADDR_WIDTH-1:0] HADDR,

    output                      HSEL0,
    output                      HSEL1
);

    wire slave0_match = (HADDR[ADDR_WIDTH-1:9] == 0) && (HADDR[8] == 1'b0);
    wire slave1_match = (HADDR[ADDR_WIDTH-1:9] == 0) && (HADDR[8] == 1'b1);

    assign HSEL0 = slave0_match;
    assign HSEL1 = slave1_match;

endmodule
