
`include "stages/id_stage.sv"
`include "stages/ex_stage.sv"
`include "registers/register_file.sv"

module cpu #(parameter BIT = 32) (
    input logic clk,
    input logic rst_n
);

    logic [31:0]      if_id_instruction;
    logic             if_ready;

    //ID out
    logic [4:0]       id_rs1_index;
    logic [BIT - 1:0] id_ex_rs1_value;
    logic             id_rs1_valid;

    logic [4:0]       id_rs2_index;
    logic [BIT - 1:0] id_ex_rs2_value;
    logic             id_rs2_valid;

    logic [4:0]       wb_rd_index;
    logic             wb_rd_write;
    logic [BIT - 1:0] wb_rd_value;
    logic [4:0]       id_rd_reserve_index;
    logic             id_rd_reserve;

    logic [BIT - 1:0] id_ex_imm;
    logic [2:0]       id_ex_funct3;
    logic [6:0]       id_ex_funct7;

    logic             id_ex_opcode;

    //EX out
    logic [BIT - 1:0] ex_mem_result;
    logic [4:0]       ex_mem_rd_index;

    logic id_ex_invalid_instruction;
    logic ex_mem_invalid_instruction;
    logic mem_wb_invalid_instruction;

    //ready lines
    logic if_deliver_ready;
    logic id_accept_ready;
    logic id_deliver_ready;
    logic ex_accept_ready;
    logic ex_deliver_ready;
    logic mem_accept_ready;
    logic mem_deliver_ready;
    logic wb_accept_ready;

    //rip bridge
    logic [BIT - 1:0] if_id_rip;
    logic [BIT - 1:0] id_ex_rip;
    logic [BIT - 1:0] ex_mem_rip;
    logic [BIT - 1:0] mem_wb_rip;

    regsiter_file #(
        .BIT(BIT)
    ) register_file (
        .clk(clk),

        .rs1(id_rs1_index),
        .rs1_value(id_ex_rs1_value),
        .rs1_valid(id_rs1_valid),

        .rs2(id_rs2_index),
        .rs2_value(id_ex_rs2_value),
        .rs2_valid(id_rs2_valid),

        .rd_write(wb_rd_write),
        .rd(wb_rd_index),
        .rd_value(wb_rd_value),

        .rd_reserve_enable(id_rd_reserve),
        .rd_reserve(id_rd_reserve_index)
    );

    id_stage #(
        .BIT(BIT)
    ) id_stage (
        .clk(clk),                                          //input
        .rst_n(rst_n),
        .instruction(if_id_instruction),

        .rip_in(if_id_rip),

        .opcode(id_ex_opcode),                              //output
        .rs1_index(id_rs1_index),
        .rs2_index(id_rs2_index),
        .rd_index(id_rd_reserve_index),
        .rd_reserve(id_rd_reserve),
        .imm(id_ex_imm),
        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),
        .rip_out(id_ex_rip),
        
        .rs1_valid(id_rs1_valid),                           //input
        .rs2_valid(id_rs2_valid),
        .invalid_instruction(id_ex_invalid_instruction),    //output

        .ex_accept_ready(ex_accept_ready),                  //input
        .if_deliver_ready(if_deliver_ready),
        .id_deliver_ready(id_deliver_ready),                //output
        .id_accept_ready(id_accept_ready)
    );

    ex_stage #(
        .BIT(BIT)
    ) ex_stage (
        .clk(clk),
        .rst_n(rst_n),

        .rip_in(id_ex_rip),
        .opcode_in(id_ex_opcode),
        .rs1_in(id_ex_rs1_value),
        .rs2_in(id_ex_rs2_value),
        .imm_in(id_ex_imm),
        .funct3_in(id_ex_funct3),
        .funct7_in(id_ex_funct7),
        .rd_index_in(if_rd_reserve_index),
        .invalid_instruction_in(id_ex_invalid_instruction),

        .id_deliver_ready(id_deliver_ready),
        .mem_accept_ready(mem_accept_ready),
        .ex_deliver_ready(ex_deliver_ready), //outputs from here
        .ex_accept_ready(ex_accept_ready),

        .rd_index_out(ex_mem_rd_index),
        .result(ex_mem_result),
        .rip_out(ex_mem_rip),
        .invalid_instruction(ex_mem_invalid_instruction)
    );

    endmodule

