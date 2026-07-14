// =====================================================================
// File        : ahb_mux.v
// Module      : ahb_mux
// Standard    : AMBA AHB-Lite
// Description : Combinational response multiplexer. Routes HRDATA,
//               HREADYOUT and HRESP from the currently selected slave
//               back to the master, based on HSEL0/HSEL1.
// Designed and Developed by K. Veera Prasad Naik
// =====================================================================
module ahb_mux #(
    parameter DATA_WIDTH = 32
)(
    input                       HSEL0,
    input                       HSEL1,

    input      [DATA_WIDTH-1:0] HRDATA0,
    input                       HREADYOUT0,
    input                       HRESP0,

    input      [DATA_WIDTH-1:0] HRDATA1,
    input                       HREADYOUT1,
    input                       HRESP1,

    output reg [DATA_WIDTH-1:0] HRDATA,
    output reg                  HREADY,
    output reg                  HRESP
);

    always @(*) begin
        case ({HSEL1, HSEL0})
            2'b01: begin // slave0 selected
                HRDATA = HRDATA0;
                HREADY = HREADYOUT0;
                HRESP  = HRESP0;
            end
            2'b10: begin // slave1 selected
                HRDATA = HRDATA1;
                HREADY = HREADYOUT1;
                HRESP  = HRESP1;
            end
            default: begin // no slave selected (unmapped region)
                HRDATA = {DATA_WIDTH{1'b0}};
                HREADY = 1'b1; // avoid stalling master
                HRESP  = 1'b0;
            end
        endcase
    end

endmodule
