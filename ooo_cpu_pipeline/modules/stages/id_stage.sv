`include "../instruction_decode/instruction_decode.sv"

module id_stage #(parameter BIT = 32) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [31:0]      instruction_in,

    input  logic [BIT - 1:0] rip_in,

    output logic [6:0]       opcode,
    output logic [4:0]       rs1_index,
    output logic [4:0]       rs2_index,
    output logic [4:0]       rd_index,
    output logic             rd_reserve,
    output logic [BIT - 1:0] imm,
    output logic [2:0]       funct3,
    output logic [6:0]       funct7,
    output logic [BIT - 1:0] rip_out,

    input logic          rs1_valid,
    input logic          rs2_valid,
    output logic         invalid_instruction,

    input logic          ex_accept_ready,
    input  logic         if_deliver_ready,
    output logic         id_deliver_ready,
    output logic         id_accept_ready
);

    reg [31:0] instruction;
    reg [BIT - 1:0] rip;
    reg        instruction_valid;
    logic needs_rs1;
    logic needs_rs2;
    logic needs_rd;

    assign rip_out = rip;

    assign id_accept_ready = (ex_accept_ready && id_deliver_ready) || !instruction_valid;
    assign id_deliver_ready = 
        instruction_valid && 
        (rs1_valid || !needs_rs1) && 
        (rs2_valid || !needs_rs2);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instruction_valid <= 1'b0;
        end else if(id_accept_ready) begin
            instruction_valid <= if_deliver_ready;
            instruction <= instruction_in;
            rip <= rip_in;
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
endmodule
