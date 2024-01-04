`ifndef RS
`define RS

`include "def.v"

`define RS_SIZ 16
`define RS_NPOS 5'd16

module RS(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    // 调用结束后 RS 是否满
    output reg rs_full,

    input wire rs_en,
    input wire [`ROB_WID] rs_rob_pos,
    input wire [6:0] rs_opcode,
    input wire [2:0] rs_funct3,
    input wire rs_funct7,
    input wire rs_rs1_rdy,
    input wire [`DATA_WID] rs_rs1_val,
    input wire [`ROB_WID] rs_rs1_rob_pos,
    input wire rs_rs2_rdy,
    input wire [`DATA_WID] rs_rs2_val,
    input wire [`ROB_WID] rs_rs2_rob_pos,
    input wire [`DATA_WID] rs_imm,
    input wire [`ADDR_WID] rs_pc,

    output reg alu_en,
    output reg [`ROB_WID] alu_rob_pos,
    output reg [6:0] alu_opcode,
    output reg [2:0] alu_funct3,
    output reg alu_funct7,
    output reg [`DATA_WID] alu_val1,
    output reg [`DATA_WID] alu_val2,
    output reg [`DATA_WID] alu_imm,

    input wire alu_done,
    input wire [`DATA_WID] alu_res,
    input wire [`ROB_WID] alu_res_rob_pos
);

reg busy[`RS_SIZ - 1:0];
reg ready[`RS_SIZ - 1:0];
reg [`ROB_WID] rob_pos[`RS_SIZ - 1:0];
reg [6:0] opcode[`RS_SIZ - 1:0];
reg [2:0] funct3[`RS_SIZ - 1:0];
reg funct7[`RS_SIZ - 1:0];
reg rs1_rdy[`RS_SIZ - 1:0];
reg [`DATA_WID] rs1_val[`RS_SIZ - 1:0];
reg [`ROB_WID] rs1_rob_pos[`RS_SIZ - 1:0];
reg rs2_rdy[`RS_SIZ - 1:0];
reg [`DATA_WID] rs2_val[`RS_SIZ - 1:0];
reg [`ROB_WID] rs2_rob_pos[`RS_SIZ - 1:0];
reg [`DATA_WID] imm[`RS_SIZ - 1:0];
reg [`ADDR_WID] pc[`RS_SIZ - 1:0];

reg [4:0] free_pos;
reg [4:0] ready_pos;

integer i;
always @(*) begin
    free_pos = `RS_NPOS;
    ready_pos = `RS_NPOS;
    rs_full = 1;
    for (i = 0; i < `RS_SIZ; i = i + 1) begin
        if (!busy[i]) begin
            if (i != free_pos || !rs_en) rs_full = 0;
            free_pos = i;
        end
        if (busy[i] && rs1_rdy[i] && rs2_rdy[i]) begin
            ready[i] = 1;
            ready_pos = i;
        end else ready[i] = 0;
    end
end

integer j, k;
always @(posedge clk) begin
    if (rst || rollback) begin
        for (j = 0; j < `RS_SIZ; j = j + 1) begin
            busy[j] <= 0;
        end
        alu_en <= 0;
    end else if (rdy) begin
        if (rs_en) begin
            busy[free_pos] <= 1;
            rob_pos[free_pos] <= rs_rob_pos;
            opcode[free_pos] <= rs_opcode;
            funct3[free_pos] <= rs_funct3;
            funct7[free_pos] <= rs_funct7;
            rs1_rdy[free_pos] <= rs_rs1_rdy;
            rs1_val[free_pos] <= rs_rs1_val;
            rs1_rob_pos[free_pos] <= rs_rs1_rob_pos;
            rs2_rdy[free_pos] <= rs_rs2_rdy;
            rs2_val[free_pos] <= rs_rs2_val;
            rs2_rob_pos[free_pos] <= rs_rs2_rob_pos;
            imm[free_pos] <= rs_imm;
            pc[free_pos] <= rs_pc;
        end
        if (ready_pos != `RS_NPOS) begin
            alu_en <= 1;
            alu_opcode <= opcode[ready_pos];
            alu_funct3 <= funct3[ready_pos];
            alu_funct7 <= funct7[ready_pos];
            alu_val1 <= rs1_val[ready_pos];
            alu_val2 <= rs2_val[ready_pos];
            alu_imm <= imm[ready_pos];
            busy[ready_pos] <= 0;
        end

        // RS 收到 ALU 的值之后广播
        // 感觉不如直接在 ALU 广播。。这样所有元件都能收到。。
        if (alu_done) begin
            for (k = 0; k < `RS_SIZ; k = k + 1) begin
                if (rs1_rob_pos[k] == alu_res_rob_pos && !rs1_rdy[k]) begin
                    rs1_rdy[k] <= 1;
                    rs1_rob_pos[k] <= 0;
                    rs1_val[k] <= alu_res;
                end
                if (rs2_rob_pos[k] == alu_res_rob_pos && !rs2_rdy[k]) begin
                    rs2_rdy[k] <= 1;
                    rs2_rob_pos[k] <= 0;
                    rs2_val[k] <= alu_res;
                end
            end
        end
    end
end

endmodule

`endif