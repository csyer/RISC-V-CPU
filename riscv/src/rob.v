`ifndef ROB
`define ROB

`include "def.v"

module RoB(
    input wire clk,
    input wire rst,
    input wire rdy,

    output reg rollback,

    output wire rob_full,

    output wire [`ROB_WID] rob_head_pos,

    input wire issue,
    input wire [`ADDR_WID] issue_pc,
    input wire [6:0] issue_opcode,
    input wire [`REG_WID] issue_rd,
    input wire issue_pre_j,

    // commit to regfile
    output reg commit_reg,
    output reg [`REG_WID] commit_reg_rd,
    output reg [`DATA_WID] commit_reg_val,

    // commit to Ifetch / predictor
    output reg commit_br,
    output reg commit_br_j,
    output reg [`ADDR_WID] commit_br_pc,
    output reg [`ADDR_WID] commit_res_pc,

    // commit to LSB
    output reg lsb_store,

    output reg [`ROB_WID] commit_rob_pos,

    input wire alu_done,
    input wire [`DATA_WID] alu_res,
    input wire alu_res_j,
    input wire [`ADDR_WID] alu_res_pc,
    input wire [`ROB_WID] alu_res_rob_pos,

    input wire lsb_done,
    input wire [`DATA_WID] lsb_res,
    input wire [`ROB_WID] lsb_res_rob_pos,

    output wire [`ROB_WID] upd_rob_pos,

    input wire [`ROB_WID] rs1_rob_pos,
    output wire rs1_rdy,
    output wire [`DATA_WID] rs1_val,
    input wire [`ROB_WID] rs2_rob_pos,
    output wire rs2_rdy,
    output wire [`DATA_WID] rs2_val
);

reg ready[`ROB_SIZ - 1:0];
reg [`ADDR_WID] pc[`ROB_SIZ - 1:0];
reg [6:0] opcode[`ROB_SIZ - 1:0];
reg [`REG_WID] rd[`ROB_SIZ - 1:0];
reg [`DATA_WID] val[`ROB_SIZ - 1:0];
reg res_j[`ROB_SIZ - 1:0];
reg [`ADDR_WID] res_pc[`ROB_SIZ - 1:0];
reg pre_j[`ROB_SIZ - 1:0];

reg [`ROB_WID] head;
reg [`ROB_WID] tail;
reg is_empty;

wire commit = !is_empty && ready[head];
wire [`ROB_WID] nxt_head = head + commit;
wire [`ROB_WID] nxt_tail = tail + issue;
wire nxt_empty = nxt_head == nxt_tail && (is_empty || commit && !issue);

assign rob_full = nxt_head == nxt_tail && !nxt_empty;
assign rob_head_pos = head;
assign upd_rob_pos = tail;

assign rs1_rdy = ready[rs1_rob_pos];
assign rs1_val = val[rs1_rob_pos];
assign rs2_rdy = ready[rs2_rob_pos];
assign rs2_val = val[rs2_rob_pos];

integer i;
always @(posedge clk) begin
    // $display("RoB: %D %D %D", head, tail, is_empty);
    if (rst || rollback) begin
        head <= 0;
        tail <= 0;
        is_empty <= 1;
        rollback <= 0;
        commit_br <= 0;
        lsb_store <= 0;
        commit_reg <= 0;
        for (i = 0; i < `ROB_SIZ; i = i + 1) begin
            ready[i] <= 0;
            pc[i] <= 0;
            opcode[i] <= 0;
            rd[i] <= 0;
            val[i] <= 0;
            res_j[i] <= 0;
            res_pc[i] <= 0;
            pre_j[i] <= 0;
        end
    end else if (rdy) begin
        is_empty <= nxt_empty;
        if (issue) begin
            // $display("issue %D %H %B", tail, issue_pc, issue_opcode);
            if (issue_opcode == `OPCODE_S) ready[tail] <= 1;
            else ready[tail] <= 0;
            pc[tail] <= issue_pc;
            opcode[tail] <= issue_opcode;
            rd[tail] <= issue_rd;
            pre_j[tail] <= issue_pre_j;
            tail = tail + 1;
        end

        if (alu_done) begin
            // $display("alu upd %D %D %D %H", alu_res_rob_pos, alu_res, ready[alu_res_rob_pos], alu_res_pc);
            ready[alu_res_rob_pos] <= 1;
            val[alu_res_rob_pos] <= alu_res;
            res_j[alu_res_rob_pos] <= alu_res_j;
            res_pc[alu_res_rob_pos] <= alu_res_pc;
        end
        if (lsb_done) begin
            // $display("lsb upd %D %D %D", lsb_res_rob_pos, lsb_res, ready[lsb_res_rob_pos]);
            ready[lsb_res_rob_pos] <= 1;
            val[lsb_res_rob_pos] <= lsb_res;
        end

        commit_reg <= 0;
        commit_br <= 0;
        lsb_store <= 0;
        if (commit) begin
            // $display("commit %D %H %B", head, pc[head], opcode[head]);
            commit_rob_pos <= head;
            case (opcode[head])
                `OPCODE_S: begin
                    lsb_store <= 1;
                end
                `OPCODE_B: begin
                    // $display("commit branch %D %H", res_j[head], pc[head]);
                    commit_br <= 1;
                    commit_br_j <= res_j[head];
                    commit_br_pc <= pc[head];
                    if (pre_j[head] != res_j[head]) begin
                        // $display("commit rollback");
                        rollback <= 1;
                        commit_res_pc <= res_pc[head];
                    end
                end
                `OPCODE_JALR: begin
                    // $display("new pc %H", res_pc[head]);
                    commit_reg <= 1;
                    commit_reg_rd <= rd[head];
                    commit_reg_val <= val[head];
                    rollback <= 1;
                    commit_res_pc <= res_pc[head];
                end
                default: begin // CAL, CALI, L, LUI, AUIPC, JAL
                    // $display("commit reg %D %D", rd[head], val[head]);
                    commit_reg <= 1;
                    commit_reg_rd <= rd[head];
                    commit_reg_val <= val[head];
                end
            endcase
            head <= head + 1;
        end
    end
end

endmodule

`endif