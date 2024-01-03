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
    input wire inst_pre_j,

    // issue
    output reg done,
    output reg [`ROB_WID] rob_pos,
    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire funct7,
    output reg rs1_rdy,
    output reg [`DATA_WID] rs1_val,
    output reg [`ROB_WID] rs1_rob_pos,
    output reg rs2_rdy,
    output reg [`DATA_WID] rs2_val,
    output reg [`ROB_WID] rs2_rob_pos,
    output reg [`DATA_WID] imm,
    output reg [`REG_WID] rd,
    output reg [`ADDR_WID] pc,
    output reg pre_j,

    // query from RegFile
    output wire [`REG_WID] reg_rs1,
    input wire reg_rs1_rdy,
    input wire [`DATA_WID] reg_rs1_val,
    input wire [`ROB_WID] reg_rs1_rob_pos,
    output wire [`REG_WID] reg_rs2,
    input wire reg_rs2_rdy,
    input wire [`DATA_WID] reg_rs2_val,
    input wire [`ROB_WID] reg_rs2_rob_pos,

    output reg rs_en,
    output reg lsb_en,

    output is_ready
);

assign reg_rs1 = inst[19:15];
assign reg_rs2 = inst[24:20];

always @(*) begin
    opcode = inst[6:0];
    funct3 = inst[14:12];
    funct7 = inst[30];
    rd = inst[11:7];
    imm = 0;
    pc = inst_pc;
    pre_j = inst_pre_j;

    is_ready = 0;

    if (rst || !inst_done || rollback) begin
        issue = 0;
        rs1_rdy = 1;
        rs1_val = 0;
        rs1_rob_pos = 0;
        rs2_rdy = 1;
        rs2_val = 0;
        rs2_rob_pos = 0;
    end else if (rdy) begin
        issue = 1;

        // 这里应该有一步 Snoop 之后再写
        // TODO
        rs1_rdy = reg_rs1_rdy;
        rs1_val = reg_rs1_val;
        rs1_rob_pos = reg_rs1_rob_pos;
        rs2_rdy = reg_rs2_rdy;
        rs2_val = reg_rs2_val;
        rs2_rob_pos = reg_rs2_rob_pos;

        case (opcode)
            `OPCODE_L: begin
                lsb_en = 1;
                rs2_rdy = 1;
                rs2_val = 0;
                rs2_rob_pos = 0;
                imm = {{21{inst[31]}}, inst[30:20]};
            end
            `OPCODE_S: begin
                is_ready = 1;
                lsb_en = 1;
                rd = 0;
                imm = {{21{inst[31]}}, inst[30:20]};
            end
            `OPCODE_CAL: begin
                rs_en = 1;
            end
            `OPCODE_CALI: begin
                rs_en = 1;
                rs2_rdy = 1;
                rs2_val = 0;
                rs2_rob_pos = 0;
                imm = {{21{inst[31]}}, inst[30:20]};
            end
            `OPCODE_B: begin
                rs_en = 1;
                rd = 0;
                imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            end
            `OPCODE_LUI: begin
                is_ready = 1;
                rs1_rdy = 1;
                rs1_val = 0;
                rs1_rob_pos = 0;
                rs2_rdy = 1;
                rs2_val = 0;
                rs2_rob_pos = 0;
                imm = {inst[31:12], 12'b0};
            end
            `OPCODE_AUIPC: begin
                rs_en = 1;
                rs1_rdy = 1;
                rs1_val = 0;
                rs1_rob_pos = 0;
                rs2_rdy = 1;
                rs2_val = 0;
                rs2_rob_pos = 0;
                imm = {inst[31:12], 12'b0};
            end
            `OPCODE_JAL: begin
                is_ready = 1;
                rs1_rdy = 1;
                rs1_val = 0;
                rs1_rob_pos = 0;
                rs2_rdy = 1;
                rs2_val = 0;
                rs2_rob_pos = 0;
                imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            `OPCODE_JALR: begin
                rs_en = 1;
                rs2_rdy = 1;
                rs2_val = 0;
                rs2_rob_pos = 0;
                imm = {{21{inst[31]}}, inst[30:20]};
            end
        endcase
    end
end

endmodule