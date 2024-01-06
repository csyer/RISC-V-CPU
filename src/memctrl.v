`ifndef MEM_CTRL
`define MEM_CTRL

`include "def.v"

module MemCtrl(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rollback, 

    input wire [7:0] mem_din,
    output reg [7:0] mem_dout,
    output reg [31:0] mem_a,
    output reg mem_wr,

    input wire if_en,
    input wire [`ADDR_WID] if_pc,
    output reg if_done,
    output wire [`ICACHE_LINE_WID] if_data,

    input wire lsb_en,
    input wire lsb_wr,
    input wire [`ADDR_WID] lsb_a,
    input wire [2:0] lsb_l,
    input wire [`DATA_WID] lsb_w,
    output reg [`DATA_WID] lsb_r,
    output reg lsb_done,

    input wire io_buffer_full
);

reg [1:0] status; //0: IDLE, 1: IF, 2: LOAD, 3: STORE
reg [6:0] stage; // 2^6 = 64
reg [6:0] len;

reg [7:0] if_data_reg[`ICACHE_LINE_LEN - 1:0];

reg [`ADDR_WID] store_a;

genvar i;
generate
    for (i = 0; i < `ICACHE_LINE_LEN; i = i + 1) begin
        assign if_data[i * 8 + 7:i * 8] = if_data_reg[i];
    end
endgenerate

always @(posedge clk) begin
    if (rst) begin
        status <= 0;
        if_done <= 0;
        lsb_done <= 0;
        mem_a <= 0;
        mem_wr <= 0;
    end else if (rdy) begin
        mem_wr <= 0;
        case(status)
            0: begin // IDLE
                if (if_done || lsb_done) begin
                    if_done <= 0;
                    lsb_done <= 0;
                end else if (!rollback) begin
                    if (lsb_en) begin
                        if (lsb_wr) begin // write / Store
                            status <= 3; 
                            store_a <= lsb_a;
                        end else begin // read / Load
                            status <= 2;
                            mem_a <= lsb_a;
                            lsb_r <= 0;
                        end
                        stage <= 0;
                        len <= {4'b0, lsb_l};
                    end else if (if_en) begin
                        status <= 1;
                        mem_a <= if_pc;
                        stage <= 0;
                        len <= `ICACHE_LINE_LEN;
                    end
                end
            end
            1: begin // IF
                // $display("mem: %D %H", stage - 1, if_data);
                if_data_reg[stage - 1] <= mem_din;
                // mem 会迟一个周期把值送过来
                if (stage + 1 == len) mem_a <= 0;
                else mem_a <= mem_a + 1;
                if (stage == len) begin
                    // $display("finish data");
                    if_done <= 1;
                    mem_wr <= 0;
                    mem_a <= 0;
                    stage <= 0;
                    status <= 0;
                end else stage <= stage + 1;
            end
            2: begin // LOAD
                if (rollback) begin
                    status <= 0;
                    lsb_done <= 0;
                    mem_wr <= 0;
                    mem_a <= 0;
                    stage <= 0;
                end else begin
                    // stage 从 1 开始，迟一个周期
                    case (stage)
                        1: lsb_r[7:0] <= mem_din;
                        2: lsb_r[15:8] <= mem_din;
                        3: lsb_r[23:16] <= mem_din;
                        4: lsb_r[31:24] <= mem_din;
                    endcase
                    if (stage + 1 == len) mem_a <= 0;
                    else mem_a = mem_a + 1;
                    if (stage == len) begin
                        status <= 0;
                        lsb_done <= 1;
                        mem_wr <= 0;
                        mem_a <= 0;
                        stage <= 0;
                    end else stage <= stage + 1;
                end
            end
            3: begin // STORE
                if (store_a[17:16] != 2'b11 || !io_buffer_full) begin
                    // $display("Store %H", store_a);
                    mem_wr <= 1;
                    case (stage)
                        0: mem_dout <= lsb_w[7:0];
                        1: mem_dout <= lsb_w[15:8];
                        2: mem_dout <= lsb_w[23:16];
                        3: mem_dout <= lsb_w[31:24];
                    endcase
                    if (stage == 0) mem_a <= store_a;
                    else mem_a = mem_a + 1;
                    if (stage == len) begin
                        status <= 0;
                        lsb_done <= 1;
                        mem_a <= 0;
                        stage <= 0;
                        mem_wr <= 0;
                    end else stage = stage + 1;
                end
            end
        endcase
    end else begin
        if_done <= 0;
        lsb_done <= 0;
        mem_a <= 0;
        mem_wr <= 0;
    end
end

endmodule

`endif