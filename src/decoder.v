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
    output reg issue,
    output reg [`ROB_WID] rob_pos,
    output reg [6:0] opcode,
    output reg [2:0] funct3,
    output reg funct7,
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
    output reg is_store,

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

    input wire alu_done,
    input wire [`DATA_WID] alu_res,
    input wire [`ROB_WID] alu_res_rob_pos,

    input wire lsb_done,
    input wire [`DATA_WID] lsb_res,
    input wire [`ROB_WID] lsb_res_rob_pos,

    output wire [`ROB_WID] rob_rs1_pos,
    input wire rob_rs1_rdy,
    input wire [`DATA_WID] rob_rs1_val,
    output wire [`ROB_WID] rob_rs2_pos,
    input wire rob_rs2_rdy,
    input wire [`DATA_WID] rob_rs2_val,

    input wire [`ROB_WID] upd_rob_pos
);

assign reg_rs1 = inst[19:15];
assign reg_rs2 = inst[24:20];

assign rob_rs1_pos = reg_rs1_rob_pos;
assign rob_rs2_pos = reg_rs2_rob_pos;

always @(*) begin
    rob_pos = upd_rob_pos;
    opcode = inst[6:0];
    funct3 = inst[14:12];
    funct7 = inst[30];
    rd = inst[11:7];
    imm = 0;
    is_store = 0;
    pc = inst_pc;
    pre_j = inst_pre_j;

    issue = 0;
    rs1_rdy = 1;
    rs1_val = 0;
    rs1_rob_pos = 0;
    rs2_rdy = 1;
    rs2_val = 0;
    rs2_rob_pos = 0;

    if (rst || !inst_done || rollback) begin
    end else if (rdy) begin
        issue = 1;

        // RS LSB RoB 都可能更新依赖
        if (reg_rs1_rdy) begin
            rs1_val = reg_rs1_val;
        end else if (alu_done && reg_rs1_rob_pos == alu_res_rob_pos) begin
            rs1_val = alu_res;
        end else if (lsb_done && reg_rs1_rob_pos == lsb_res_rob_pos) begin
            rs1_val = lsb_res;
        end else if (rob_rs1_rdy) begin
            rs1_val = rob_rs1_val;
        end begin 
            rs1_val = 0;
            rs1_rdy = reg_rs1_rdy;
            rs1_rob_pos = reg_rs1_rob_pos;
        end

        if (reg_rs2_rdy) begin
            rs2_val = reg_rs2_val;
        end else if (alu_done && reg_rs2_rob_pos == alu_res_rob_pos) begin
            rs2_val = alu_res;
        end else if (lsb_done && reg_rs2_rob_pos == lsb_res_rob_pos) begin
            rs2_val = lsb_res;
        end else if (rob_rs2_rdy) begin
            rs2_val = rob_rs2_val;
        end begin 
            rs2_val = 0;
            rs2_rdy = reg_rs2_rdy;
            rs2_rob_pos = reg_rs2_rob_pos;
        end

        case (opcode)
            `OPCODE_L: begin
                lsb_en = 1;
                rs2_rdy = 1;
                rs2_val = 0;
                rs2_rob_pos = 0;
                imm = {{21{inst[31]}}, inst[30:20]};
            end
            `OPCODE_S: begin
                is_store = 1;
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
                rs_en = 1;
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
                rs_en = 1;
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

`endif