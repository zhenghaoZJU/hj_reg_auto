`include "xregister.vh"
`default_nettype none
module regslv_reg_top__reg_block_1(
//*************************************EXTERNAL MODULE PORT START*************************************//
//**************************************EXTERNAL MODULE PORT END**************************************//


//*************************************INTERNAL FIELD PORT START**************************************//
	// ports of internal regfile
	// ports of ['REG1_SW_RO', 'FIELD_0']
	REG1_SW_RO__FIELD_0__next_value        ,
	REG1_SW_RO__FIELD_0__pulse             ,
	REG1_SW_RO__FIELD_0__curr_value        ,
	// ports of ['REG2_SW_RW', 'FIELD_0']
	REG2_SW_RW__FIELD_0__next_value        ,
	REG2_SW_RW__FIELD_0__pulse             ,
	REG2_SW_RW__FIELD_0__curr_value        ,
	// ports of ['REG3_SW_RW1', 'FIELD_0']
	REG3_SW_RW1__FIELD_0__next_value        ,
	REG3_SW_RW1__FIELD_0__pulse             ,
	REG3_SW_RW1__FIELD_0__curr_value        ,
	// ports of ['REG4_SW_WO', 'FIELD_0']
	REG4_SW_WO__FIELD_0__next_value        ,
	REG4_SW_WO__FIELD_0__pulse             ,
	REG4_SW_WO__FIELD_0__curr_value        ,
	// ports of ['REG5_SW_W1', 'FIELD_0']
	REG5_SW_W1__FIELD_0__next_value        ,
	REG5_SW_W1__FIELD_0__pulse             ,
	REG5_SW_W1__FIELD_0__curr_value        ,
//**************************************INTERNAL FIELD PORT END***************************************//


//****************************************STANDARD PORT START*****************************************//
	fsm_clk                 ,
	fsm_rstn                ,
	req_vld                 ,
	ack_vld                 ,
	wr_en                   ,
	rd_en                   ,
	addr                    ,
	wr_data                 ,
	rd_data                 ,
	global_sync_reset_in    ,
	global_sync_reset_out
//*****************************************STANDARD PORT END******************************************//
);


//*************************************PARAMETER DEFINITION START*************************************//
	parameter                  ADDR_WIDTH = 64          ;
	parameter                  DATA_WIDTH = 32          ;
	//N:number of internal registers, M:number of external modules
	localparam                 N = 5                    ;
	localparam                 M = 0                    ;
	localparam                 REG_NUM = N ? N : 1      ;
	localparam                 EXT_NUM = M ? M : 1      ;
//**************************************PARAMETER DEFINITION END**************************************//


//***************************************PORT DECLARATION START***************************************//
	// regslv domain fsm_clk
	input                         fsm_clk                 ;
	input                         fsm_rstn                ;
	input                         req_vld                 ;
	output                        ack_vld                 ;
	input                         wr_en                   ;
	input                         rd_en                   ;
	input     [ADDR_WIDTH-1:0]    addr                    ;
	input     [DATA_WIDTH-1:0]    wr_data                 ;
	output    [DATA_WIDTH-1:0]    rd_data                 ;
	input                         global_sync_reset_in    ;
	output                        global_sync_reset_out   ;
	//ports define of internal regfile
	wire regfile_clk   = fsm_clk   ;
	wire regfile_rstn  = fsm_rstn  ;
	// ports of ['REG1_SW_RO', 'FIELD_0']
	input  [32-1:0]    REG1_SW_RO__FIELD_0__next_value        ;
	input              REG1_SW_RO__FIELD_0__pulse             ;
	output [32-1:0]    REG1_SW_RO__FIELD_0__curr_value        ;
	// ports of ['REG2_SW_RW', 'FIELD_0']
	input  [32-1:0]    REG2_SW_RW__FIELD_0__next_value        ;
	input              REG2_SW_RW__FIELD_0__pulse             ;
	output [32-1:0]    REG2_SW_RW__FIELD_0__curr_value        ;
	// ports of ['REG3_SW_RW1', 'FIELD_0']
	input  [32-1:0]    REG3_SW_RW1__FIELD_0__next_value        ;
	input              REG3_SW_RW1__FIELD_0__pulse             ;
	output [32-1:0]    REG3_SW_RW1__FIELD_0__curr_value        ;
	// ports of ['REG4_SW_WO', 'FIELD_0']
	input  [32-1:0]    REG4_SW_WO__FIELD_0__next_value        ;
	input              REG4_SW_WO__FIELD_0__pulse             ;
	output [32-1:0]    REG4_SW_WO__FIELD_0__curr_value        ;
	// ports of ['REG5_SW_W1', 'FIELD_0']
	input  [32-1:0]    REG5_SW_W1__FIELD_0__next_value        ;
	input              REG5_SW_W1__FIELD_0__pulse             ;
	output [32-1:0]    REG5_SW_W1__FIELD_0__curr_value        ;
//****************************************PORT DECLARATION END****************************************//


//***************************************WIRE DECLARATION START***************************************//
	// declare the handshake signal for fsm
	wire                   slv__fsm__ack_vld		;
	reg                    new_ack_launched		;
	reg                    fsm__slv__req_vld_ff  ;
	wire                   fsm__slv__req_vld_int ;
	reg                    fsm__slv__req_vld     ;
	// signal for fsm
	wire 						fsm__slv__wr_en		;
	wire 						fsm__slv__rd_en		;
	wire [ADDR_WIDTH-1:0] 		fsm__slv__addr		;
	wire [DATA_WIDTH-1:0] 		fsm__slv__wr_data	;
	wire [DATA_WIDTH-1:0]  		slv__fsm__rd_data	;
	// fsm state indicator
	wire				   		cs_is_idle			;
	reg                new_ack_lanuch            ;

	// signal for decoder
	// signal for global decoder @regslv domain
	logic [64-1:0] 			global_address	;
	logic [EXT_NUM-1:0] 	ext_sel			;
	logic 					int_selected	;
	logic 					ext_selected	;
	logic 					none_selected	;
	// signal for internal decoder @regfile domain
	logic [REG_NUM-1:0] 	reg_sel			;
	logic 					dummy_reg		;

	// signal for regfile split mux
	logic [REG_NUM-1:0] [DATA_WIDTH-1:0] regfile_reg_rd_data_in;

	// signal for external split mux
	wire [EXT_NUM-1:0]                     ext_req_vld_fsm      ;
	wire [EXT_NUM-1:0]                     ext_ack_vld_fsm      ;
	wire [EXT_NUM-1:0]                     ext_ack_fsm		    ;
	wire                                   ext_wr_en_fsm        ;
	wire                                   ext_rd_en_fsm        ;
	wire [ADDR_WIDTH-1:0]                  ext_addr_fsm         ;
	wire [DATA_WIDTH-1:0]                  ext_wr_data_fsm      ;
	wire [EXT_NUM-1:0] [DATA_WIDTH-1:0]    ext_rd_data_fsm      ;
	wire [DATA_WIDTH-1:0] 				   ext_rd_data_vld_fsm	;
	wire                                   ext_reg_ack_vld_fsm  ;

	// regfile signal in regslv domain
	wire [EXT_NUM-1:0]                     regfile_req_vld_fsm      ;
	wire                                   regfile_ack_vld_fsm      ;
	wire                                   regfile_wr_en_fsm        ;
	wire                                   regfile_rd_en_fsm        ;
	wire [ADDR_WIDTH-1:0]                  regfile_addr_fsm         ;
	wire [DATA_WIDTH-1:0]                  regfile_wr_data_fsm      ;
	wire [DATA_WIDTH-1:0]                  regfile_rd_data_fsm      ;

	// regfile signal in regfile domain
	wire [REG_NUM-1:0] wr_sel;
	wire [REG_NUM-1:0] rd_sel;
	wire [EXT_NUM-1:0]                     regfile_req_vld      ;
	wire                                   regfile_ack_vld      ;
	wire                                   regfile_rd_ack_vld   ;
	wire                                   regfile_wr_en        ;
	wire                                   regfile_rd_en        ;
	wire [ADDR_WIDTH-1:0]                  regfile_addr         ;
	wire [DATA_WIDTH-1:0]                  regfile_wr_data      ;
	wire [DATA_WIDTH-1:0]                  regfile_rd_data      ;
	logic [31:0] REG1_SW_RO_wr_data;
	logic REG1_SW_RO_wr_en;
	logic REG1_SW_RO_rd_en;
	logic [31:0] REG2_SW_RW_wr_data;
	logic REG2_SW_RW_wr_en;
	logic REG2_SW_RW_rd_en;
	logic [31:0] REG3_SW_RW1_wr_data;
	logic REG3_SW_RW1_wr_en;
	logic REG3_SW_RW1_rd_en;
	logic [31:0] REG4_SW_WO_wr_data;
	logic REG4_SW_WO_wr_en;
	logic REG4_SW_WO_rd_en;
	logic [31:0] REG5_SW_W1_wr_data;
	logic REG5_SW_W1_wr_en;
	logic REG5_SW_W1_rd_en;
//****************************************WIRE DECLARATION END****************************************//


//***************************************ADDRESS DECODER START****************************************//
	// global fsm_decoder @regslv domain
	assign global_address   = cs_is_idle ? addr : fsm__slv__addr;
	assign ext_selected     = | ext_sel;
	always_comb begin
			int_selected = 1'b0;
			ext_sel = {EXT_NUM{1'b0}};
			none_selected = 1'b0;
		unique casez (global_address)
			64'h0,64'h4,64'h8,64'hc,64'h10:int_selected = 1'b1;//
			default: none_selected = 1'b1;
		endcase
	end
	// internal regfile decoder @regfile domain
	always_comb begin
			reg_sel = {REG_NUM{1'b0}};
			dummy_reg = 1'b0;
		unique casez (regfile_addr)
			64'h0:reg_sel[0] = 1'b1;//['REG1_SW_RO']
			64'h4:reg_sel[1] = 1'b1;//['REG2_SW_RW']
			64'h8:reg_sel[2] = 1'b1;//['REG3_SW_RW1']
			64'hc:reg_sel[3] = 1'b1;//['REG4_SW_WO']
			64'h10:reg_sel[4] = 1'b1;//['REG5_SW_W1']
			default: dummy_reg = 1'b1;
		endcase
	end
//****************************************ADDRESS DECODER END*****************************************//


//************************************STATE MACHINE INSTANCE START************************************//
	slv_fsm #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
		slv_fsm_reg_top__reg_block_1 (
		.clk(fsm_clk), .rstn(fsm_rstn), .mst__fsm__req_vld(req_vld), .mst__fsm__wr_en(wr_en), .mst__fsm__rd_en(rd_en), .mst__fsm__addr(addr), .mst__fsm__wr_data(wr_data),
		.slv__fsm__rd_data(slv__fsm__rd_data), .slv__fsm__ack_vld(slv__fsm__ack_vld), .fsm__slv__req_vld(fsm__slv__req_vld),
		.fsm__slv__wr_en(fsm__slv__wr_en), .fsm__slv__rd_en(fsm__slv__rd_en), .fsm__slv__addr(fsm__slv__addr), .fsm__slv__wr_data(fsm__slv__wr_data),
		.fsm__mst__rd_data(rd_data), .fsm__mst__ack_vld(ack_vld),
		.external_reg_selected(ext_selected),
		.cs_is_idle(cs_is_idle),		.mst__fsm__sync_reset(global_sync_reset_in),
		.fsm__slv__sync_reset(global_sync_reset_out)
	);
	always@(posedge fsm_clk or negedge fsm_rstn) begin
		if(~fsm_rstn)begin
			new_ack_launched <= 1'b0;
			fsm__slv__req_vld_ff <= 1'b0;
		end
		else begin
			fsm__slv__req_vld_ff <= fsm__slv__req_vld;
			if(fsm__slv__req_vld & ! fsm__slv__req_vld_ff) new_ack_launched <= 1'b0;
			else if(| ext_ack_fsm) new_ack_launched <= 1'b1;
			else new_ack_launched <= 1'b0;
		end
	end

	assign fsm__slv__req_vld_int = fsm__slv__req_vld & !new_ack_launched;
//*************************************STATE MACHINE INSTANCE END*************************************//


//**************************************SPLIT MUX INSTANCE START**************************************//
	// regfile mux @regfile domain
	split_mux_2d #(.WIDTH(DATA_WIDTH), .CNT(N+1), .GROUP_SIZE(128), .SKIP_DFF_0(1), .SKIP_DFF_1(1)) rd_split_mux
	(.clk(regfile_clk), .rst_n(regfile_rstn),
	.din({regfile_reg_rd_data_in,{DATA_WIDTH{1'b0}}}), .sel({rd_sel, dummy_reg}),
	.dout(regfile_rd_data), .dout_vld(regfile_rd_ack_vld)
	);
//***************************************SPLIT MUX INSTANCE END***************************************//


//*****************************************ULTIMATE MUX START*****************************************//
	// select which to read out and transfer the corresponding vld signal @regslv domain
	assign slv__fsm__rd_data = regfile_ack_vld_fsm ? regfile_rd_data_fsm : 0;
	assign slv__fsm__ack_vld = regfile_ack_vld_fsm;
//******************************************ULTIMATE MUX END******************************************//


//******************************EXTERNAL MEMORY SNAPSHOT REGISTER START*******************************//
//*******************************EXTERNAL MEMORY SNAPSHOT REGISTER END********************************//


//*****************************EXTERNAL MEMORY CDC DELIVER INSTANT START******************************//
//******************************EXTERNAL MEMORY CDC DELIVER INSTANT END*******************************//


//*********************************REGFILE CDC DELIVER INSTANT START**********************************//
	assign regfile_req_vld_fsm = fsm__slv__req_vld & int_selected;
	assign regfile_wr_en_fsm = fsm__slv__wr_en & int_selected;
	assign regfile_rd_en_fsm = fsm__slv__rd_en & int_selected;
	assign regfile_wr_data_fsm = int_selected ? fsm__slv__wr_data : 0;
	assign regfile_addr_fsm = int_selected ? fsm__slv__addr : 0;
	assign wr_sel = {REG_NUM{regfile_wr_en}} & reg_sel;
	assign rd_sel = {REG_NUM{regfile_rd_en}} & reg_sel;
	assign regfile_ack_vld = regfile_rd_ack_vld | regfile_wr_en;
	assign regfile_req_vld       = regfile_req_vld_fsm    ;
	assign regfile_ack_vld_fsm   = regfile_ack_vld        ;
	assign regfile_wr_en         = regfile_wr_en_fsm      ;
	assign regfile_rd_en         = regfile_rd_en_fsm      ;
	assign regfile_addr          = regfile_addr_fsm       ;
	assign regfile_wr_data       = regfile_wr_data_fsm    ;
	assign regfile_rd_data_fsm   = regfile_rd_data        ;
//**********************************REGFILE CDC DELIVER INSTANT END***********************************//


//**************************************REG/FIELD INSTANCE START**************************************//
	//============================================REG INSTANT=============================================//
	//REG NAME: REG1_SW_RO//
	//REG HIERARCHY: ['REG1_SW_RO']//
	//REG ABSOLUTE_ADDR:64'h0//
	//REG OFFSET_ADDR:64'h64'h0//
	logic [31:0] REG1_SW_RO_o;
	assign REG1_SW_RO_wr_data = wr_sel[0] ? regfile_wr_data : 0;
	assign REG1_SW_RO_wr_en = wr_sel[0];
	assign REG1_SW_RO_rd_en = rd_sel[0];
	field
		//**************PARAMETER INSTANTIATE***************//
		#(
		.F_WIDTH               (32),
		.ARST_VALUE            (32'haaaaaaaa),
		.SW_TYPE               ({`SW_RO}),
		.SW_ONREAD_TYPE        ({`NA}),
		.SW_ONWRITE_TYPE       ({`NA}),
		.HW_TYPE               (`HW_RW),
		.PRECEDENCE            (`SW)
		)
	x__REG1_SW_RO__FIELD_0
		//*****************PORT INSTANTIATE*****************//
		(
		.clk                   (regfile_clk),
		.rst_n                 (regfile_rstn),
		.sync_rst              (1'b0),
		.sw_wr_data            (REG1_SW_RO_wr_data[31:0]),
		.sw_rd                 (REG1_SW_RO_rd_en),
		.sw_wr                 (REG1_SW_RO_wr_en),
		.write_protect_en      (1'b0),
		.sw_type_alter_signal  (1'b0),
		.swmod_out(),
		.swacc_out(),
		.hw_value              (REG1_SW_RO__FIELD_0__next_value),
		.hw_pulse              (REG1_SW_RO__FIELD_0__pulse),
		.field_value           (REG1_SW_RO__FIELD_0__curr_value)
		);
	always_comb begin
	REG1_SW_RO_o[31:0] = 32'h0;
		REG1_SW_RO_o[31:0] = REG1_SW_RO__FIELD_0__curr_value;
	end
	assign regfile_reg_rd_data_in[0] = REG1_SW_RO_o;
	//============================================REG INSTANT=============================================//
	//REG NAME: REG2_SW_RW//
	//REG HIERARCHY: ['REG2_SW_RW']//
	//REG ABSOLUTE_ADDR:64'h4//
	//REG OFFSET_ADDR:64'h64'h4//
	logic [31:0] REG2_SW_RW_o;
	assign REG2_SW_RW_wr_data = wr_sel[1] ? regfile_wr_data : 0;
	assign REG2_SW_RW_wr_en = wr_sel[1];
	assign REG2_SW_RW_rd_en = rd_sel[1];
	field
		//**************PARAMETER INSTANTIATE***************//
		#(
		.F_WIDTH               (32),
		.ARST_VALUE            (32'haaaaaaaa),
		.SW_TYPE               ({`SW_RW}),
		.SW_ONREAD_TYPE        ({`NA}),
		.SW_ONWRITE_TYPE       ({`NA}),
		.HW_TYPE               (`HW_RW),
		.PRECEDENCE            (`SW)
		)
	x__REG2_SW_RW__FIELD_0
		//*****************PORT INSTANTIATE*****************//
		(
		.clk                   (regfile_clk),
		.rst_n                 (regfile_rstn),
		.sync_rst              (1'b0),
		.sw_wr_data            (REG2_SW_RW_wr_data[31:0]),
		.sw_rd                 (REG2_SW_RW_rd_en),
		.sw_wr                 (REG2_SW_RW_wr_en),
		.write_protect_en      (1'b0),
		.sw_type_alter_signal  (1'b0),
		.swmod_out(),
		.swacc_out(),
		.hw_value              (REG2_SW_RW__FIELD_0__next_value),
		.hw_pulse              (REG2_SW_RW__FIELD_0__pulse),
		.field_value           (REG2_SW_RW__FIELD_0__curr_value)
		);
	always_comb begin
	REG2_SW_RW_o[31:0] = 32'h0;
		REG2_SW_RW_o[31:0] = REG2_SW_RW__FIELD_0__curr_value;
	end
	assign regfile_reg_rd_data_in[1] = REG2_SW_RW_o;
	//============================================REG INSTANT=============================================//
	//REG NAME: REG3_SW_RW1//
	//REG HIERARCHY: ['REG3_SW_RW1']//
	//REG ABSOLUTE_ADDR:64'h8//
	//REG OFFSET_ADDR:64'h64'h8//
	logic [31:0] REG3_SW_RW1_o;
	assign REG3_SW_RW1_wr_data = wr_sel[2] ? regfile_wr_data : 0;
	assign REG3_SW_RW1_wr_en = wr_sel[2];
	assign REG3_SW_RW1_rd_en = rd_sel[2];
	field
		//**************PARAMETER INSTANTIATE***************//
		#(
		.F_WIDTH               (32),
		.ARST_VALUE            (32'haaaaaaaa),
		.SW_TYPE               ({`SW_RW1}),
		.SW_ONREAD_TYPE        ({`NA}),
		.SW_ONWRITE_TYPE       ({`NA}),
		.HW_TYPE               (`HW_RW),
		.PRECEDENCE            (`SW)
		)
	x__REG3_SW_RW1__FIELD_0
		//*****************PORT INSTANTIATE*****************//
		(
		.clk                   (regfile_clk),
		.rst_n                 (regfile_rstn),
		.sync_rst              (1'b0),
		.sw_wr_data            (REG3_SW_RW1_wr_data[31:0]),
		.sw_rd                 (REG3_SW_RW1_rd_en),
		.sw_wr                 (REG3_SW_RW1_wr_en),
		.write_protect_en      (1'b0),
		.sw_type_alter_signal  (1'b0),
		.swmod_out(),
		.swacc_out(),
		.hw_value              (REG3_SW_RW1__FIELD_0__next_value),
		.hw_pulse              (REG3_SW_RW1__FIELD_0__pulse),
		.field_value           (REG3_SW_RW1__FIELD_0__curr_value)
		);
	always_comb begin
	REG3_SW_RW1_o[31:0] = 32'h0;
		REG3_SW_RW1_o[31:0] = REG3_SW_RW1__FIELD_0__curr_value;
	end
	assign regfile_reg_rd_data_in[2] = REG3_SW_RW1_o;
	//============================================REG INSTANT=============================================//
	//REG NAME: REG4_SW_WO//
	//REG HIERARCHY: ['REG4_SW_WO']//
	//REG ABSOLUTE_ADDR:64'hc//
	//REG OFFSET_ADDR:64'h64'hc//
	logic [31:0] REG4_SW_WO_o;
	assign REG4_SW_WO_wr_data = wr_sel[3] ? regfile_wr_data : 0;
	assign REG4_SW_WO_wr_en = wr_sel[3];
	assign REG4_SW_WO_rd_en = rd_sel[3];
	field
		//**************PARAMETER INSTANTIATE***************//
		#(
		.F_WIDTH               (32),
		.ARST_VALUE            (32'haaaaaaaa),
		.SW_TYPE               ({`SW_WO}),
		.SW_ONREAD_TYPE        ({`NA}),
		.SW_ONWRITE_TYPE       ({`NA}),
		.HW_TYPE               (`HW_RW),
		.PRECEDENCE            (`SW)
		)
	x__REG4_SW_WO__FIELD_0
		//*****************PORT INSTANTIATE*****************//
		(
		.clk                   (regfile_clk),
		.rst_n                 (regfile_rstn),
		.sync_rst              (1'b0),
		.sw_wr_data            (REG4_SW_WO_wr_data[31:0]),
		.sw_rd                 (REG4_SW_WO_rd_en),
		.sw_wr                 (REG4_SW_WO_wr_en),
		.write_protect_en      (1'b0),
		.sw_type_alter_signal  (1'b0),
		.swmod_out(),
		.swacc_out(),
		.hw_value              (REG4_SW_WO__FIELD_0__next_value),
		.hw_pulse              (REG4_SW_WO__FIELD_0__pulse),
		.field_value           (REG4_SW_WO__FIELD_0__curr_value)
		);
	always_comb begin
	REG4_SW_WO_o[31:0] = 32'h0;
	end
	assign regfile_reg_rd_data_in[3] = REG4_SW_WO_o;
	//============================================REG INSTANT=============================================//
	//REG NAME: REG5_SW_W1//
	//REG HIERARCHY: ['REG5_SW_W1']//
	//REG ABSOLUTE_ADDR:64'h10//
	//REG OFFSET_ADDR:64'h64'h10//
	logic [31:0] REG5_SW_W1_o;
	assign REG5_SW_W1_wr_data = wr_sel[4] ? regfile_wr_data : 0;
	assign REG5_SW_W1_wr_en = wr_sel[4];
	assign REG5_SW_W1_rd_en = rd_sel[4];
	field
		//**************PARAMETER INSTANTIATE***************//
		#(
		.F_WIDTH               (32),
		.ARST_VALUE            (32'haaaaaaaa),
		.SW_TYPE               ({`SW_W1}),
		.SW_ONREAD_TYPE        ({`NA}),
		.SW_ONWRITE_TYPE       ({`NA}),
		.HW_TYPE               (`HW_RW),
		.PRECEDENCE            (`SW)
		)
	x__REG5_SW_W1__FIELD_0
		//*****************PORT INSTANTIATE*****************//
		(
		.clk                   (regfile_clk),
		.rst_n                 (regfile_rstn),
		.sync_rst              (1'b0),
		.sw_wr_data            (REG5_SW_W1_wr_data[31:0]),
		.sw_rd                 (REG5_SW_W1_rd_en),
		.sw_wr                 (REG5_SW_W1_wr_en),
		.write_protect_en      (1'b0),
		.sw_type_alter_signal  (1'b0),
		.swmod_out(),
		.swacc_out(),
		.hw_value              (REG5_SW_W1__FIELD_0__next_value),
		.hw_pulse              (REG5_SW_W1__FIELD_0__pulse),
		.field_value           (REG5_SW_W1__FIELD_0__curr_value)
		);
	always_comb begin
	REG5_SW_W1_o[31:0] = 32'h0;
	end
	assign regfile_reg_rd_data_in[4] = REG5_SW_W1_o;
//***************************************REG/FIELD INSTANCE END***************************************//


//**************************************REG/FIELD INSTANCE START**************************************//
//***************************************REG/FIELD INSTANCE END***************************************//


endmodule
`default_nettype wire