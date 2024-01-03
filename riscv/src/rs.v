`ifndef RS
`define RS

`include "def.v"

`define RS_SIZ 16

module RS(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    output reg rs_full,

    input wire rs_en,
    input wire [`ROB_WID] rs_rob_pos,
    input wire [6:0] rs_opcode,
    input wire [2:0] rs_funct3,
    input wire rs_funct7,
    input reg rs_rs1_rdy,
    input reg [`DATA_WID] rs_rs1_val,
    input reg [`ROB_WID] rs_rs1_rob_pos,
    input reg rs_rs2_rdy,
    input reg [`DATA_WID] rs_rs2_val,
    input reg [`ROB_WID] rs_rs2_rob_pos,
    input reg [`DATA_WID] rs_imm,

    output reg alu_en,
    output [6:0] alu_opcode,
    output wire [2:0] alu_funct3,
    output wire alu_funct7,
    output reg [`DATA_WID] alu_val1,
    output reg [`DATA_WID] alu_val2,
    output reg [`DATA_WID] alu_imm,

    input wire alu_res
);

reg busy[`RS_SIZ - 1:0];
reg ready[`RS_SIZ - 1:0];
reg [`ROB_WID] rs_rob_pos[`RS_SIZ - 1:0],
reg [6:0] rs_opcode[`RS_SIZ - 1:0],
reg [2:0] rs_funct3[`RS_SIZ - 1:0],
reg rs_funct7[`RS_SIZ - 1:0],
reg rs_rs1_rdy[`RS_SIZ - 1:0],
reg [`DATA_WID] rs_rs1_val[`RS_SIZ - 1:0],
reg [`ROB_WID] rs_rs1_rob_pos[`RS_SIZ - 1:0],
reg rs_rs2_rdy[`RS_SIZ - 1:0],
reg [`DATA_WID] rs_rs2_val[`RS_SIZ - 1:0],
reg [`ROB_WID] rs_rs2_rob_pos[`RS_SIZ - 1:0],
reg [`DATA_WID] rs_imm[`RS_SIZ - 1:0],

always @(posedge clk) begin
    if (rst) begin
        // TODO
    end else if (rdy) begin
        // TODO
    end
end

endmodule

`endif