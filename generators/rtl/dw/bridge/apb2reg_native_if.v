module apb2reg_native_if (
    clk, rst_n,
    psel, penable, pready, pwrite, paddr, pwdata, prdata, pslverr,
    req_vld, ack_vld, wr_en, rd_en, addr, wr_data, rd_data, err
);
    parameter   ADDR_WIDTH  = 64;
    parameter   DATA_WIDTH  = 32;

    input   logic                       clk;
    input   logic                       rst_n;

    output  logic                       req_vld;
    input   logic                       ack_vld;
    output  logic                       wr_en;
    output  logic                       rd_en;
    output  logic   [ADDR_WIDTH-1:0]    addr;
    output  logic   [DATA_WIDTH-1:0]    wr_data;
    input   logic   [DATA_WIDTH-1:0]    rd_data;
    input   logic                       err;

    input   logic                       psel;
    input   logic                       penable;
    output  logic                       pready;
    input   logic                       pwrite;
    input   logic   [ADDR_WIDTH-1:0]    paddr;
    input   logic   [DATA_WIDTH-1:0]    pwdata;
    output  logic   [DATA_WIDTH-1:0]    prdata;
    output  logic                       pslverr;

    logic   [DATA_WIDTH-1:0]            rd_data_ff;
    logic                               err_ff;

    logic   [1:0]                       state;
    logic   [1:0]                       next_state;

    localparam      S_IDLE              = 2'd0,
                    S_WAIT              = 2'd1,
                    S_ACK               = 2'd2;

    // state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state       <= S_IDLE;
        else
            state       <= next_state;
    end

    // state transition logic
    always_comb begin
        case (state)
            S_IDLE:
                if (req_vld & (wr_en | rd_en))
                    if (ack_vld)
                        next_state  = S_ACK;
                    else
                        next_state  = S_WAIT;
                else
                    next_state      = S_IDLE;
            S_WAIT:
                if (ack_vld)
                    next_state  = S_IDLE;
                else
                    next_state  = S_WAIT;
            S_ACK:
                next_state      = S_IDLE;
            default:
                next_state      = S_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data_ff  <= {DATA_WIDTH{1'b0}};
            err_ff      <= 1'b0;
        end else begin
            rd_data_ff  <= rd_data;
            err_ff      <= err;
        end
    end

    assign  req_vld     = psel & ~penable;
    assign  wr_en       = psel & ~penable & pwrite;
    assign  rd_en       = psel & ~penable & ~pwrite;
    assign  addr        = (psel & ~penable) ? paddr : {ADDR_WIDTH{1'b0}};
    assign  wr_data     = (psel & ~penable) ? pwdata : {DATA_WIDTH{1'b0}};
    assign  pready      = (state == S_ACK) || (state == S_WAIT && next_state == S_IDLE);
    assign  prdata      = (state == S_ACK) ? rd_data_ff : ((state == S_WAIT && next_state == S_IDLE) ? rd_data : {DATA_WIDTH{1'b0}});
    assign  pslverr     = (state == S_ACK) ? err_ff : ((state == S_WAIT && next_state == S_IDLE) ? err : 1'b0);
endmodule