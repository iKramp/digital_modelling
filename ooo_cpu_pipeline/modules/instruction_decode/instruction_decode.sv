
`include "formats.sv"

module instruction_decode (
    input  logic [31:0] instruction,
    output logic [4:0]  rs1,
    output logic        needs_rs1,
    output logic [4:0]  rs2,
    output logic        needs_rs2,
    output logic [4:0]  rd,
    output logic        needs_rd,
    output logic [31:0] imm,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7,
    output logic        invalid_instruction
);
    // Determine the instruction format based on the opcode
    logic [1:0] format; //0-R, 1-I, 2-S, 3-U
    logic       alternate_format; //S -> B, U -> J
    logic       j_format;
    logic       b_format;
    assign alternate_format = (j_format || b_format);
    assign j_format = (instruction[6:0] == 7'b1101111); // JAL
    assign b_format = (instruction[6:0] == 7'b1100011); // Branch instructions

    
    always_comb begin
        case (instruction[6:0]) // opcode is in bits [6:0]
            7'b0110011: format = 2'b00; // (OP)     R-type
            7'b0010011: format = 2'b01; // (OP-IMM) I-type
            7'b0110111,                 // (LUI)    U-type
            7'b0010111: format = 2'b11; // (AUIPC)  U-type
            7'b1101111: format = 2'b10; // (JAL)    J-type
            7'b1100111: format = 2'b01; // (JALR)   I-type
            7'b1100011: format = 2'b10; // (BRANCH) B-type
            7'b0000011: format = 2'b01; // (LOAD)   I-type
            7'b0100011: format = 2'b10; // (STORE)  S-type
            7'b0001111,                 // (FENCE)  I-type
            7'b1110011: format = 2'b01; // (SYSTEM) I-type
            7'b0101111: format = 2'b00; // (AMO)    R-type
            default:    invalid_instruction = 1;
        endcase
    end

    // Instantiate the format decoder
    format_decoder fd (
        .format(format),
        .alternate_format(alternate_format),
        .instruction(instruction),
        .rs1(rs1),
        .rs1_valid(needs_rs1),
        .rs2(rs2),
        .rs2_valid(needs_rs2),
        .rd(rd),
        .rd_valid(needs_rd),
        .imm(imm),
        .funct3(funct3),
        .funct7(funct7)
    );
