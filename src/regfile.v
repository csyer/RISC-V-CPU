`ifndef REGFILE
`define REGFILE

`include "def.v"

module RegFile(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    // from Decoder / query
    input wire [`REG_WID] rs1,
    output reg rs1_rdy,
    output reg [`DATA_WID] rs1_val,
    output reg [`ROB_WID] rs1_rob_pos,
    
    input wire [`REG_WID] rs2,
    output reg rs2_rdy,
    output reg [`DATA_WID] rs2_val,
    output reg [`ROB_WID] rs2_rob_pos,

    // Decoder issue / add rely
    input wire issue,
    input wire [`REG_WID] issue_rd,
    input wire [`ROB_WID] issue_rob_pos,

    // RoB commit / remove rely
    input wire commit,
    input wire [`REG_WID] commit_rd,
    input wire [`DATA_WID] commit_val,
    input wire [`ROB_WID] commit_rob_pos
);

reg is_rdy [`REG_SIZ - 1:0];
reg [`DATA_WID] val[`REG_SIZ - 1:0];
reg [`ROB_WID] rob_pos[`REG_SIZ - 1:0];

wire valid_commit = commit && commit_rd != 0;
wire upd = !is_rdy[commit_rd] && rob_pos[commit_rd] == commit_rob_pos;

integer i;
always @(posedge clk) begin
    // for (i = 0; i < 32; i++)
        // $display("REG %D : %D %H %D", 1, is_rdy[1], val[1], rob_pos[1]);
    if (rst) begin 
        for (i = 0; i < `REG_SIZ; i = i + 1) begin 
            val[i] <= 32'b0;
            is_rdy[i] <= 1'b1;
            rob_pos[i] <= 4'b0;
        end
    end else if(rdy) begin
        // x0 恒为 0
        if (commit && commit_rd != 0) begin
            val[commit_rd] <= commit_val;
            if (upd) begin
                is_rdy[commit_rd] <= 1'b1;
                rob_pos[commit_rd] <= 4'b0; 
            end
        end 
        if (issue && issue_rd != 0) begin
            is_rdy[issue_rd] <= 1'b0;
            rob_pos[issue_rd] <= issue_rob_pos;
        end
        
        if (rollback) begin
            for (i = 0; i < `REG_SIZ; i = i + 1) begin
                is_rdy[i] <= 1'b1;
                rob_pos[i] <= 4'b0;
            end
        end
    end
end

always @(*) begin
    // a little forwarding ? 
    if (valid_commit && rs1 == commit_rd && upd) begin
        rs1_rdy = 1'b1;
        rs1_val = commit_val;
        rs1_rob_pos = 4'b0;
    end else begin
        // $display("dbg %D %D", rs1, val[rs1]);
        rs1_rdy = is_rdy[rs1];
        rs1_val = val[rs1];
        rs1_rob_pos = rob_pos[rs1];
    end

    if (valid_commit && rs2 == commit_rd && upd) begin
        rs2_rdy = 1'b1;
        rs2_val = commit_val;
        rs2_rob_pos = 4'b0;
    end else begin
        rs2_rdy = is_rdy[rs2];
        rs2_val = val[rs2];
        rs2_rob_pos = rob_pos[rs2];
    end
end

endmodule

`endif