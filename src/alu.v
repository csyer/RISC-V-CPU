`ifndef ALU
`define ALU

`include "def.v"

`define FUNCT3_ADD  3'b000
`define FUNCT3_SLL  3'b001
`define FUNCT3_SLT  3'b010
`define FUNCT3_SLTU 3'b011
`define FUNCT3_XOR  3'b100
`define FUNCT3_SRL  3'b101
`define FUNCT3_SRA  3'b101
`define FUNCT3_OR   3'b110
`define FUNCT3_AND  3'b111

`define FUNCT3_BEQ  3'b000
`define FUNCT3_BNE  3'b001
`define FUNCT3_BLT  3'b100
`define FUNCT3_BGE  3'b101
`define FUNCT3_BLTU 3'b110
`define FUNCT3_BGEU 3'b111

module ALU(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    input wire alu_en,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire funct7,
    input wire [`DATA_WID] val1,
    input wire [`DATA_WID] val2,
    input wire [`DATA_WID] imm,
    input wire [`ROB_WID] rob_pos,
    input wire [`ADDR_WID] pc,

    output reg res_done,
    output reg [`ROB_WID] res_rob_pos,
    output reg [`DATA_WID] res_cal,
    output reg [`ADDR_WID] res_pc,
    output reg res_j
);

wire [`DATA_WID] lhs = val1;
wire [`DATA_WID] rhs = opcode == `OPCODE_CAL ? val2 : imm;
reg [`DATA_WID] cal;
always @(*) begin
    case (funct3) 
        `FUNCT3_ADD: begin
            if (funct7 && opcode == `OPCODE_CAL) 
                cal = lhs - rhs;
            else cal = lhs + rhs;
        end
        `FUNCT3_XOR: cal = lhs ^ rhs;
        `FUNCT3_OR: cal = lhs | rhs;
        `FUNCT3_AND: cal = lhs & rhs;
        `FUNCT3_SLL: cal = lhs << rhs;
        `FUNCT3_SRL: begin
            if (funct7) cal = $signed(lhs) >> rhs[5:0];
            else cal = lhs >> rhs[5:0];
        end
        `FUNCT3_SLT: cal = ($signed(lhs) < $signed(rhs));
        `FUNCT3_SLTU: cal = (lhs < rhs);
    endcase
end

reg cmp;
always @(*) begin
    case (funct3)
      `FUNCT3_BEQ: cmp = (val1 == val2);
      `FUNCT3_BNE: cmp = (val1 != val2);
      `FUNCT3_BLT: cmp = ($signed(val1) < $signed(val2));
      `FUNCT3_BGE: cmp = ($signed(val1) >= $signed(val2));
      `FUNCT3_BLTU: cmp = (val1 < val2);
      `FUNCT3_BGEU: cmp = (val1 >= val2);
      default: cmp = 0;
    endcase
end

always @(posedge clk) begin
    if (rst || rollback) begin 
        res_done <= 0;
        res_rob_pos <= 0;
        res_cal <= 0;
        res_pc <= 0;
        res_j <= 0;
    end else if (rdy) begin
        res_done <= 0;
        if (alu_en) begin
            res_done <= 1;
            res_rob_pos <= rob_pos;
            res_j <= 0;
            case (opcode)
                `OPCODE_CAL: res_cal <= cal;
                `OPCODE_CALI: res_cal <= cal;
                `OPCODE_LUI: res_cal <= imm;
                `OPCODE_AUIPC: res_cal <= pc + imm;
                `OPCODE_B:
                    if (cmp) begin
                        res_j <= 1;
                        res_pc <= pc + imm;
                    end else res_pc <= pc + 4;
                `OPCODE_JAL: begin
                    res_j <= 1;
                    res_cal <= pc + 4;
                    res_pc  <= pc + imm;
                end
                `OPCODE_JALR: begin
                    res_j <= 1;
                    res_cal <= pc + 4;
                    res_pc  <= val1 + imm;
                end
            endcase
        end
    end
end

endmodule

`endif