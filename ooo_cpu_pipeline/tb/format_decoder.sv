`timescale 1ns/1ps

module tb_format_decoder;

    reg  [1:0]  format;
    reg  [31:0] instruction;

    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [31:0] imm;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    integer tests_passed;
    integer tests_failed;

    // Instantiate design under test
    format_decoder uut (
        .format(format),
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm),
        .funct3(funct3),
        .funct7(funct7)
    );

    // Check only the immediate.
    // Used for formats where other outputs are not relevant.
    task check_imm(
        input [1:0]  test_format,
        input [31:0] test_instruction,
        input [31:0] expected_imm,
        input string test_name
    );
        begin
            format      = test_format;
            instruction = test_instruction;
            #1;

            if (imm === expected_imm) begin
                $display("[PASS] %s | imm = %h",
                         test_name, imm);
                tests_passed = tests_passed + 1;
            end
            else begin
                $display("[FAIL] %s | expected imm = %h, got = %h",
                         test_name, expected_imm, imm);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    // Check immediate and register fields when applicable.
    task check_fields(
        input [1:0]  test_format,
        input [31:0] test_instruction,
        input [31:0] expected_imm,
        input [4:0]  expected_rs1,
        input [4:0]  expected_rs2,
        input [4:0]  expected_rd,
        input [2:0]  expected_funct3,
        input [6:0]  expected_funct7,
        input string test_name
    );
        begin
            format      = test_format;
            instruction = test_instruction;
            #1;

            if ((imm    === expected_imm) &&
                (rs1    === expected_rs1) &&
                (rs2    === expected_rs2) &&
                (rd     === expected_rd) &&
                (funct3 === expected_funct3) &&
                (funct7 === expected_funct7)) begin

                $display("[PASS] %s", test_name);
                tests_passed = tests_passed + 1;
            end
            else begin
                $display("[FAIL] %s", test_name);
                $display("       imm    expected=%h actual=%h",
                         expected_imm, imm);
                $display("       rs1    expected=%h actual=%h",
                         expected_rs1, rs1);
                $display("       rs2    expected=%h actual=%h",
                         expected_rs2, rs2);
                $display("       rd     expected=%h actual=%h",
                         expected_rd, rd);
                $display("       funct3 expected=%h actual=%h",
                         expected_funct3, funct3);
                $display("       funct7 expected=%h actual=%h",
                         expected_funct7, funct7);

                tests_failed = tests_failed + 1;
            end
        end
    endtask

    // Stimulus
    initial begin
        $dumpfile("tb_format_decoder.vcd");
        $dumpvars(0, tb_format_decoder);

        format      = 0;
        instruction = 0;
        tests_passed = 0;
        tests_failed = 0;

        $display("Starting format_decoder simulation");

        // =====================================================
        // R FORMAT: format = 2'b00
        //
        // R format has no immediate. Check register fields
        // and function fields, but ignore imm.
        // =====================================================

        // add x3, x1, x2
        // funct7=0000000, rs2=00010, rs1=00001,
        // funct3=000, rd=00011, opcode=0110011
        check_fields(
            2'b00, 32'h002081B3,
            33'h0,       // imm ignored by this format
            5'd1, 5'd2, 5'd3,
            3'b000, 7'b0000000,
            "R: ADD x3, x1, x2"
        );

        // sub x5, x6, x7
        // funct7=0100000, rs2=7, rs1=6,
        // funct3=000, rd=5
        check_fields(
            2'b00, 32'h407302B3,
            33'h0,       // imm ignored
            5'd6, 5'd7, 5'd5,
            3'b000, 7'b0100000,
            "R: SUB x5, x6, x7"
        );

        // =====================================================
        // I FORMAT: format = 2'b01
        // Immediate = sign_extend(instruction[31:20])
        // =====================================================

        // addi x1, x2, 5
        // Immediate = +5
        check_fields(
            2'b01, 32'h00510093,
            33'h000000005,
            5'd2, 5'd0, 5'd1,
            3'b000, 7'b0000000,
            "I: ADDI with positive immediate"
        );

        // addi x3, x4, -1
        // Immediate field = 12'hFFF
        // Expected 33-bit sign extension = 1FFFFFFFF
        check_imm(
            2'b01, 32'hFFF20193,
            33'h1FFFFFFFF,
            "I: Negative immediate -1"
        );

        // addi x5, x6, -2048
        // Minimum signed 12-bit immediate = 12'h800
        check_imm(
            2'b01, 32'h80030293,
            33'h1FFFFF800,
            "I: Minimum signed immediate -2048"
        );

        // addi x7, x8, 2047
        // Maximum signed 12-bit immediate = 12'h7FF
        check_imm(
            2'b01, 32'h7FF40393,
            33'h0000007FF,
            "I: Maximum signed immediate +2047"
        );

        // lw x9, 16(x10)
        // Immediate = +16
        check_imm(
            2'b01, 32'h01052483,
            33'h000000010,
            "I: Load positive offset +16"
        );

        // lw x11, -8(x12)
        // Immediate = -8
        check_imm(
            2'b01, 32'hFF842583,
            33'h1FFFFFFF8,
            "I: Load negative offset -8"
        );

        // =====================================================
        // S FORMAT: format = 2'b10
        // Immediate = {instruction[31:25],
        //              instruction[11:7]}
        // Sign extend the resulting 12-bit value.
        // =====================================================

        // sw x2, 12(x1)
        // S immediate = 12
        check_imm(
            2'b10, 32'h0020A623,
            33'h00000000C,
            "S: Store positive offset +12"
        );

        // sw x3, -1(x4)
        // Immediate bits = 12'hFFF
        check_imm(
            2'b10, 32'hFE322FA3,
            33'h1FFFFFFFF,
            "S: Store negative offset -1"
        );

        // sw x5, -2048(x6)
        // Minimum signed 12-bit immediate
        check_imm(
            2'b10, 32'h80532023,
            33'h1FFFFF800,
            "S: Minimum signed immediate -2048"
        );

        // sw x7, 2047(x8)
        // Maximum signed 12-bit immediate
        check_imm(
            2'b10, 32'h7E742FA3,
            33'h0000007FF,
            "S: Maximum signed immediate +2047"
        );

        // sw x9, 0(x10)
        check_imm(
            2'b10, 32'h00952023,
            33'h000000000,
            "S: Zero immediate"
        );

        // =====================================================
        // U FORMAT: format = 2'b11
        // Standard RV32 U immediate:
        // imm = sign_extend({instruction[31:12], 12'b0})
        //
        // These checks assume imm is signed-extended to 33 bits.
        // =====================================================

        // lui x1, 0x12345
        // Immediate = 0x12345000
        check_imm(
            2'b11, 32'h123450B7,
            33'h012345000,
            "U: LUI positive immediate"
        );

        // lui x2, 0x80000
        // Bit 31 of the immediate is set.
        // Expected signed 33-bit value = -0x80000000
        check_imm(
            2'b11, 32'h80000137,
            33'h180000000,
            "U: LUI with sign bit set"
        );

        // lui x3, 0xFFFFF
        // Immediate bits = 0xFFFFF000
        // Sign-extended 33-bit value = -4096
        check_imm(
            2'b11, 32'hFFFFF1B7,
            33'h1FFFFF000,
            "U: LUI all upper immediate bits set"
        );

        // lui x4, 0x00001
        // Immediate = 0x00001000
        check_imm(
            2'b11, 32'h00001237,
            33'h000001000,
            "U: LUI smallest positive nonzero immediate"
        );

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

