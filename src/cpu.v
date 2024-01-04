// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "memctrl.v"

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire rollback;

wire rs_full;
wire lsb_full;
wire rob_full;

wire if_to_mem_en;
wire [`ADDR_WID] if_to_mem_pc;
wire mem_to_if_done;
wire [`ICACHE_LINE_WID] mem_to_if_data;

wire lsb_to_mem_en;
wire lsb_to_mem_wr;
wire [`ADDR_WID] lsb_to_mem_a;
wire [2:0] lsb_to_mem_l;
wire [`DATA_WID] lsb_to_mem_w;
wire [`DATA_WID] mem_to_lsb_r;
wire mem_to_lsb_done;

MemCtrl mem_ctrl(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .rollback(rollback),

    .mem_din(mem_din),
    .mem_dout(mem_dout),
    .mem_a(mem_a),
    .mem_wr(mem_wr),

    .if_en(if_to_mem_en),
    .if_pc(if_to_mem_pc),
    .if_done(mem_to_if_done),
    .if_data(mem_to_if_data),

    .lsb_en(lsb_to_mem_en),
    .lsb_wr(lsb_to_mem_wr),
    .lsb_a(lsb_to_mem_a),
    .lsb_l(lsb_to_mem_l),
    .lsb_w(lsb_to_mem_w),
    .lsb_r(mem_to_lsb_r),
    .lsb_done(mem_to_lsb_done),

    .io_buffer_full(io_buffer_full)
);

wire if_to_mem_en;
wire [`ADDR_WID] if_to_mem_pc;
wire mem_to_if_done;
wire [`DATA_WID] mem_to_if_data;

wire if_to_dec_done;
wire [`INST_WID] if_to_dec_inst;
wire [`ADDR_WID] if_to_dec_pc;
wire if_to_dec_pre_j;

wire rob_to_if_br;
wire rob_to_if_br_j;
wire [`ADDR_WID] rob_to_if_br_pre_pc;
wire [`ADDR_WID] rob_to_if_br_res_pc;

IFetch ifetch(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .rollback(rollback),

    .rs_full(rs_full),
    .lsb_full(lsb_full),
    .rob_full(rob_full),

    .mem_en(if_to_mem_en),
    .mem_pc(if_to_mem_pc),
    .mem_done(mem_to_if_done),
    .mem_data(mem_to_if_data),

    .inst_done(if_to_dec_done),
    .inst(if_to_dec_inst),
    .inst_pc(if_to_dec_pc),
    .inst_pre_j(if_to_dec_pre_j),

    .br_pre(rob_to_if_br),
    .br_pre_j(rob_to_if_br_j),
    .br_pre_pc(rob_to_if_br_pre_pc),
    .br_res_pc(rob_to_if_br_res_pc)
)

wire [`REG_WID] dec_to_reg_rs1;
wire reg_to_dec_rs1_rdy;
wire [`DATA_WID] reg_to_dec_rs1_val;
wire [`ROB_WID] reg_to_dec_rs1_rob_pos;
wire [`REG_WID] dec_to_reg_rs2;
wire reg_to_dec_rs2_rdy;
wire [`DATA_WID] reg_to_dec_rs2_val;
wire [`ROB_WID] reg_to_dec_rs2_rob_pos;

wire issue;
wire [`REG_WID] issue_rd;
wire [`ROB_WID] issue_rob_pos;

wire rob_to_reg_commit;
wire [`REG_WID] rob_to_reg_rd;
wire [`DATA_WID] rob_to_reg_val;
wire [`ROB_WID] rob_to_reg_pos;

RegFile reg_file(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .rollback(rollback),

    .rs1(dec_to_reg_rs1),
    .rs1_rdy(reg_to_dec_rs1_rdy),
    .rs1_val(reg_to_dec_rs1_val),
    .rs1_rob_pos(reg_to_dec_rs1_rob_pos),
    .rs2(dec_to_reg_rs2),
    .rs2_rdy(reg_to_dec_rs2_rdy),
    .rs2_val(reg_to_dec_rs2_val),
    .rs2_rob_pos(reg_to_dec_rs2_rob_pos),

    .issue(issue),
    .issue_rd(issue_rd),
    .issue_rob_pos(issue_rob_pos),

    .commit(rob_to_reg_commit),
    .commit_rd(rob_to_reg_rd),
    .commit_val(rob_to_reg_val),
    .commit_rob_pos(rob_to_reg_pos)
);

wire [6:0] issue_opcode;
wire [2:0] issue_funct3;
wire issue_funct7;
wire issue_rs1_rdy;
wire [`DATA_WID] issue_rs1_val;
wire [`ROB_WID] issue_rs1_rob_pos,
wire issue_rs2_rdy;
wire [`DATA_WID] issue_rs2_val;
wire [`ROB_WID] issue_rs2_rob_pos;
wire [`DATA_WID] issue_imm;
wire [`ADDR_WID] issue_pc;
wire issue_pre_j;

wire dec_to_rs_en;
wire dec_to_lsb_en;

wire alu_to_dec_done;
wire [`DATA_WID] alu_to_dec_res;
wire [`ROB_WID] alu_to_dec_rob_pos;

wire lsb_to_dec_done;
wire [`DATA_WID] lsb_to_dec_res;
wire [`ROB_WID] lsb_to_dec_rob_pos;

wire [`ROB_WID]  dec_to_rob_rs1_pos;
wire rob_to_dec_rs1_rdy;
wire [`DATA_WID] rob_to_dec_rs1_val;
wire [`ROB_WID]  dec_to_rob_rs2_pos;
wire rob_to_dec_rs2_rdy;
wire [`DATA_WID] rob_to_dec_rs2_val;

wire [`ROB_WID] rob_to_dec_upd_pos;

Decoder decoder(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .rollback(rollback),

    .inst_done(if_to_dec_done),
    .inst(if_to_dec_inst),
    .inst_pc(if_to_dec_pc),
    .inst_pre_j(if_to_dec_pre_j),

    .issue(issue),
    .rob_pos(issue_rob_pos),
    .opcode(issue_opcode),
    .funct3(issue_funct3),
    .funct7(issue_funct7),
    .rs1_rdy(issue_rs1_rdy),
    .rs1_val(issue_rs1_val),
    .rs1_rob_pos(issue_rs1_rob_pos),
    .rs2_rdy(issue_rs2_rdy),
    .rs2_val(issue_rs2_val),
    .rs2_rob_pos(issue_rs2_rob_pos),
    .imm(issue_imm),
    .rd(issue_rd),
    .pc(issue_pc),
    .pre_j(issue_pre_j),

    .reg_rs1(dec_to_reg_rs1),
    .reg_rs1_rdy(reg_to_dec_rs1_rdy),
    .reg_rs1_val(reg_to_dec_rs1_val),
    .reg_rs1_rob_pos(reg_to_dec_rs1_rob_pos),
    .reg_rs2(dec_to_reg_rs2),
    .reg_rs2_rdy(reg_to_dec_rs2_rdy),
    .reg_rs2_val(reg_to_dec_rs2_val),
    .reg_rs2_rob_pos(reg_to_dec_rs2_rob_pos),

    .rs_en(dec_to_rs_en),
    .lsb_en(dec_to_lsb_en),

    .alu_done(alu_to_dec_done),
    .alu_res(alu_to_dec_res),
    .alu_res_rob_pos(alu_to_dec_rob_pos),

    .lsb_done(lsb_to_dec_done),
    .lsb_res(lsb_to_dec_res),
    .lsb_res_rob_pos(lsb_to_dec_rob_pos),

    .rob_rs1_pos(dec_to_rob_rs1_pos),
    .rob_rs1_rdy(rob_to_dec_rs1_rdy),
    .rob_rs1_val(rob_to_dec_rs1_val),
    .rob_rs2_pos(dec_to_rob_rs2_pos),
    .rob_rs2_rdy(rob_to_dec_rs2_rdy),
    .rob_rs2_val(rob_to_dec_rs2_val),

    .upd_rob_pos(rob_to_dec_upd_pos)
);

endmodule