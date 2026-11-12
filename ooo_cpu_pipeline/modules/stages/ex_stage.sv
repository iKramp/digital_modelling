`import "../modules/execution/op.sv"
`import "../modules/execution/memory.sv"
`import "../modules/execution/branch.sv"
`import "../modules/execution/lui_auipc_jal_jalr.sv"

module ex_stage #(parameter BIT = 32) (
    input logic              clk,
    input logic              rst_n,

    input logic  [BIT - 1:0] rip_in,
    input logic  [6:0]       opcode_in,
    input logic  [BIT - 1:0] rs1_in,
    input logic  [BIT - 1:0] rs2_in,
    input logic  [BIT - 1:0] imm_in,
    input logic  [2:0]       funct3_in,
    input logic  [6:0]       funct7_in,
    input logic  [4:0]       rd_index_in,
    input logic              invalid_instruction_in,

    input logic              id_deliver_ready,
    input logic              mem_accept_ready,
    output logic             ex_deliver_ready,
    output logic             ex_accept_ready,

    output logic [4:0]       rd_index_out,
    output logic [BIT - 1:0] result,
    output logic [BIT - 1:0] rip_out,
    output logic             invalid_instruction
);
    reg  [6:0]       opcode;
    reg  [BIT - 1:0] rs1;
    reg  [BIT - 1:0] rs2;
    reg  [BIT - 1:0] imm;
    reg  [2:0]       funct3;
    reg  [6:0]       funct7;
    reg  [4:0]       rd_index;
    reg              stage_valid;
    reg  [BIT - 1:0] rip;

    assign rip_out = rip;
    assign ex_accept_ready = (mem_accept_ready && ex_deliver_ready) || !stage_valid;
    assign ex_deliver_ready = stage_valid && module_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_valid <= 1'b0;
        end else if (ex_accept_ready) begin
            opcode <= opcode_in;
            rs1 <= rs1_in;
            rs2 <= rs2_in;
            imm <= imm_in;
            funct3 <= funct3_in;
            funct7 <= funct7_in;
            rd_index <= rd_index_in;
            stage_valid <= id_deliver_ready;
            rip <= rip_in;
        end
    end

    logic [BIT - 1:0]op_res;
    logic op_ready; //unused
    logic op_invalid_instruction;

    logic [BIT - 1:0]brach_res;
    logic brach_ready; //unused
    logic brach_invalid_instruction;

    logic [BIT - 1:0]mem_res;
    logic mem_ready; //unused
    logic mem_invalid_instruction;

    logic [BIT - 1:0]lui_auipc_jal_jalr_res;
    logic lui_auipc_jal_jalr_ready;
    logic lui_auipc_jal_jalr_invalid_instruction;

    op #(.BIT(BIT)) op (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rs1(rs1),
        .rs2(rs2),
        .imm(imm),
        .result(op_res),
        .op_ready(op_ready),
        .invalid_instruction(op_invalid_instruction)
    );
    
    branch #(.BIT(BIT)) branch (
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .imm(imm),
        .result(branch_res),
        .branch_ready(branch_ready),
        .invalid_instruction(branch_invalid_instruction)
    );

    load_store_ex #(.BIT(BIT)) load_store_ex (
        .rs1(rs1),
        .imm(imm),
        .result(mem_res),
        .mem_ready(mem_ready),
        .invalid_instruction(mem_invalid_instruction)
    );

    lui_auipc_jal_jalr #(.BIT(BIT)) lui_auipc_jal_jalr (
        .rip(rip),
        .rs1(rs1),
        .opcode(opcode),
        .imm(imm),
        .result(lui_auipc_jal_jalr_res),
        .invalid_instruction(lui_auipc_jal_jalr_invalid_instruction),
        .ready(lui_auipc_jal_jalr_ready)
    )

    logic module_ready;

    always_comb begin
        case(opcode) begin
            7'b0010011,
            7'b0110011: begin
                result <= op_res;
                module_ready <= op_ready;
                invalid_instruction <= op_invalid_instruction | invalid_instruction_in;
            end
            7'b0110111,
            7'b0010111,
            7'b1101111,
            7'b1100111: begin 
                result <= lui_auipc_jal_jalr_res;
                module_ready <= lui_auipc_jal_jalr_ready;
                invalid_instruction <= lui_auipc_jal_jalr_invalid_instruction;
            end
            7'b1100011: begin
                result <= brach_res;
                module_ready <= branch_ready;
                invalid_instruction <= branch_invalid_instruction | invalid_instruction_in;
            end
            7'b0000011, //load
            7'b0100011: begin //store
                result <= mem_res;
                module_ready <= mem_ready;
                invalid_instruction <= mem_invalid_instruction | invalid_instruction_in;
            end
            7'b0001111, //fence
            7'b1110011: begin //system
                //forward imm
                result <= imm;
                module_ready <= 1'b1;
                invalid_instruction <= 1'b0 | invalid_instruction_in;
            end
            default: begin
                result <= 0;
                module_ready <= 1'b1;
                invalid_instruction <= 1'b1;
            end
        endcase
    end
    

endmodule
