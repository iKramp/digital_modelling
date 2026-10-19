module id_stage #(parameter BIT = 32) (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [31:0]  instruction,
    input  logic         if_ready,

    output logic [4:0]   rs1_index,
    output logic [4:0]   rs2_index,
    output logic [4:0]   rd_index,
    output logic         rd_reserve,
    output logic [31:0]  imm,
    output logic [2:0]   funct3,
    output logic [6:0]   funct7,

    input logic          rs1_valid,
    input logic          rs2_valid,
    output logic         id_ready,
    output logic         invalid_instruction
);

    reg instruction;
    logic needs_rs1;
    logic needs_rs2;
    logic needs_rd;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instruction <= 32'b00000000000000000000000000010011; //ADDI 0 to reg 0 (NOP)
        end else if (if_ready) begin
            instruction <= instruction;
        end
    end
    
    instruction_decode decoder (
        .instruction(instruction),
        .rs1(rs1_index),
        .needs_rs1(needs_rs1),
        .rs2(rs2_index),
        .needs_rs2(needs_rs2),
        .rd(rd_index),
        .needs_rd(needs_rd),
        .imm(imm),
        .funct3(funct3),
        .funct7(funct7),
        .invalid_instruction(invalid_instruction)
    );

    id_ready = (rs1_valid || !needs_rs1) && (rs2_valid || !needs_rs2);

endmodule
