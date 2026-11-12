///for simplicity invalid fields may contain values
///they are not cleared
///reg_valid is used for fetching values
module format_decoder (
    input  logic [1:0]  format, //0-R, 1-I, 2-S, 3-U
    input  logic        alternate_format, //S -> B, U -> J
    input  logic [31:0] instruction,
    output logic [4:0]  rs1,
    output logic        rs1_valid,
    output logic [4:0]  rs2,
    output logic        rs2_valid,
    output logic [4:0]  rd,
    output logic        rd_valid,
    output logic [31:0] imm,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7
);
    assign funct7 = instruction[32:25];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];

    assign rs1_valid = format != 3;
    assign rs2_valid = format == 0 || format == 2;
    assign rd_valid = format != 2;

    logic immI[31:0];
    logic immS[31:0];
    logic immU[31:0];

    logic immB[31:0];
    logic immJ[31:0];

    assign immI = {
       { 20{instruction[31]} },
       instruction[31:20]
    };

    assign immS = {
       { 20{instruction[31]} },
       instruction[31:25],
       instruction[11:7]
    };

    assign immU = {
       instruction[31:12],
       { 12{1'b0} }
    };

    assign immB = {
       { 20{instruction[31]} },
       instruction[7],
       instruction[30:25],
       instruction[11:8],
       1'b0
    };

    assign immJ = {
       { 12{instruction[31]} },
       instruction[19:12],
       instruction[20],
       instruction[30:21],
       1'b0
    };

    always_comb begin
        case(format)
            2'd0: imm = immI; //no imm, short circuit to immI
            2'd1: imm = immI;
            2'd2: imm = alternate_format ? immB : immS;
            2'd3: imm = alternate_format ? immJ : immU;
        endcase
    end
endmodule
