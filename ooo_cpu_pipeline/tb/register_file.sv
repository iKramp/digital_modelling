`timescale 1ns/1ps

`include "../modules/registers/register_file.sv"

//will test with only 2 registers for now
module tb_register_file;

    reg clk;
    
    reg [0:0]    rs1;
    reg [0:0]    rs2;

    reg          rd_write;
    reg [0:0]    rd;
    reg [31:0]   rd_value;
    reg          rd_reserve_enable;
    reg [0:0]    rd_reserve;

    logic [31:0] rs1_value;
    logic        rs1_valid;
    logic [31:0] rs2_value;
    logic        rs2_valid;


    integer tests_passed;
    integer tests_failed;
    string test_name;

    // Instantiate design under test
    register_file #(.N_REGS(2)) uut (
        .clk(clk),
        .rs1(rs1),
        .rs1_value(rs1_value),
        .rs1_valid(rs1_valid),
        .rs2(rs2),
        .rs2_value(rs2_value),
        .rs2_valid(rs2_valid),
        .rd_write(rd_write),
        .rd(rd),
        .rd_value(rd_value),
        .rd_reserve_enable(rd_reserve_enable),
        .rd_reserve(rd_reserve)
    );

    // Check only the immediate.
    // Used for formats where other outputs are not relevant.
    task check_rs1(
        input        expected_valid,
        input [31:0] expected_value,
        output       test_passed
    );
        begin
            if (expected_valid === rs1_valid && ((expected_value === rs1_value) || !expected_valid)) begin
                $display("[-rs1] rs1 correct: valid: %d, val: %d", rs1_valid, rs1_value);
                test_passed = 1;
            end
            else begin
                $display("[-rs1] rs1 incorrect: expected valid: %d, val: %d | got valid: %d, val: %d",
                         expected_valid, expected_value, rs1_valid, rs1_value);
                test_passed = 0;
            end
        end
    endtask

    task check_rs2(
        input        expected_valid,
        input [31:0] expected_value,
        output       test_passed
    );
        begin
            if (expected_valid === rs2_valid && ((expected_value === rs2_value) || !expected_valid)) begin
                $display("[-rs2] rs2 correct: valid: %d, val: %d", rs2_valid, rs2_value);
                test_passed = 1;
            end
            else begin
                $display("[-rs2] rs2 incorrect: expected valid: %d, val: %d | got valid: %d, val: %d",
                         expected_valid, expected_value, rs2_valid, rs2_value);
                test_passed = 0;
            end
        end
    endtask

    task check_rs(
        input        expected_rs1_valid,
        input [31:0] expected_rs1_value,
        input        expected_rs2_valid,
        input [31:0] expected_rs2_value,
        input string test_name
    );
        #1; //delay to propagate to output
        begin
            logic rs1_passed;
            logic rs2_passed;
            logic test_passed;
            check_rs1(expected_rs1_valid, expected_rs1_value, rs1_passed);
            check_rs2(expected_rs2_valid, expected_rs2_value, rs2_passed);
            test_passed = rs1_passed && rs2_passed;
            tests_passed += test_passed;
            tests_failed += !test_passed;
            if (test_passed) begin
                $display("[PASS] %s", test_name);
            end else begin
                $display("[FAIL] %s", test_name);
            end
        end
    endtask

    task set_inputs(
        input [0:0]  rs1_in,
        input [0:0]  rs2_in,
        input        rd_write_in,
        input [0:0]  rd_in,
        input [31:0] rd_value_in,
        input        rd_reserve_enable_in,
        input [0:0]  rd_reserve_in
    );
        begin
            rs1      = rs1_in;
            rs2      = rs2_in;
            rd_write = rd_write_in;
            rd       = rd_in;
            rd_value = rd_value_in;
            rd_reserve_enable = rd_reserve_enable_in;
            rd_reserve = rd_reserve_in;
        end
    endtask

    task clock_tick();
        begin
            clk = 0;
            #5;
            clk = 1;
            #5;
        end
    endtask

    task start_test(input string test_name);
        begin
            $display("[TEST START] %s", test_name);
        end
    endtask

    // Stimulus
    initial begin
        $dumpfile("tb_register_file.vcd");
        $dumpvars(0, tb_register_file);

        tests_passed = 0;
        tests_failed = 0;

        $display("Starting register_file simulation");

        // register 0 tests - all reads return 0
        test_name = "Write to register 0 and read back";
        start_test(test_name);
        set_inputs(0, 0, 1, 0, 32'hDEADBEEF, 0, 0);
        clock_tick();
        check_rs(1, 32'd0, 1, 32'd0, test_name);

        //regular register tests - read after write + clock cycle return the
        //value written
        test_name = "Write to register 1 and read back";
        start_test(test_name);
        set_inputs(1, 0, 1, 1, 32'hCAFEBABE, 0, 0);
        clock_tick();
        check_rs(1, 32'hCAFEBABE, 1, 32'd0, test_name);

        //reserve write tests - reads return not valid until a write happens
        //in this test try write + clock + read
        test_name = "Reserve write to register 1 and read back before write";
        start_test(test_name);
        set_inputs(1, 0, 0, 0, 32'd0, 1, 1);
        clock_tick();
        clock_tick();
        check_rs(0, 32'd0, 1, 32'd0, test_name);
        test_name = "Reserve write to register 1 and read back after write";
        clock_tick();
        set_inputs(1, 0, 1, 1, 32'hDEADCAFE, 0, 0);
        clock_tick();
        check_rs(1, 32'hDEADCAFE, 1, 32'd0, test_name);

        //reserve write tests - reads return not valid until a write happens
        //in this test try write + read in the same clock cycle, should return
        //valid with new value
        test_name = "Reserve write to register 1 and read back before write";
        start_test(test_name);
        set_inputs(1, 0, 0, 0, 32'd0, 1, 1);
        clock_tick();
        check_rs(0, 32'd0, 1, 32'd0, test_name);
        test_name = "Reserve write to register 1 and read back at write";
        clock_tick();
        set_inputs(1, 0, 1, 1, 32'hAAAAAAAA, 0, 0);
        check_rs(1, 32'hAAAAAAAA, 1, 32'd0, test_name);
        

        // =====================================================
        // Summary
        // =====================================================

        $display("----------------------------------------");
        $display("Simulation complete");
        $display("Tests passed: %0d", tests_passed);
        $display("Tests failed: %0d", tests_failed);
        $display("----------------------------------------");

        if (tests_failed != 0)
            $fatal(1, "format_decoder testbench FAILED");

        $finish;
    end

endmodule
