`include "field_attr.vh"
`default_nettype none
module regmst_root_map (
    // APB interface to upstream SoC interconnect
    pclk, presetn, psel, penable, pready, pslverr, pwrite, paddr, pwdata, prdata,
    // reg_native_if to the downstream regdisp module
    regmst_root_map__regdisp_disp_map__req_vld, regdisp_disp_map__regmst_root_map__ack_vld,
    regdisp_disp_map__regmst_root_map__err, regmst_root_map__regdisp_disp_map__wr_en,
    regmst_root_map__regdisp_disp_map__rd_en, regmst_root_map__regdisp_disp_map__addr,
    regmst_root_map__regdisp_disp_map__wr_data, regdisp_disp_map__regmst_root_map__rd_data,
    regmst_root_map__regdisp_disp_map__soft_rst
);
    parameter       ADDR_WIDTH  = 64;
    parameter       DATA_WIDTH  = 32;
    localparam      REG_NUM     = 4;

    input   logic                       pclk;
    input   logic                       presetn;
    input   logic                       psel;
    input   logic                       penable;
    output  logic                       pready;
    output  logic                       pslverr;
    input   logic                       pwrite;
    input   logic   [ADDR_WIDTH-1:0]    paddr;
    input   logic   [DATA_WIDTH-1:0]    pwdata;
    output  logic   [DATA_WIDTH-1:0]    prdata;

    output  logic                       regmst_root_map__regdisp_disp_map__req_vld;
    input   logic                       regdisp_disp_map__regmst_root_map__ack_vld;
    input   logic                       regdisp_disp_map__regmst_root_map__err;
    output  logic                       regmst_root_map__regdisp_disp_map__wr_en;
    output  logic                       regmst_root_map__regdisp_disp_map__rd_en;
    output  logic   [ADDR_WIDTH-1:0]    regmst_root_map__regdisp_disp_map__addr;
    output  logic   [DATA_WIDTH-1:0]    regmst_root_map__regdisp_disp_map__wr_data;
    input   logic   [DATA_WIDTH-1:0]    regdisp_disp_map__regmst_root_map__rd_data;
    output  logic                       regmst_root_map__regdisp_disp_map__soft_rst;

    logic   [REG_NUM-1:0]               dec_db_reg_sel;
    logic                               dec_ext_sel;
    logic 	                            dec_dummy_reg_sel;

    logic                               fsm_req_vld;
    logic                               fsm_ack_vld;
    logic                               fsm_wr_en;
    logic 	                            fsm_rd_en;
    logic   [ADDR_WIDTH-1:0]            fsm_addr;
    logic   [DATA_WIDTH-1:0]            fsm_wr_data;
    logic   [DATA_WIDTH-1:0]            fsm_rd_data;

    logic   [DATA_WIDTH-1:0]            tmr_cnt;
    logic                               tmr_tmout;
    logic                               tmr_rst;

    logic                               err_acc_dummy;
    logic                               int_err_acc_dummy;
    logic                               ext_err_acc_dummy;

    logic   [31:0]                      db_regs_err_addr__snap_0_wr_data;
    logic                               db_regs_err_addr__snap_0_wr_en;
    logic                               db_regs_err_addr__snap_0_rd_en;
    logic   [31:0]                      db_regs_err_addr__snap_1_wr_data;
    logic                               db_regs_err_addr__snap_1_wr_en;
    logic                               db_regs_err_addr__snap_1_rd_en;
    logic   [31:0]                      db_regs_err_addr__snap_0_o;
    logic   [31:0]                      db_regs_err_addr__snap_1_o;
    logic   [63:0]                      db_regs_err_addr_o;
    logic   [1:0]                       db_regs_err_addr_snapshot_snap_wr_en;
    logic   [1:0]                       db_regs_err_addr_snapshot_snap_rd_en;
    logic   [63:0]                      db_regs_err_addr_snapshot_snap_wr_data;
    logic   [63:0]                      db_regs_err_addr_snapshot_snap_rd_data;
    logic   [63:0]                      db_regs_err_addr_snapshot_reg_wr_data;
    logic   [63:0]                      db_regs_err_addr_snapshot_reg_rd_data;
    logic                               db_regs_err_addr_snapshot_reg_wr_en;
    logic                               db_regs_err_addr_snapshot_reg_rd_en;
    logic   [63:0]                      db_regs_err_addr__ADDR__next_value;
    logic                               db_regs_err_addr__ADDR__pulse;
    logic   [63:0]                      db_regs_err_addr__ADDR__curr_value;

    logic   [31:0]                      db_regs_tmr_thr_wr_data;
    logic                               db_regs_tmr_thr_wr_en;
    logic                               db_regs_tmr_thr_rd_en;
    logic   [31:0]                      db_regs_tmr_thr_o;
    logic   [31:0]                      db_regs_tmr_thr__CNT__curr_value;

    logic   [31:0]                      db_regs_err_stat_wr_data;
    logic                               db_regs_err_stat_wr_en;
    logic                               db_regs_err_stat_rd_en;
    logic   [31:0]                      db_regs_err_stat_o;
    logic                               db_regs_err_stat__SOFT_RST__curr_value;
    logic                               db_regs_err_stat__ERR_OCCUR__curr_value;
    logic                               db_regs_err_stat__ERR_OCCUR__next_value;
    logic                               db_regs_err_stat__ERR_OCCUR__pulse;
    logic   [1:0]                       db_regs_err_stat__ERR_TYPE__curr_value;
    logic   [1:0]                       db_regs_err_stat__ERR_TYPE__next_value;
    logic                               db_regs_err_stat__ERR_TYPE__pulse;

    logic   [REG_NUM:0] [DATA_WIDTH-1:0]    int_rd_split_mux_din;
    logic   [REG_NUM:0]                     int_rd_split_mux_sel;
    logic                                   int_rd_split_mux_dout_vld;
    logic                                   int_wr_sel;
    logic                                   dummy_reg_rd_sel;
    logic                                   dummy_reg_wr_sel;
    logic   [REG_NUM-1:0] [DATA_WIDTH-1:0]  db_reg_rd_data;
    logic   [REG_NUM-1:0]                   db_reg_wr_sel;
    logic   [REG_NUM-1:0]                   db_reg_rd_sel;
    logic                                   int_ack_vld;
    logic   [DATA_WIDTH-1:0]                int_rd_data;

//****************************************ADDRESS DECODER************************************************//
    // distinguish access requests to:
    //      internel debug registers
    //      external regdisp module
    //      empty address slot (dummy register)
    always_comb begin
        dec_db_reg_sel      = {REG_NUM {1'b0}};
        dec_ext_sel         = 1'b0;
        dec_dummy_reg_sel   = 1'b0;
        unique casez (paddr[63:2])
            62'h0??, 62'h1??, 62'h2??, 62'h3??, 62'h40?, 62'h41?, 62'h42?, 62'h430, 62'h431: dec_ext_sel = 1'b1;
            62'h800: dec_db_reg_sel[0] = 1'b1;
            62'h801: dec_db_reg_sel[1] = 1'b1;
            62'h802: dec_db_reg_sel[2] = 1'b1;
            62'h803: dec_db_reg_sel[3] = 1'b1;
            default: dec_dummy_reg_sel  = 1'b1;
        endcase
    end

//*****************************************FSM INSTANCE************************************************//
    mst_fsm #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
    mst_fsm (
        .pclk                   (pclk),
        .presetn                (presetn),
        .psel                   (psel),
        .penable                (penable),
        .pready                 (pready),
        .pslverr                (pslverr),
        .paddr                  (paddr),
        .pwrite                 (pwrite),
        .pwdata                 (pwdata),
        .prdata                 (prdata),
        .fsm_req_vld            (fsm_req_vld),
        .fsm_ack_vld            (fsm_ack_vld),
        .fsm_addr               (fsm_addr),
        .fsm_wr_en              (fsm_wr_en),
        .fsm_rd_en              (fsm_rd_en),
        .fsm_wr_data            (fsm_wr_data),
        .fsm_rd_data            (fsm_rd_data),
        .err_acc_dummy          (err_acc_dummy),
        .tmr_tmout              (tmr_tmout),
        .tmr_rst                (tmr_rst)
    );

//*******************************************TIMER*****************************************************//
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn || tmr_rst)
            tmr_cnt <= {DATA_WIDTH{1'b0}};
        else if (tmr_cnt < db_regs_tmr_thr_o)
            tmr_cnt <= tmr_cnt + 1'b1;
    end

//*******************************************EVENT RECORD**********************************************//
    assign  tmr_tmout           = (tmr_cnt == db_regs_tmr_thr_o);
    assign  int_err_acc_dummy   = dec_dummy_reg_sel & fsm_req_vld;

//******************************************DEBUG REGISTERS********************************************//
    // debug register: db_regs_err_addr (64-bit)
    // description:
    //      address of the access where timeout event occurs
    // absolute address:
    // base offset:
    // reset value: 0x0
    // include 2 snapshot registers:
    //      snapshot register 0: db_regs_err_addr__snap_0
    //          absolute address:
    //          base offset:
    //      snapshot register 1: db_regs_err_addr__snap_1
    //          absolute address:
    //          base offset:

    field #(
        .F_WIDTH                (64),
        .ARST_VALUE             (64'h0),
        .SW_TYPE                ({`SW_RO}),
        .SW_ONREAD_TYPE         ({`NA}),
        .SW_ONWRITE_TYPE        ({`NA}),
        .HW_TYPE                (`HW_RW),
        .PRECEDENCE             (`SW))
    x__db_regs_err_addr__ADDR (
        .clk                    (pclk),
        .rst_n                  (presetn),
        .sync_rst               (1'b0),
        .sw_wr_data             (db_regs_err_addr_snapshot_reg_wr_data[63:0]),
        .sw_rd                  (db_regs_err_addr_snapshot_reg_rd_en),
        .sw_wr                  (db_regs_err_addr_snapshot_reg_wr_en),
        .write_protect_en       (1'b0),
        .sw_type_alter_signal   (1'b0),
        .swmod_out              (),
        .swacc_out              (),
        .hw_value               (db_regs_err_addr__ADDR__next_value),
        .hw_pulse               (db_regs_err_addr__ADDR__pulse),
        .field_value            (db_regs_err_addr__ADDR__curr_value)
    );
    always_comb begin
        db_regs_err_addr_o[63:0]     = 64'h0;
        db_regs_err_addr_o[63:0]     = db_regs_err_addr__ADDR__curr_value;
    end
    assign  db_regs_err_addr_snapshot_reg_rd_data    = db_regs_err_addr_o;

    assign  db_regs_err_addr_snapshot_snap_wr_en     = {db_regs_err_addr__snap_1_wr_en, db_regs_err_addr__snap_0_wr_en};
    assign  db_regs_err_addr_snapshot_snap_rd_en     = {db_regs_err_addr__snap_1_rd_en, db_regs_err_addr__snap_0_rd_en};
    assign  db_regs_err_addr_snapshot_snap_wr_data   = {db_regs_err_addr__snap_1_wr_data, db_regs_err_addr__snap_0_wr_data};
    assign  {db_regs_err_addr__snap_1_o, db_regs_err_addr__snap_0_o}  = db_regs_err_addr_snapshot_snap_rd_data;

    snapshot_reg #(.DATA_WIDTH(32), .REG_WIDTH(64))
    db_regs_err_addr_snapshot (
        .clk                    (pclk),
        .rst_n                  (presetn),
        .soft_rst               (regmst_root_map__regdisp_disp_map__soft_rst),
        .snap_wr_en             (db_regs_err_addr_snapshot_snap_wr_en),
        .snap_rd_en             (db_regs_err_addr_snapshot_snap_rd_en),
        .snap_wr_data           (db_regs_err_addr_snapshot_snap_wr_data),
        .snap_rd_data           (db_regs_err_addr_snapshot_snap_rd_data),
        .reg_wr_en              (db_regs_err_addr_snapshot_reg_wr_en),
        .reg_rd_en              (db_regs_err_addr_snapshot_reg_rd_en),
        .reg_wr_data            (db_regs_err_addr_snapshot_reg_wr_data),
        .reg_rd_data            (db_regs_err_addr_snapshot_reg_rd_data)
    );

    // debug register: db_regs_tmr_thr (32-bit)
    // description:
    //      overflow threshold of the timer that
    //      counts for access cycles since regmst receives an APB transaction
    // absolute address:
    // base offset:
    // reset value: 0x63 (0d99)
    field #(
        .F_WIDTH                (32),
        .ARST_VALUE             (32'h63),
        .SW_TYPE                ({`SW_RW}),
        .SW_ONREAD_TYPE         ({`NA}),
        .SW_ONWRITE_TYPE        ({`NA}),
        .HW_TYPE                (`HW_RW),
        .PRECEDENCE             (`SW))
    x__db_regs_tmr_thr__CNT (
        .clk                    (pclk),
        .rst_n                  (presetn),
        .sync_rst               (1'b0),
        .sw_wr_data             (db_regs_tmr_thr_wr_data[31:0]),
        .sw_rd                  (db_regs_tmr_thr_rd_en),
        .sw_wr                  (db_regs_tmr_thr_wr_en),
        .write_protect_en       (1'b0),
        .sw_type_alter_signal   (1'b0),
        .swmod_out              (),
        .swacc_out              (),
        .hw_value               (32'b0),
        .hw_pulse               (1'b0),
        .field_value            (db_regs_tmr_thr__CNT__curr_value)
    );

    always_comb begin
        db_regs_tmr_thr_o[31:0]      = 32'h0;
        db_regs_tmr_thr_o[31:0]      = db_regs_tmr_thr__CNT__curr_value;
    end

    // debug register: db_regs_err_stat
    // description:
    //      record error status.
    //      when field SOFT_RST is asserted, all FSM in downstream modules are reset
    //      so that access won't be stuck at waiting for response
    // absolute address:
    // base offset:
    // reset value: 0x0
    field #(
        .F_WIDTH                (1),
        .ARST_VALUE             (1'h0),
        .SW_TYPE                ({`SW_RW}),
        .SW_ONREAD_TYPE         ({`NA}),
        .SW_ONWRITE_TYPE        ({`NA}),
        .HW_TYPE                (`HW_RW),
        .PRECEDENCE             (`SW))
    x__db_regs_err_stat__SOFT_RST (
        .clk                    (pclk),
        .rst_n                  (presetn),
        .sync_rst               (1'b0),
        .sw_wr_data             (db_regs_err_stat_wr_data[0:0]),
        .sw_rd                  (db_regs_err_stat_rd_en),
        .sw_wr                  (db_regs_err_stat_wr_en),
        .write_protect_en       (1'b0),
        .sw_type_alter_signal   (1'b0),
        .swmod_out              (),
        .swacc_out              (),
        .hw_value               (1'b0),
        .hw_pulse               (1'b0),
        .field_value            (db_regs_err_stat__SOFT_RST__curr_value)
    );
    // soft reset signal is from register db_regs_err_stat bit 0 (SOFT_RST)
    assign  regmst_root_map__regdisp_disp_map__soft_rst          = db_regs_err_stat__SOFT_RST__curr_value;

    field #(
        .F_WIDTH                (1),
        .ARST_VALUE             (1'h0),
        .SW_TYPE                ({`SW_RW}),
        .SW_ONREAD_TYPE         ({`NA}),
        .SW_ONWRITE_TYPE        ({`NA}),
        .HW_TYPE                (`HW_RW),
        .PRECEDENCE             (`SW))
    x__db_regs_err_stat__ERR_OCCUR (
        .clk                    (pclk),
        .rst_n                  (presetn),
        .sync_rst               (1'b0),
        .sw_wr_data             (db_regs_err_stat_wr_data[1:1]),
        .sw_rd                  (db_regs_err_stat_rd_en),
        .sw_wr                  (db_regs_err_stat_wr_en),
        .write_protect_en       (1'b0),
        .sw_type_alter_signal   (1'b0),
        .swmod_out              (),
        .swacc_out              (),
        .hw_value               (db_regs_err_stat__ERR_OCCUR__next_value),
        .hw_pulse               (db_regs_err_stat__ERR_OCCUR__pulse),
        .field_value            (db_regs_err_stat__ERR_OCCUR__curr_value)
    );
    // timeout event is recorded in field ERR_OCCUR
    assign  db_regs_err_stat__ERR_OCCUR__pulse           = tmr_tmout;
    assign  db_regs_err_stat__ERR_OCCUR__next_value      = tmr_tmout;

    field #(
        .F_WIDTH                (2),
        .ARST_VALUE             (1'h0),
        .SW_TYPE                ({`SW_RO}),
        .SW_ONREAD_TYPE         ({`NA}),
        .SW_ONWRITE_TYPE        ({`NA}),
        .HW_TYPE                (`HW_RW),
        .PRECEDENCE             (`SW))
    x__db_regs_err_stat__ERR_TYPE (
        .clk                    (pclk),
        .rst_n                  (presetn),
        .sync_rst               (1'b0),
        .sw_wr_data             (db_regs_err_stat_wr_data[3:2]),
        .sw_rd                  (db_regs_err_stat_rd_en),
        .sw_wr                  (db_regs_err_stat_wr_en),
        .write_protect_en       (1'b0),
        .sw_type_alter_signal   (1'b0),
        .swmod_out              (),
        .swacc_out              (),
        .hw_value               (db_regs_err_stat__ERR_TYPE__next_value),
        .hw_pulse               (db_regs_err_stat__ERR_TYPE__pulse),
        .field_value            (db_regs_err_stat__ERR_TYPE__curr_value)
    );
    // field ERR_TYPE records whether error occurs in write or read transaction
    assign  db_regs_err_stat__ERR_TYPE__pulse        = tmr_tmout | err_acc_dummy;
    assign  db_regs_err_stat__ERR_TYPE__next_value   = {tmr_tmout, pwrite};

    always_comb begin
        db_regs_err_stat_o[31:0]     = 32'h0;
        db_regs_err_stat_o[0:0]      = db_regs_err_stat__SOFT_RST__curr_value;
        db_regs_err_stat_o[1:1]      = db_regs_err_stat__ERR_OCCUR__curr_value;
        db_regs_err_stat_o[3:2]      = db_regs_err_stat__ERR_TYPE__curr_value;
    end


//*************************INTERNAL/EXTERNAL MUX/IMUX INSTANCE*****************************************//
    // internal register multiplexor: rd_data and ack_vld from debug registers
    assign  db_reg_rd_data[0]           = db_regs_err_addr__snap_0_o;
    assign  db_reg_rd_data[1]           = db_regs_err_addr__snap_1_o;
    assign  db_reg_rd_data[2]           = db_regs_tmr_thr_o;
    assign  db_reg_rd_data[3]           = db_regs_err_stat_o;

    assign  int_rd_split_mux_din        = {db_reg_rd_data, {DATA_WIDTH{1'b0}}};
    assign  int_rd_split_mux_sel        = {db_reg_rd_sel, dummy_reg_rd_sel};
    assign  int_wr_sel                  = (| db_reg_wr_sel) | dummy_reg_wr_sel;
    split_mux_2d #(
        .WIDTH(DATA_WIDTH), .CNT(REG_NUM+1),
        .GROUP_SIZE(128), .SKIP_DFF_0(1), .SKIP_DFF_1(1))
    int_rd_split_mux (
        .clk                    (pclk),
        .rst_n                  (presetn),
        .din                    (int_rd_split_mux_din),
        .sel                    (int_rd_split_mux_sel),
        .dout                   (int_rd_data),
        .dout_vld               (int_rd_split_mux_dout_vld));

    assign  int_ack_vld         = int_rd_split_mux_dout_vld | int_wr_sel;

    // internal register inverse multiplexor to debug registers
    assign  db_reg_wr_sel               = {REG_NUM{fsm_wr_en}} & dec_db_reg_sel;
    assign  db_reg_rd_sel               = {REG_NUM{fsm_rd_en}} & dec_db_reg_sel;
    assign  dummy_reg_rd_sel            = dec_dummy_reg_sel & fsm_req_vld & fsm_rd_en;
    assign  dummy_reg_wr_sel            = dec_dummy_reg_sel & fsm_req_vld & fsm_wr_en;

    assign  db_regs_err_addr__snap_0_wr_data = db_reg_wr_sel[0] ? fsm_wr_data : {DATA_WIDTH{1'b0}};
    assign  db_regs_err_addr__snap_0_wr_en   = db_reg_wr_sel[0];
    assign  db_regs_err_addr__snap_0_rd_en   = db_reg_rd_sel[0];

    assign  db_regs_err_addr__snap_1_wr_data = db_reg_wr_sel[1] ? fsm_wr_data : {DATA_WIDTH{1'b0}};
    assign  db_regs_err_addr__snap_1_wr_en   = db_reg_wr_sel[1];
    assign  db_regs_err_addr__snap_1_rd_en   = db_reg_rd_sel[1];

    assign  db_regs_tmr_thr_wr_data          = db_reg_wr_sel[2] ? fsm_wr_data : {DATA_WIDTH{1'b0}};
    assign  db_regs_tmr_thr_wr_en            = db_reg_wr_sel[2];
    assign  db_regs_tmr_thr_rd_en            = db_reg_rd_sel[2];

    assign  db_regs_err_stat_wr_data         = db_reg_wr_sel[3] ? fsm_wr_data : {DATA_WIDTH{1'b0}};
    assign  db_regs_err_stat_wr_en           = db_reg_wr_sel[3];
    assign  db_regs_err_stat_rd_en           = db_reg_rd_sel[3];

    // ultimate multiplexor to mst_fsm: ack_vld, rd_data, err
    assign  fsm_rd_data                 = int_ack_vld ? int_rd_data : (regdisp_disp_map__regmst_root_map__ack_vld ? regdisp_disp_map__regmst_root_map__rd_data : {DATA_WIDTH{1'b0}});
    assign  fsm_ack_vld                 = int_ack_vld | regdisp_disp_map__regmst_root_map__ack_vld;
    assign  ext_err_acc_dummy           = regdisp_disp_map__regmst_root_map__err;
    assign  err_acc_dummy               = int_err_acc_dummy | ext_err_acc_dummy;

    // ultimate inverse multiplexor: to the external downstream regdisp module
    assign  regmst_root_map__regdisp_disp_map__req_vld       = fsm_req_vld & dec_ext_sel;
    assign  regmst_root_map__regdisp_disp_map__wr_en         = fsm_wr_en & dec_ext_sel;
    assign  regmst_root_map__regdisp_disp_map__rd_en         = fsm_rd_en & dec_ext_sel;
    assign  regmst_root_map__regdisp_disp_map__addr          = dec_ext_sel ? fsm_addr : {ADDR_WIDTH{1'b0}};
    assign  regmst_root_map__regdisp_disp_map__wr_data       = dec_ext_sel ? fsm_wr_data : {DATA_WIDTH{1'b0}};
endmodule
`default_nettype wire