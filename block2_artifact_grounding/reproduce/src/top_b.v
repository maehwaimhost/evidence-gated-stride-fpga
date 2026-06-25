`timescale 1ns / 1ps

module top_b (
    input  wire       clk_a,
    input  wire       clk_b,
    input  wire       reset_n,
    input  wire [7:0] din,
    input  wire       din_valid,
    output wire [7:0] dout,
    output wire       dout_valid,
    output wire [3:0] status
);
    wire [7:0] cfg_threshold;
    wire [7:0] fifo_rdata;
    wire       fifo_empty;
    wire       fifo_full;
    wire       fifo_rd;

    bp_regfile u_regfile (
        .clk(clk_a),
        .reset_n(reset_n),
        .wr_en(din_valid),
        .wr_data(din),
        .threshold(cfg_threshold)
    );

    bp_async_fifo u_fifo (
        .wclk(clk_a),
        .wrst_n(reset_n),
        .wr_en(din_valid & ~fifo_full),
        .wdata(din ^ cfg_threshold),
        .rclk(clk_b),
        .rrst_n(reset_n),
        .rd_en(fifo_rd),
        .rdata(fifo_rdata),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    bp_monitor_fsm u_monitor (
        .clk(clk_b),
        .reset_n(reset_n),
        .empty(fifo_empty),
        .rdata(fifo_rdata),
        .rd_en(fifo_rd),
        .dout(dout),
        .dout_valid(dout_valid),
        .status(status)
    );
endmodule

module bp_regfile (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       wr_en,
    input  wire [7:0] wr_data,
    output reg  [7:0] threshold
);
    reg [7:0] regs [0:7];
    reg [2:0] wptr;
    integer i;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wptr <= 3'd0;
            threshold <= 8'h40;
            for (i = 0; i < 8; i = i + 1) begin
                regs[i] <= 8'd0;
            end
        end else if (wr_en) begin
            regs[wptr] <= wr_data;
            wptr <= wptr + 3'd1;
            threshold <= regs[0] ^ regs[7] ^ wr_data;
        end
    end
endmodule

module bp_async_fifo (
    input  wire       wclk,
    input  wire       wrst_n,
    input  wire       wr_en,
    input  wire [7:0] wdata,
    input  wire       rclk,
    input  wire       rrst_n,
    input  wire       rd_en,
    output reg  [7:0] rdata,
    output wire       full,
    output wire       empty
);
    reg [7:0] mem [0:15];
    reg [4:0] wptr_bin;
    reg [4:0] rptr_bin;
    reg [4:0] wptr_gray;
    reg [4:0] rptr_gray;
    reg [4:0] wq1_rptr_gray;
    reg [4:0] wq2_rptr_gray;
    reg [4:0] rq1_wptr_gray;
    reg [4:0] rq2_wptr_gray;
    reg       full_r;
    reg       empty_r;

    wire [4:0] wptr_bin_next;
    wire [4:0] wptr_gray_next;
    wire [4:0] rptr_bin_next;
    wire [4:0] rptr_gray_next;

    assign wptr_bin_next  = wptr_bin + {4'd0, (wr_en & ~full_r)};
    assign wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;
    assign rptr_bin_next  = rptr_bin + {4'd0, (rd_en & ~empty_r)};
    assign rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 5'd0;
            wptr_gray <= 5'd0;
            wq1_rptr_gray <= 5'd0;
            wq2_rptr_gray <= 5'd0;
            full_r <= 1'b0;
        end else begin
            if (wr_en & ~full_r) begin
                mem[wptr_bin[3:0]] <= wdata;
            end
            wptr_bin <= wptr_bin_next;
            wptr_gray <= wptr_gray_next;
            wq1_rptr_gray <= rptr_gray;
            wq2_rptr_gray <= wq1_rptr_gray;
            full_r <= (wptr_gray_next == {~wq2_rptr_gray[4:3], wq2_rptr_gray[2:0]});
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 5'd0;
            rptr_gray <= 5'd0;
            rq1_wptr_gray <= 5'd0;
            rq2_wptr_gray <= 5'd0;
            rdata <= 8'd0;
            empty_r <= 1'b1;
        end else begin
            if (rd_en & ~empty_r) begin
                rdata <= mem[rptr_bin[3:0]];
            end
            rptr_bin <= rptr_bin_next;
            rptr_gray <= rptr_gray_next;
            rq1_wptr_gray <= wptr_gray;
            rq2_wptr_gray <= rq1_wptr_gray;
            empty_r <= (rptr_gray_next == rq2_wptr_gray);
        end
    end

    assign full  = full_r;
    assign empty = empty_r;
endmodule

module bp_monitor_fsm (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       empty,
    input  wire [7:0] rdata,
    output reg        rd_en,
    output reg  [7:0] dout,
    output reg        dout_valid,
    output reg  [3:0] status
);
    localparam MS_WAIT = 2'd0;
    localparam MS_READ = 2'd1;
    localparam MS_EVAL = 2'd2;
    localparam MS_EMIT = 2'd3;

    reg [1:0] mstate;
    reg [7:0] peak;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mstate <= MS_WAIT;
            rd_en <= 1'b0;
            dout <= 8'd0;
            dout_valid <= 1'b0;
            status <= 4'd0;
            peak <= 8'd0;
        end else begin
            rd_en <= 1'b0;
            dout_valid <= 1'b0;
            case (mstate)
                MS_WAIT: begin
                    if (!empty) begin
                        rd_en <= 1'b1;
                        mstate <= MS_READ;
                    end
                end
                MS_READ: begin
                    mstate <= MS_EVAL;
                end
                MS_EVAL: begin
                    if (rdata > peak) begin
                        peak <= rdata;
                    end
                    mstate <= MS_EMIT;
                end
                MS_EMIT: begin
                    dout <= rdata ^ peak;
                    dout_valid <= 1'b1;
                    status <= {1'b1, peak[7:5]};
                    mstate <= MS_WAIT;
                end
                default: begin
                    mstate <= MS_WAIT;
                end
            endcase
        end
    end
endmodule
