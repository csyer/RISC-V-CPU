`ifndef LSB
`define LSB

module LSB(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    output reg lsb_full,

    input wire lsb_en,
    input wire [`ROB_WID] lsb_rob_pos,
    input wire [6:0] lsb_opcode,
    input wire [2:0] lsb_funct3,
    input wire lsb_funct7,
    input wire lsb_rs1_rdy,
    input wire [`DATA_WID] lsb_rs1_val,
    input wire [`ROB_WID] lsb_rs1_rob_pos,
    input wire lsb_rs2_rdy,
    input wire [`DATA_WID] lsb_rs2_val,
    input wire [`ROB_WID] lsb_rs2_rob_pos,
    input wire [`DATA_WID] lsb_imm,
);

always @(posedge clk) begin
    if (rst) begin
        // TODO
    end else if (rdy) begin
        // TODO
    end
end

endmodule

`endif