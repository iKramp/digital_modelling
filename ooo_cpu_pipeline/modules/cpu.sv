module cpu #(parameter BIT = 32) (
    input logic clk,
    input logic rst_n
);

    logic [31:0]      if_id_instruction;
    logic             if_ready;

    logic [4:0]       id_rs1_index;
    logic [BIT - 1:0] id_ex_rs1_value;
    logic             id_rs1_valid;

    logic [4:0]       id_rs2_index;
    logic [BIT - 1:0] id_ex_rs2_value;
    logic             id_rs2_valid;

    logic [4:0]       id_rd_index;
    logic             wb_rd_write;
    logic [BIT - 1:0] wb_rd_value;
    logic [4:0]       id_rd_reserve_index;
    logic             id_rd_reserve;

    logic [31:0]      id_ex_imm;
    logic [2:0]       id_ex_funct3;
    logic [6:0]       id_ex_funct7;

    logic id_ready;
    logic id_ex_invalid_instruction;

    register_file #(
        .BIT(BIT),
        .N_REGS(32)
    ) reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .instruction(id_if_instruction),
        .if_ready(if_ready),

        .rs1_index(id_rs1_index),
        .rs2_index(id_rs2_index),
        .rd_index(id_rd_reserve_index),
        .rd_reserve(id_rd_reserve),
        .imm(id_ex_imm),
        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),
        
        .rs1_valid(id_rs1_valid),
        .rs2_valid(id_rs2_valid),
        .id_ready(id_ready),
        .invalid_instruction(id_ex_invalid_instruction)
    );


