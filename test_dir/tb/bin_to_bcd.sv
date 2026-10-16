`timescale 1ns/1ps

module tb;

    reg  clk;
    reg  rst_n;
    logic seg_top;
    logic seg_top_right;
    logic seg_bot_right;
    logic seg_bot;
    logic seg_bot_left;
    logic seg_top_left;
    logic seg_center;
    logic seg_decimal;
    logic [7:0] an;

    // Instantiate design under test
    top uut (
        .CPU_RESETN(rst_n),
        .CLK100MHZ(clk),
        .SEG_TOP(seg_top),
        .SEG_TOP_RIGHT(seg_top_right),
        .SEG_BOT_RIGHT(seg_bot_right),
        .SEG_BOT(seg_bot),
        .SEG_BOT_LEFT(seg_bot_left),
        .SEG_TOP_LEFT(seg_top_left),
        .SEG_CENTER(seg_center),
        .SEG_DECIMAL(seg_decimal),
        .AN(an)
    );

    // Clock generation
    always #5 clk = ~clk;

    task reset();
        rst_n = 0;
        #20;
        rst_n = 1;
        #20;
    endtask

    // Stimulus
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0);
        clk = 0;
        rst_n = 1;

        $display("Starting simulation");
        reset();

        #1000; // Run simulation for 1000 time units

        $display("Simulation complete");
        $finish;
    end

endmodule
