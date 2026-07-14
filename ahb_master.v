// =====================================================================
// File        : ahb_master.v
// Module      : ahb_master
// Standard    : AMBA AHB-Lite
// Description : Synthesizable AHB-Lite master. Converts a simple
//               request interface (start/write/addr/wdata) into the
//               standard two-phase AHB transfer:
//                 Address phase (HTRANS = NONSEQ, HADDR/HWRITE valid)
//                 Data phase    (HWDATA driven / HRDATA sampled)
//               Single outstanding transfer at a time (no pipelined
//               back-to-back overlap) for clarity and correctness.
//
// Ports
//   Request side : start, write, addr, wdata, rdata, done, busy
//   AHB side     : HADDR, HWRITE, HTRANS, HSIZE, HBURST, HPROT, HWDATA (out)
//                  HRDATA, HREADY, HRESP (in)
// Designed and Developed by K. Veera Prasad Naik
// =====================================================================
module ahb_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                       HCLK,
    input                       HRESETn,

    // Simple request interface (from test sequencer / user logic)
    input                       start,
    input                       write,
    input      [ADDR_WIDTH-1:0] addr,
    input      [DATA_WIDTH-1:0] wdata,
    output reg [DATA_WIDTH-1:0] rdata,
    output reg                  done,
    output                      busy,

    // AHB-Lite bus signals (master outputs)
    output reg [ADDR_WIDTH-1:0] HADDR,
    output reg                  HWRITE,
    output                      [1:0] HTRANS,
    output     [2:0]            HSIZE,
    output     [2:0]            HBURST,
    output     [3:0]            HPROT,
    output reg [DATA_WIDTH-1:0] HWDATA,

    // AHB-Lite bus signals (from slave/mux)
    input      [DATA_WIDTH-1:0] HRDATA,
    input                       HREADY,
    input                       HRESP
);

    // Fixed transfer attributes (single 32-bit transfers, no bursts)
    assign HSIZE  = 3'b010;      // 32-bit word
    assign HBURST = 3'b000;      // SINGLE
    assign HPROT  = 4'b0011;     // data access, privileged, non-cacheable

    localparam [1:0] TR_IDLE   = 2'b00;
    localparam [1:0] TR_NONSEQ = 2'b10;

    localparam ST_IDLE   = 2'b00;
    localparam ST_ADDR   = 2'b01; // address phase
    localparam ST_DATA   = 2'b10; // data phase

    reg [1:0] state, next_state;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            ST_IDLE : next_state = start ? ST_ADDR : ST_IDLE;
            ST_ADDR : next_state = ST_DATA;
            ST_DATA : next_state = HREADY ? (start ? ST_ADDR : ST_IDLE) : ST_DATA;
            default : next_state = ST_IDLE;
        endcase
    end

    assign HTRANS = (state == ST_ADDR) ? TR_NONSEQ : TR_IDLE;
    assign busy   = (state != ST_IDLE);

    // Address / control phase capture
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR  <= {ADDR_WIDTH{1'b0}};
            HWRITE <= 1'b0;
            HWDATA <= {DATA_WIDTH{1'b0}};
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start) begin
                        HADDR  <= addr;
                        HWRITE <= write;
                        HWDATA <= wdata;
                    end
                end
                ST_DATA: begin
                    if (HREADY && start) begin
                        HADDR  <= addr;
                        HWRITE <= write;
                        HWDATA <= wdata;
                    end
                end
                default: ; // ST_ADDR: hold captured values
            endcase
        end
    end

    // Read-data capture / done pulse
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            rdata <= {DATA_WIDTH{1'b0}};
            done  <= 1'b0;
        end else begin
            done <= 1'b0;
            if (state == ST_DATA && HREADY) begin
                if (!HWRITE)
                    rdata <= HRDATA;
                done <= 1'b1;
            end
        end
    end

endmodule
