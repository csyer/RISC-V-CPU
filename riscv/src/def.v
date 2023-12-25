`define ROB_LEN 32
`define REG_SIZ 32

`define WID32 31: 0
`define WIDROB `ROBLEN - 1: 0

`define OPCODE_L      7'b0000011
`define OPCODE_S      7'b0100011
`define OPCODE_CAL    7'b0110011
`define OPCODE_CALI   7'b0010011
`define OPCODE_B      7'b1100011
`define OPCODE_LUI    7'b0110111
`define OPCODE_AUIPC  7'b0010111
`define OPCODE_JAL    7'b1101111
`define OPCODE_JALR   7'b1100111