module lui_auipc_jal_jalr #(parameter BIT = 32) (
    input  logic [BIT - 1:0] rip,
    input  logic [BIT - 1:0] rs1,
    input  logic [6:0]       opcode,
    input  logic [BIT - 1:0] imm,
    output logic [BIT - 1:0] result,
    output logic             invalid_instruction,
    output logic             ready
);
    assign ready = 1'b1;
    assign invalid_instruction = 1'b0;

    logic [BIT - 1:0] lui_result;
    logic [BIT - 1:0] auipc_result;
    logic [BIT - 1:0] jal_result;
    logic [BIT - 1:0] jalr_result;
    logic [BIT - 1:0] jalr_intermediate_result;
    logic             is_jump;
    logic             is_auipc;
    logic             jump_register;

    assign lui_result = imm;
    assign auipc_result = rip + imm;
    assign jal_result = auipc; //same calculation
    assign jalr_intermediate_result = rs1 + imm;
    assign jalr_result = {jalr_intermediate_result[BIT - 1:1], 1'b1};
    assign is_auipc = opcode[5] == 1'b0;
    assign is_jump = opcode[6] == 1'b1;
    assign jump_register = opcode[3] == 1'b0;

    assign result = is_jump ?
        (jump_register ? jalr_result : jal_result) :
        (is_auipc ? auipc_result : lui_result);
endmodule
