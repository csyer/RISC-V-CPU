`ifndef DECODER
`define DECODER

`include "def.v"

module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    // fetch from IFetch
    input wire inst_done,
    input wire [`INST_WID] inst,
    input wire [`ADDR_WID] inst_pc,
    input wire pre_j,

    // issue
    output reg done,
    output reg [`ROB_WID] rob_pos,
    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire funct7,
    output reg rdy1,
    output reg [`DATA_WID] val1,
    output reg [`ROB_WID] pos1,
    output reg rdy2,
    output reg [`DATA_WID] val2,
    output reg [`ROB_WID] pos2,
    output reg [`DATA_WID] imm,
    output reg [`REG_WID] rd,

    // query from RegFile
    output wire [`REG_WID] reg_rs1,
    input wire reg_rdy1,
    input wire [`DATA_WID] reg_val1,
    input wire [`ROB_WID] reg_pos1,
    output wire [`REG_WID] reg_rs2,
    input wire reg_rdy2,
    input wire [`DATA_WID] reg_val2,
    input wire [`ROB_WID] reg_pos2
);

assign reg_rs1 = inst[19:15];
assign reg_rs2 = inst[24:20];

always @(*) begin
    opcode = inst[6:0];
    funct3 = inst[14:12];
    funct7 = inst[30];
    rd = inst[11:7];
    imm = 0;

    if (rst) begin
        // TODO
    end else if (rdy) begin
        case (opcode)
            `OPCODE_L: begin
            end
            `OPCODE_S: begin
            end
            `OPCODE_CAL: begin
            end
            `OPCODE_CALI: begin
            end
            `OPCODE_B: begin
            end
            `OPCODE_LUI: begin
            end
            `OPCODE_AUIPC: begin
            end
            `OPCODE_JAL: begin
            end
            `OPCODE_JALR: begin
            end
        endcase
    end
end

endmodule