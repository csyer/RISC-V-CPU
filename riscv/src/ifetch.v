`ifndef IFETCH
`define IFETCH

`include "def.v"

`define ICACHE_SIZ 16
`define ICACHE_LEN 64
`define 

module IFetch(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback,

    input wire rs_full,
    input wire lsb_full,
    input wire rob_full,


)

// ICache
reg valid[0: `ICACHE_SIZ - 1];

endmodule

`endif