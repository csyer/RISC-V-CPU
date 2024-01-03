`ifndef REGFILE
`define REGFILE

`include "def.v"

module RegFile(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    input wire [`WIDREG] rs1,
    output reg [`WID32] val1,
    output reg [`WIDROB] rob_pos1,
    input wire [`WIDREG] rs2,
    output reg [`WID32] val2,
    output reg [`WIDROB] rob_pos2
);

reg [`DATA_WID] r[0: `REG_SIZ - 1];
reg is_rdy [0: `REG_SIZ - 1];
reg [`ROB_WID] pos[0: `REG_SIZ - 1];

integer i;
always @(posedge clk) begin
    if (rst) begin 
        for (i = 0; i < `REG_SIZ; i = i + 1) begin 
            val[i] <= 32'b0;
            is_rdy[i] <= 1'b0;
            pos[i] <= 4'b0;
        end
    end else if(rdy) begin
        // TODO
    end
    if (rollback) begin
        for (i = 0; i < `REG_SIZ; i = i + 1) begin
            is_rdy[i] <= 1'b0;
            pos[i] <= 4'b0;
        end
    end
end

endmodule

`endif