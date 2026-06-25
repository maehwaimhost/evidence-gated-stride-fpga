`timescale 1ns / 1ps

module tb_top_b;
    reg        clk_a = 1'b0;
    reg        clk_b = 1'b0;
    reg        reset_n = 1'b0;
    reg  [7:0] din = 8'd0;
    reg        din_valid = 1'b0;
    wire [7:0] dout;
    wire       dout_valid;
    wire [3:0] status;

    top_b dut (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .reset_n(reset_n),
        .din(din),
        .din_valid(din_valid),
        .dout(dout),
        .dout_valid(dout_valid),
        .status(status)
    );

    always #5.0 clk_a = ~clk_a;
    always #3.5 clk_b = ~clk_b;

    reg [7:0] stim_lfsr = 8'h6b;

    always @(posedge clk_a) begin
        if (reset_n) begin
            stim_lfsr <= {stim_lfsr[6:0], stim_lfsr[7] ^ stim_lfsr[5] ^ stim_lfsr[4] ^ stim_lfsr[3]};
            din <= stim_lfsr;
            din_valid <= stim_lfsr[0];
        end else begin
            din_valid <= 1'b0;
        end
    end

    initial begin
        #42 reset_n = 1'b1;
        #15000 $finish;
    end
endmodule
