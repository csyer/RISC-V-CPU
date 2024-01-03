`ifndef DECODER
`define DECODER

`include "def.v"

module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    input wire inst_done,
    input wire [`INST_WID] inst,
    input wire [`ADDR_WID] inst_pc,

    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire funct7,

    output wire [`REG_WID] reg_rs1,
    input wire [`DATA_WID] reg_rs1_v,
    input wire [`ROB_WID] reg_rs1_q,
    output wire [`REG_WID] reg_rs2,
    input wire [`DATA_WID] reg_rs2_v,
    input wire [`ROB_WID] reg_rs2_q

    output reg done,
);

always @(*) begin
    opcode = inst[6:0];
    funct3 = inst[14:12];
    funct7 = inst[30];

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