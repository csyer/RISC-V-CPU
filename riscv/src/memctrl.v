module MemCtrl(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback, 

    input wire [7: 0] mem_in,
    output reg [7: 0] mem_out,
    output reg [31: 0] mem_addr,
    output reg mem_wr
);

always @(posedge clk) begin
    if (rst) begin
    end else if (!rdy) begin
    end else begin
    end
end

endmodule