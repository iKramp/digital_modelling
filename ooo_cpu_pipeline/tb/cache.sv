`include "../modules/memory/cache.sv"

`timescale 1ns/1ps

module cache_mod_tb;

    parameter BIT = 32;
    parameter BUS_BIT = 128;
    parameter ADDR_BIT = BIT;
    parameter CACHE_LINES = 4;

    localparam CLK_PERIOD = 10;

    logic clk;
    logic rst_n;

    logic [ADDR_BIT-1:0] addr;
    logic read;
    logic write;
    logic [1:0] data_width;

    tri [BIT-1:0] cpu_data;
    logic [BIT-1:0] cpu_write_data;
    logic cpu_drive_en;
    logic cpu_data_valid;

    logic mem_ready;
    wire logic [BUS_BIT-1:0] mem_data;
    logic mem_read;
    logic mem_write;
    logic [ADDR_BIT-1:0] mem_addr;

    integer memory_delay;
    integer test_count = 0;

    logic [BUS_BIT-1:0] memory_array [0:4095];

    logic [ADDR_BIT-1:0] saved_mem_addr;
    logic saved_mem_read;
    logic saved_mem_write;

    assign cpu_data = cpu_drive_en ? cpu_write_data : 'z;

    // DUT
    cache_mod #(
        .BIT(BIT),
        .BUS_BIT(BUS_BIT),
        .ADDR_BIT(ADDR_BIT),
        .CACHE_LINES(CACHE_LINES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .addr(addr),
        .read(read),
        .write(write),
        .data_width(data_width),

        .cpu_data(cpu_data),
        .cpu_data_valid(cpu_data_valid),

        .mem_ready(mem_ready),
        .mem_data(mem_data),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_addr(mem_addr)
    );

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------
    // Memory model
    // ------------------------------------------------

    // The memory model does not check which commands
    // the cache issues. It simply responds to them.
    //
    // Every command receives a response after
    // memory_delay clock cycles.

    logic [BUS_BIT-1:0] mem_data_reg;
    assign mem_data = saved_mem_read ? mem_data_reg : 'z;

    initial begin : memory_model

        integer i;
        integer index;

        mem_ready = 0;

        $dumpfile("cache_mod_tb.vcd");
        $dumpvars(0, cache_mod_tb);

        for (i = 0; i < 4096; i = i + 1)
            memory_array[i] = {
                4{32'h12340000 + i}
            };

        forever begin

            @(posedge clk);

            if (rst_n && (mem_read || mem_write)) begin

                saved_mem_addr = mem_addr;
                saved_mem_read = mem_read;
                saved_mem_write = mem_write;

                // Wait for configured memory latency.
                repeat (memory_delay)
                    @(posedge clk);

                index = (saved_mem_addr >> 4) % 4096;

                // Provide memory data for reads.
                mem_data_reg = memory_array[index];

                // Complete memory transaction.
                mem_ready = 1'b1;

                @(posedge clk);

                mem_ready = 1'b0;

                // Wait until the command is deasserted
                // before accepting another transaction.
                wait (!(mem_read || mem_write));

            end

        end
    end

    // ------------------------------------------------
    // Timing requirement monitor
    // ------------------------------------------------

    // After mem_ready, the cache must produce either
    // a new memory command or cpu_data_valid within
    // three clock cycles.

    always @(posedge clk) begin : memory_response_monitor

        integer cycles;

        if (rst_n && mem_ready) begin

            cycles = 0;

            while (cycles < 3) begin

                @(posedge clk);
                cycles = cycles + 1;

                if (cpu_data_valid || mem_read || mem_write)
                    break;

            end

            if (!(cpu_data_valid || mem_read || mem_write)) begin

                $error(
                    "TIMEOUT: No CPU response or memory command within 3 cycles after mem_ready. Time=%0t",
                    $time
                );

                $fatal;

            end

        end

    end

    // ------------------------------------------------
    // CPU transaction tasks
    // ------------------------------------------------

    task automatic cpu_request(
        input logic [ADDR_BIT-1:0] request_addr,
        input logic request_read,
        input logic request_write,
        input logic [1:0] request_width,
        input logic [BIT-1:0] write_data
    );

        integer cycles;
        logic completed;

        begin

            test_count = test_count + 1;

            @(negedge clk);

            addr = request_addr;
            read = request_read;
            write = request_write;
            data_width = request_width;

            cpu_write_data = write_data;
            cpu_drive_en = request_write;

            completed = 0;

            // Check CPU request latency.
            // A valid response or memory command must
            // appear within three clock cycles.

            for (cycles = 1; cycles <= 3; cycles = cycles + 1) begin

                @(posedge clk);

                if (cpu_data_valid || mem_read || mem_write) begin
                    completed = 1;
                    break;
                end

            end

            if (!completed) begin
                $dumpflush;

                $error(
                    "CPU REQUEST TIMEOUT: addr=%h read=%b write=%b",
                    request_addr,
                    request_read,
                    request_write
                );


                $fatal;

            end

            // Release CPU request.
            @(negedge clk);

            // Wait for the transaction to complete.
            // This allows arbitrarily delayed memory responses.

            cycles = 0;

            while (!cpu_data_valid && cycles < 30) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            @(negedge clk);

            read = 0;
            write = 0;
            cpu_drive_en = 0;

            // Note: Some write-through/write-back cache
            // implementations may not assert cpu_data_valid
            // for writes. Adapt this completion condition
            // to the intended CPU write handshake if needed.

            if (cycles >= 30 && !cpu_data_valid) begin

                $error(
                    "CPU TRANSACTION TIMEOUT: addr=%h",
                    request_addr
                );

                $fatal;

            end

            @(negedge clk);

            $display(
                "[PASS] Transaction %0d: addr=%h read=%b write=%b delay=%0d",
                test_count,
                request_addr,
                request_read,
                request_write,
                memory_delay
            );

        end

    endtask

    // ------------------------------------------------
    // Test sequences
    // ------------------------------------------------

    task automatic run_tests;

        begin

            $display("");
            $display("========================================");
            $display(" Running tests with memory delay = %0d",
                     memory_delay);
            $display("========================================");

            // Different addresses.
            // Exercise cache-line allocation.

            cpu_request(32'h00000000, 1, 0, 2'b10, 0);
            cpu_request(32'h00000010, 1, 0, 2'b10, 0);
            cpu_request(32'h00000020, 1, 0, 2'b10, 0);
            cpu_request(32'h00000030, 1, 0, 2'b10, 0);

            // More addresses than cache lines.
            // Exercise replacement.

            cpu_request(32'h00000040, 1, 0, 2'b10, 0);
            cpu_request(32'h00000050, 1, 0, 2'b10, 0);
            cpu_request(32'h00000060, 1, 0, 2'b10, 0);
            cpu_request(32'h00000070, 1, 0, 2'b10, 0);

            // Similar addresses.
            // Access multiple words within the same
            // presumed 16-byte cache line.

            cpu_request(32'h00000100, 1, 0, 2'b10, 0);
            cpu_request(32'h00000104, 1, 0, 2'b10, 0);
            cpu_request(32'h00000108, 1, 0, 2'b10, 0);
            cpu_request(32'h0000010C, 1, 0, 2'b10, 0);

            // Repeat reads to test cache hits.

            cpu_request(32'h00000100, 1, 0, 2'b10, 0);
            cpu_request(32'h00000104, 1, 0, 2'b10, 0);

            // Write operations.

            cpu_request(32'h00000200, 0, 1, 2'b10, 32'hDEADBEEF);
            cpu_request(32'h00000204, 0, 1, 2'b10, 32'hCAFEBABE);
            cpu_request(32'h00000208, 0, 1, 2'b10, 32'h12345678);

            // Read after write.

            cpu_request(32'h00000200, 1, 0, 2'b10, 0);
            cpu_request(32'h00000204, 1, 0, 2'b10, 0);

            // Same address, different access widths.

            cpu_request(32'h00000300, 1, 0, 2'b00, 0);
            cpu_request(32'h00000301, 1, 0, 2'b00, 0);
            cpu_request(32'h00000300, 1, 0, 2'b01, 0);
            cpu_request(32'h00000300, 1, 0, 2'b10, 0);

            // Interleaved addresses to exercise
            // multiple cache lines.

            cpu_request(32'h00000400, 1, 0, 2'b10, 0);
            cpu_request(32'h00000500, 1, 0, 2'b10, 0);
            cpu_request(32'h00000404, 1, 0, 2'b10, 0);
            cpu_request(32'h00000600, 1, 0, 2'b10, 0);
            cpu_request(32'h00000504, 1, 0, 2'b10, 0);
            cpu_request(32'h00000700, 1, 0, 2'b10, 0);

            // Repeat accesses after replacement pressure.

            cpu_request(32'h00000400, 1, 0, 2'b10, 0);
            cpu_request(32'h00000700, 1, 0, 2'b10, 0);

            $display("");
            $display("All tests passed for memory delay = %0d",
                     memory_delay);

        end

    endtask

    // ------------------------------------------------
    // Main test
    // ------------------------------------------------

    integer delay_value;

    initial begin

        rst_n = 0;

        addr = 0;
        read = 0;
        write = 0;
        data_width = 0;

        cpu_write_data = 0;
        cpu_drive_en = 0;

        memory_delay = 0;

        repeat (5) @(posedge clk);

        rst_n = 1;

        @(negedge clk);

        // Run the entire test suite for delays 0 to 10.
        for (delay_value = 0; delay_value <= 10;
             delay_value = delay_value + 1) begin

            memory_delay = delay_value;

            // Reset cache between different delay tests.
            rst_n = 0;

            repeat (3) @(posedge clk);

            rst_n = 1;

            @(negedge clk);

            run_tests();

        end

        $display("");
        $display("========================================");
        $display(" ALL TESTS PASSED");
        $display(" Total CPU transactions: %0d", test_count);
        $display(" Memory delays tested: 0 through 10");
        $display("========================================");

        $finish;

    end

    // Global simulation timeout.
    initial begin
        #10000000;
        $fatal(1, "GLOBAL TESTBENCH TIMEOUT");
    end

endmodule
