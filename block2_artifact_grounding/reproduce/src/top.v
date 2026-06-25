`timescale 1ns / 1ps

module top (
    input  wire       clk,
    input  wire       reset_n,
    output wire [3:0] led
);
    wire       tick;
    wire [7:0] sample;
    wire [7:0] accumulator;
    wire [7:0] digest;
    wire [1:0] state;
    wire       alarm;

    ap_timer u_timer (
        .clk(clk),
        .reset_n(reset_n),
        .tick(tick)
    );

    ap_sample_source u_sample_source (
        .clk(clk),
        .reset_n(reset_n),
        .tick(tick),
        .sample(sample)
    );

    ap_control_fsm u_control_fsm (
        .clk(clk),
        .reset_n(reset_n),
        .tick(tick),
        .sample(sample),
        .accumulator(accumulator),
        .state(state),
        .alarm(alarm)
    );

    ap_integrity_lfsr u_integrity_lfsr (
        .clk(clk),
        .reset_n(reset_n),
        .enable(tick),
        .data_in(sample ^ accumulator),
        .digest(digest)
    );

    assign led = {alarm, state, digest[0]};
endmodule

module ap_timer (
    input  wire clk,
    input  wire reset_n,
    output wire tick
);
    reg [15:0] count;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            count <= 16'd0;
        end else begin
            count <= count + 16'd1;
        end
    end

    assign tick = (count[7:0] == 8'hff);
endmodule

module ap_sample_source (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       tick,
    output wire [7:0] sample
);
    reg [7:0] lfsr;
    wire feedback;

    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lfsr <= 8'h5a;
        end else if (tick) begin
            lfsr <= {lfsr[6:0], feedback};
        end
    end

    assign sample = lfsr ^ 8'h3c;
endmodule

module ap_control_fsm (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       tick,
    input  wire [7:0] sample,
    output reg  [7:0] accumulator,
    output reg  [1:0] state,
    output reg        alarm
);
    localparam ST_IDLE    = 2'd0;
    localparam ST_COLLECT = 2'd1;
    localparam ST_CHECK   = 2'd2;
    localparam ST_ALARM   = 2'd3;

    reg [7:0] history [0:15];
    reg [3:0] write_ptr;
    reg [7:0] rolling_xor;
    integer i;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= ST_IDLE;
            alarm <= 1'b0;
            accumulator <= 8'd0;
            rolling_xor <= 8'd0;
            write_ptr <= 4'd0;
            for (i = 0; i < 16; i = i + 1) begin
                history[i] <= 8'd0;
            end
        end else if (tick) begin
            history[write_ptr] <= sample;
            write_ptr <= write_ptr + 4'd1;
            accumulator <= accumulator + sample;
            rolling_xor <= rolling_xor ^ sample;

            case (state)
                ST_IDLE: begin
                    alarm <= 1'b0;
                    state <= ST_COLLECT;
                end
                ST_COLLECT: begin
                    if (write_ptr == 4'hf) begin
                        state <= ST_CHECK;
                    end
                end
                ST_CHECK: begin
                    if ((rolling_xor[7:4] == 4'ha) || accumulator[7]) begin
                        alarm <= 1'b1;
                        state <= ST_ALARM;
                    end else begin
                        alarm <= 1'b0;
                        state <= ST_COLLECT;
                    end
                end
                ST_ALARM: begin
                    if (sample[2:0] == 3'b000) begin
                        alarm <= 1'b0;
                        state <= ST_COLLECT;
                    end
                end
                default: begin
                    state <= ST_IDLE;
                    alarm <= 1'b0;
                end
            endcase
        end
    end
endmodule

module ap_integrity_lfsr (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       enable,
    input  wire [7:0] data_in,
    output reg  [7:0] digest
);
    wire feedback;

    assign feedback = digest[7] ^ digest[2] ^ data_in[3] ^ data_in[0];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            digest <= 8'ha5;
        end else if (enable) begin
            digest <= {digest[6:0], feedback} ^ data_in;
        end
    end
endmodule
