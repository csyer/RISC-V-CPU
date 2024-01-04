`ifndef IFETCH
`define IFETCH

`include "def.v"

`define ICACHE_TAG_WID 21:0
`define ICACHE_TAG 31:10
`define ICACHE_IDX_WID 3:0
`define ICACHE_IDX 9:6
`define ICACHE_BS_WID 3:0
`define ICACHE_BS 5:2
/*
每条指令长度为 4 Byte
为了使指令完整出现在 ICACHE Line 中
在指令不重合的情况下
最高的 30 位唯一确定一条指令

ICACHE 有 16 行，每行 16 条 4 Byte 指令
*/

module IFetch(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    input wire rs_full,
    input wire lsb_full,
    input wire rob_full,

    output reg mem_en,
    output reg [`ADDR_WID] mem_pc,
    input wire mem_done,
    input wire [`ICACHE_LINE_WID] mem_data,

    // now
    output reg inst_done,
    output reg [`INST_WID] inst,
    output reg [`ADDR_WID] inst_pc,
    output reg inst_pre_j,

    // when RoB commit
    input wire br_pre,
    input wire br_pre_j, // is jump
    input wire [`ADDR_WID] br_pre_pc,
    input wire [`ADDR_WID] br_res_pc
);

reg status; // 0: IDLE, 1: FETCH
reg [`ADDR_WID] pc;

reg [`ADDR_WID] pre_pc; // 预测当前指令是否跳转
reg pre_j;

// 1KB ICACHE
reg valid[`ICACHE_LINE_NUM - 1:0];
reg [`ICACHE_TAG_WID] tag[`ICACHE_LINE_NUM - 1:0];
reg [`ICACHE_LINE_WID] data[`ICACHE_LINE_NUM - 1:0];

wire [`ICACHE_TAG_WID] pc_tag = pc[`ICACHE_TAG];
wire [`ICACHE_IDX_WID] pc_idx = pc[`ICACHE_IDX];
wire [`ICACHE_BS_WID] pc_bs = pc[`ICACHE_BS];
wire hit = valid[pc_idx] && (pc_tag == tag[pc_idx]);

wire [`ICACHE_TAG_WID] mem_pc_tag = mem_pc[`ICACHE_TAG];
wire [`ICACHE_IDX_WID] mem_pc_idx = mem_pc[`ICACHE_IDX];

wire [`ICACHE_LINE_WID] line = data[pc_idx];
wire [`INST_WID] insts[`ICACHE_INST_NUM - 1:0];
wire [`INST_WID] _inst = insts[pc_bs];

genvar k;
generate
    for (k = 0; k < `ICACHE_INST_NUM; k = k + 1) begin
        assign insts[k] = line[k * 32 + 31:k * 32];
    end
endgenerate

integer i;
always @(posedge clk) begin
    if (rst) begin
        pc <= 32'b0;
        mem_en <= 0;
        mem_pc <= 32'b0;
        for (i = 0; i < `ICACHE_LINE_NUM; i = i + 1) begin
            valid[i] <= 0;
        end
        inst_done <= 0;
        status <= 0;
    end else if (rdy) begin
        if (rollback) begin
            inst_done <= 0;
            pc <= br_res_pc;
        end else begin
            if (hit && !rs_full && !lsb_full && !rob_full) begin
                inst_done <= 1;
                inst <= _inst;
                inst_pc <= pc;
                pc <= pre_pc;
                inst_pre_j <= pre_j;
            end else begin
                inst_done <= 0;
            end
        end
            
        case (status)
            0: begin // IDLE
                if (!hit) begin
                    mem_en <= 1;
                    mem_pc <= pc & 32'hFFFFFFC0;
                    status <= 1;
                end
            end
            1: begin // FETCH
                if (mem_done) begin
                    valid[mem_pc_idx] <= 1;
                    tag[mem_pc_idx] <= mem_pc_tag;
                    data[mem_pc_idx] <= mem_data;
                    mem_en <= 0;
                    status <= 0;
                end
            end
        endcase
    end
end

// Predictor
`define PRE_SIZ 64  // 2^6
reg [1:0] pre_cnt[`PRE_SIZ - 1:0];
wire [5:0] pre_idx = br_pre_pc[6:2];

integer j;
always @(posedge clk) begin
    if (rst) begin
        for (j = 0; j < `PRE_SIZ; j = j + 1) begin
            pre_cnt[j] <= 0;
        end
    end else if (rdy) begin
        if (br_pre) begin 
            if (br_pre_j) begin
                if (pre_cnt[pre_idx] < 2'b11) begin
                    pre_cnt[pre_idx] <= pre_cnt[pre_idx] + 1;
                end
            end else begin
                if (pre_cnt[pre_idx] > 2'b00) begin
                    pre_cnt[pre_idx] <= pre_cnt[pre_idx] - 1;
                end
            end
        end
    end
end

wire [5:0] pre_pc_idx = pc[6:2];
always @(*) begin
    pre_pc = pc + 4;
    pre_j = 0;
    // 偷个懒。。遇到 JALR 就直接认为不跳好了
    // 反正在 JALR ready 之前要 stall，感觉差不多。。
    case (_inst[6:0]) 
        `OPCODE_JAL: begin
            pre_pc = pc + {{12{_inst[31]}}, _inst[19:12], _inst[20], _inst[30:21], 1'b0};
            pre_j = 1;
        end
        `OPCODE_B: begin
            if (pre_cnt[pre_pc_idx] >= 2'b10) begin 
                pre_pc = {{20{_inst[31]}}, _inst[7], _inst[30:25], _inst[11:8], 1'b0};
                pre_j = 1;
            end
        end
    endcase
end

endmodule

`endif