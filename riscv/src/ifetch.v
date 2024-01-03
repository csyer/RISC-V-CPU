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

    output wire mem_en,
    output wire [`ADDR_WID] mem_pc,
    input wire mem_done,
    input wire [`ICACHE_LINE_WID] mem_data,

    output reg inst_done,
    output reg [`INST_WID] inst,
    output reg [`ADDR_WID] inst_pc
)

reg status; // 0: IDLE, 1: FETCH
reg [`ADDR_WID] pc;

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

integer i, j;
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
        if (hit && !rs_full && !lsb_full && !rob_full) begin
            inst_done <= 1;
            inst <= line[(pc_bs + 1) * 32 - 1:pc_bs * 32];
            inst_pc <= pc;
        end else begin
            inst_done <= 0;
        end
            
        case (status)
            0: begin // IDLE
                if (!hit) begin
                    mem_en <= 1;
                    mem_pc <= pc & 8'hFFFFFFC0;
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

endmodule

`endif