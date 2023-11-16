module ALU(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire [6: 0] opcode,
    input wire [31: 0] A,
    input wire [31: 0] B,

    output wire [31: 0] result
);

endmodule