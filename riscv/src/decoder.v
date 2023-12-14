module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    input wire [31: 0] inst,

    output wire [6: 0] opcode,
    output wire [2: 0] funct3,
    output wire        funct7,
    output wire [31: 0] rs1,
    output wire [31: 0] rs2,
    output wire [31: 0] imm,
    output wire [31: 0] rd
)



endmodule