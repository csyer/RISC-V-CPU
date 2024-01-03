`define ROB_SIZ 32
`define REG_SIZ 32

`define DATA_WID 31:0
`define INST_WID 31:0
`define ADDR_WID 31:0
`define ROB_WID `ROB_LEN - 1:0
`define REG_WID `REG_SIZ - 1:0

`define CACHE_LINE_NUM 16
`define CACHE_LINE_LEN 64
`define CACHE_LINE_WID `CACHE_LINE_LEN * 8 - 1:0

`define OPCODE_L      7'b0000011
`define OPCODE_S      7'b0100011
`define OPCODE_CAL    7'b0110011
`define OPCODE_CALI   7'b0010011
`define OPCODE_B      7'b1100011
`define OPCODE_LUI    7'b0110111
`define OPCODE_AUIPC  7'b0010111
`define OPCODE_JAL    7'b1101111
`define OPCODE_JALR   7'b1100111
