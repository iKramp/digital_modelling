
module branch #(parameter BIT = 32) (
    input logic [2:0] funct3,
    input logic [BIT - 1:0] rs1,
    input logic [BIT - 1:0] rs2,
    input logic [BIT - 1:0] imm,

    output logic [BIT - 1:0] result,
    output logic             brach_ready,
    output logic             invalid_instruction
);
    logic unsigned rs1_unsigned[BIT - 1:0];
    logic unsigned rs2_unsigned[BIT - 1:0];

    assign branch_ready = 1'b1;
    logic eq;
    logic gt;
    logic gtu;
    logic lt;
    logic ltu;
    assign eq = rs1 == rs2;
    assign neq = rs1 != rs2;
    assign gt = rs1 > rs2;
    assign gtu = rs1_unsigned > rs2_unsigned;
    assign lt = rs1 < rs2;
    assign ltu = rs1_unsigned < rs2_unsigned;

    assign result[31:1] = 31'b0;

    always_comb begin
        case(funct3)
            3'b000: begin
                result[0] <= eq;
                invalid_instruction <= 1'b0;
            end
            3'b001: begin
                result[0] <= neq;
                invalid_instruction <= 1'b0;
            end
            3'b100: begin
                result[0] <= lt;
                invalid_instruction <= 1'b0;
            end
            3'b110: begin
                result[0] <= ltu;
                invalid_instruction <= 1'b0;
            end
            3'b101: begin
                result[0] <= gt || eq;
                invalid_instruction <= 1'b0;
            end
            3'b111: begin
                result[0] <= gtu || eq;
                invalid_instruction <= 1'b0;
            end
            default: begin
                result[0] <= 1'b0;
                invalid_instruction <= 1'b1;
            end
        endcase
    end
endmodule
