`ifndef LSB
`define LSB

`include "def.v"

`define FUNCT3_LB  3'b000
`define FUNCT3_LH  3'b001
`define FUNCT3_LW  3'b010
`define FUNCT3_LBU 3'b100
`define FUNCT3_LHU 3'b101

`define FUNCT3_SB  3'b000
`define FUNCT3_SH  3'b001
`define FUNCT3_SW  3'b010

`define LSB_SIZ 16
`define LSB_WID 3:0
`define LSB_NPOS 5'd16

module LSB(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    output reg lsb_full,

    input wire lsb_en,
    input wire [`ROB_WID] lsb_rob_pos,
    input wire lsb_ls, // 0: Load; 1: Store
    input wire [2:0] lsb_funct3,
    input wire lsb_rs1_rdy,
    input wire [`DATA_WID] lsb_rs1_val,
    input wire [`ROB_WID] lsb_rs1_rob_pos,
    input wire lsb_rs2_rdy,
    input wire [`DATA_WID] lsb_rs2_val,
    input wire [`ROB_WID] lsb_rs2_rob_pos,
    input wire [`DATA_WID] lsb_imm,

    output reg mem_en,
    output reg mem_wr,
    output reg [`ADDR_WID] mem_a,
    output reg [2:0] mem_l,
    output reg [`DATA_WID] mem_w,
    input wire mem_done,
    input wire mem_r,

    output reg done,
    output reg [`DATA_WID] res,
    output reg [`ROB_WID] res_rob_pos,

    input wire alu_done,
    input wire [`DATA_WID] alu_res,
    input wire [`ROB_WID] alu_res_rob_pos,

    input wire lsb_done,
    input wire [`DATA_WID] lsb_res,
    input wire [`ROB_WID] lsb_res_rob_pos,

    input wire commit_store,
    input wire [`ROB_WID] commit_rob_pos,

    input wire [`ROB_WID] rob_head_pos
);

reg committed[`LSB_SIZ - 1:0];
reg busy[`LSB_SIZ - 1:0];
reg [`ROB_WID] rob_pos[`LSB_SIZ - 1:0];
reg ls[`LSB_SIZ - 1:0];
reg [2:0] funct3[`LSB_SIZ - 1:0];
reg rs1_rdy[`LSB_SIZ - 1:0];
reg [`DATA_WID] rs1_val[`LSB_SIZ - 1:0];
reg [`ROB_WID] rs1_rob_pos[`LSB_SIZ - 1:0];
reg rs2_rdy[`LSB_SIZ - 1:0];
reg [`DATA_WID] rs2_val[`LSB_SIZ - 1:0];
reg [`ROB_WID] rs2_rob_pos[`LSB_SIZ - 1:0];
reg [`DATA_WID] imm[`LSB_SIZ - 1:0];

reg status; // 0: IDLE; 1: Load/Store
reg [`LSB_WID] head;
reg [`LSB_WID] tail;
reg [4:0] commit_tail; 
reg is_empty;

wire [`ADDR_WID] head_addr = rs1_val[head] + imm[head];
wire head_io = head_addr[17:16] == 2'b11;

wire store_en = ls[head] == 1;
wire load_en = ls[head] == 0 && !head_io;
wire input_en = head_io && rob_pos[head] == rob_head_pos;

wire pop = status && mem_done;
wire [`LSB_WID] nxt_head = head + pop;
wire [`LSB_WID] nxt_tail = tail + issue;
wire nxt_empty = nxt_head == nxt_tail && (empty || pop && !issue)

always @(*) begin
    lsb_full = nxt_head == nxt_tail && !nxt_empty;
end

// Store/Output: 先 commit 再 store
// Load：先 Load 再 commit
// Input: stall 到队头再处理好了

integer i;
always @(posedge clk) begin
    if (rst || (rollback && commit_tail == `LSB_NPOS)) begin
        status <= 0;
        mem_en <= 0;
        head <= 0;
        tail <= 0;
        is_empty <= 1;
        commit_tail <= `LSB_NPOS;
        for (i = 0; i < `LSB_SIZ; i = i + 1) begin
            committed[i] <= 0;
            busy[i] <= 0;
            rob_pos[i] <= 0;
            ls[i] <= 0;
            funct3[i] <= 0;
            rs1_rdy[i] <= 0;
            rs1_val[i] <= 0;
            rs1_rob_pos[i] <= 0;
            rs2_rdy[i] <= 0;
            rs2_val[i] <= 0;
            rs2_rob_pos[i] <= 0;
            imm[i] <= 0;
        end
    end else if (rollback) begin
        // 分支前的指令一定都被 commit 过
        // 只要清空还没被 commit 的指令
        tail <= commit_tail + 1;
        for (i = 0; i < `LSB_SIZ; i = i + 1) begin
            if (!committed[i]) begin
                busy[i] <= 0;
            end
        end
        // 当前正在执行的指令继续执行
        // 如果刚好结束一条 LS
        if (status == 1 && mem_done) begin
            // Store: 一定在分支之前，好像啥也不用干
            // Load: 已经被 commit 过了，好像也啥都不用干
            status <= 0;
            mem_en <= 0;
            head <= head + 1;
            busy[head] <= 0;
            committed[head] <= 0;
            if (commit_tail[`LSB_WID] == head) begin
                commit_tail <= `LSB_NPOS;
                empty <= 1;
            end
        end
    end else if (rdy) begin
        if (lsb_en) begin
            busy[tail] <= 1;
            rob_pos[tail] <= lsb_rob_pos;
            ls[tail] <= lsb_ls;
            funct3[tail] <= lsb_funct3;
            rs1_rdy[tail] <= lsb_rs1_rdy;
            rs1_val[tail] <= lsb_rs1_val;
            rs1_rob_pos[tail] <= lsb_rs1_rob_pos;
            rs2_rdy[tail] <= lsb_rs2_rdy;
            rs2_val[tail] <= lsb_rs2_val;
            rs2_rob_pos[tail] <= lsb_rs2_rob_pos;
            imm[tail] <= lsb_imm;
        end

        case (status) 
            0: begin // IDLE
                if (!empty && rs1_rdy[head] && rs2_rdy[head] && (store_en || load_en || input_en)) begin
                    mem_en <= 1;
                    mem_a <= rs1_val[head] + imm[head];
                    status <= 1;
                    if (ls[head]) begin // Store
                        mem_w <= rs2_val[head];
                        mem_wr <= 1;
                        case (funct3[head])
                            `FUNCT3_SB: mem_l <= 3'd1;
                            `FUNCT3_SH: mem_l <= 3'd2;
                            `FUNCT3_SW: mem_l <= 3'd4;
                        endcase
                    end else begin // Load
                        mem_wr <= 0;
                        case (funct3[head])
                            `FUNCT3_LB: mem_l <= 3'd1;
                            `FUNCT3_LH: mem_l <= 3'd2;
                            `FUNCT3_LW: mem_l <= 3'd4;
                            `FUNCT3_LBU: mem_l <= 3'd1;
                            `FUNCT3_LHU: mem_l <= 3'd2;
                        endcase
                    end
                end else mem_en <= 0;
            end
            1: begin // Load/Store
                done <= 0;
                if (mem_done) begin
                    mem_en <= 0;
                    status <= 0;
                    busy[head] <= 0;
                    if (!ls[head]) begin // Load 
                        done <= 1;
                        res_rob_pos <= rob_pos[head];
                        case (funct3[head])
                            `FUNCT3_LB:
                                res <= {{24{mem_r[7]}}, mem_r[7:0]};
                            `FUNCT3_LH:
                                res <= {{16{mem_r[15]}}, mem_r[15:0]};
                            `FUNCT3_LW: res <= mem_r;
                            `FUNCT3_LBU: res <= {24'b0, mem_r[7:0]};
                            `FUNCT3_LHU: res <= {16'b0, mem_r[15:0]};
                        endcase
                    end
                end
                if (commit_tail[`LSB_WID] == head) begin
                    commit_tail <= `LSB_NPOS;
                end
            end
        endcase
    end

    if (alu_done) begin
        for (i = 0; i < `LSB_SIZ; i = i + 1) begin
            if (rs1_rdy[i] && rs1_rob_pos[i] == alu_res_rob_pos) begin
                rs1_rdy[i] <= 1;
                rs1_rob_pos[i] <= 0;
                rs1_val[i] <= alu_res;
            end
            if (rs2_rdy[i] && rs2_rob_pos[i] == alu_res_rob_pos) begin
                rs2_rdy[i] <= 1;
                rs2_rob_pos[i] <= 0;
                rs2_val[i] <= alu_res;
            end
        end
    end

    if (lsb_done) begin
        for (i = 0; i < `LSB_SIZ; i = i + 1) begin
            if (rs1_rdy[i] && rs1_rob_pos[i] == lsb_res_rob_pos) begin
                rs1_rdy[i] <= 1;
                rs1_rob_pos[i] <= 0;
                rs1_val[i] <= lsb_res;
            end
            if (rs2_rdy[i] && rs2_rob_pos[i] == lsb_res_rob_pos) begin
                rs2_rdy[i] <= 1;
                rs2_rob_pos[i] <= 0;
                rs2_val[i] <= lsb_res;
            end
        end
    end

    if (commit_store) begin
        for (i = 0; i < `LSB_SIZ; i = i + 1) begin
            if (busy[i] && rob_pos[i] == commit_rob_pos) begin
                committed[i] <= 1;
                commit_tail <= {1'b0, i[`LSB_WID]};
            end
        end
    end

    head <= nxt_head;
    tail <= nxt_tail;
    empty <= nxt_empty;
end

endmodule

`endif