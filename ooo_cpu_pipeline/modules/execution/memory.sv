///calculates the address of the load/store
module load_store_ex #(parameter BIT = 32) (
    input logic [BIT - 1:0] rs1,
    input logic [BIT - 1:0] imm,

    output logic [BIT - 1:0] result,
    output logic             mem_ready,
    output logic             invalid_instruction
);
    assign mem_ready = 1'b1;
    assign invalid_instruction = 1'b0;
    assign result = rs1 + imm;
endmodule

//fence has nothing to do in ex stage
