// =====================================================================
// File        : ahb_slave.v
// Module      : ahb_slave
// Standard    : AMBA AHB-Lite
// Description : Generic synthesizable AHB-Lite slave with a
//               parameterized 32-bit register bank (default: 4 regs).
//               Zero wait-state response (HREADYOUT tied high).
//
//               Follows the standard AHB two-phase pipeline pattern:
//                 - Address phase: HSEL && HREADY && HTRANS==NONSEQ
//                   is sampled, latching the write-enable and the
//                   target register index.
//                 - Data phase (next cycle): HWDATA is written into
//                   the latched register index if a write was
//                   pending.
//               HRDATA is driven combinationally from the currently
//               addressed register.
// Designed and Developed by K. Veera Prasad Naik
// =====================================================================
module ahb_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 4
)(
    input                       HCLK,
    input                       HRESETn,

    input      [ADDR_WIDTH-1:0] HADDR,
    input                       HWRITE,
    input      [1:0]            HTRANS,
    input                       HSEL,
    input                       HREADY,
    input      [DATA_WIDTH-1:0] HWDATA,

    output reg [DATA_WIDTH-1:0] HRDATA,
    output                      HREADYOUT,
    output                      HRESP
);

    localparam [1:0] TR_NONSEQ = 2'b10;

    reg [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];

    reg        pending_write;
    reg [1:0]  pending_index;

    wire [1:0] reg_index = HADDR[3:2];

    assign HREADYOUT = 1'b1; // no wait states
    assign HRESP     = 1'b0; // OKAY

    integer i;

    // Address-phase acceptance: latch write intent + target index
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            pending_write <= 1'b0;
            pending_index <= 2'b00;
        end else if (HSEL && HREADY) begin
            pending_write <= HWRITE && (HTRANS == TR_NONSEQ);
            pending_index <= reg_index;
        end else begin
            pending_write <= 1'b0;
        end
    end

    // Data-phase commit: perform the actual register write
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            for (i = 0; i < NUM_REGS; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (pending_write) begin
            regs[pending_index] <= HWDATA;
        end
    end

    // Combinational read
    always @(*) begin
        HRDATA = regs[reg_index];
    end

endmodule
