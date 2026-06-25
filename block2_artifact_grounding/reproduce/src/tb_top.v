`timescale 1ns / 1ps

module tb_top;
    reg clk = 1'b0;
    reg reset_n = 1'b0;
    wire [3:0] led;

    top dut (
        .clk(clk),
        .reset_n(reset_n),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        #35 reset_n = 1'b1;
        #12000 $finish;
    end
endmodule
