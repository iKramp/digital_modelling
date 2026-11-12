`include "register.sv"

module register_file #(
    parameter BIT = 32, 
    parameter N_REGS = 32, 
    parameter REG_ADDR_WIDTH = $clog2(N_REGS)
) (
    input logic                         clk,
    
    input logic  [REG_ADDR_WIDTH - 1:0] rs1,
    output logic [BIT - 1:0]            rs1_value,
    output logic                        rs1_valid,
    
    input logic  [REG_ADDR_WIDTH - 1:0] rs2,
    output logic [BIT - 1:0]            rs2_value,
    output logic                        rs2_valid,
    
    input logic                         rd_write,
    input logic  [REG_ADDR_WIDTH - 1:0] rd,
    input logic  [BIT - 1:0]            rd_value,

    input logic                         rd_reserve_enable,
    input logic  [REG_ADDR_WIDTH - 1:0] rd_reserve
);
    logic [N_REGS - 1:1]write_enable_net;
    logic [N_REGS - 1:0]write_enable_net_full;
    assign write_enable_net_full = {write_enable_net, 1'b0};

    logic [N_REGS - 1:1]reserve_write_net;
    logic [N_REGS - 1:0]reserve_write_net_full;
    assign reserve_write_net_full = {reserve_write_net, 1'b0};

    logic [N_REGS - 1:1]read_valid_net;
    logic [N_REGS - 1:0]read_valid_net_full;
    assign read_valid_net_full = {read_valid_net, 1'b1};

    logic [BIT - 1:0]value_net[N_REGS - 1:1];
    logic [BIT - 1:0]value_net_full[N_REGS - 1:0];
    assign value_net_full[0] = {BIT{1'b0}};
    genvar i; //register
    generate
        for (i = 1; i < N_REGS; i++) begin : gen_registers
            assign value_net_full[i] = value_net[i];

            cpu_register cpu_reg (
                .clk(clk),
                .write_enable(write_enable_net[i]),
                .reserve_write(reserve_write_net[i]),
                .write_num(rd_value),
                .read_num(value_net[i]),
                .read_valid(read_valid_net[i])
            );

            assign write_enable_net[i] = rd_write && (rd == i);
            assign reserve_write_net[i] = rd_reserve_enable && (rd_reserve == i);
        end
    endgenerate

    always_comb begin
        rs1_value = value_net_full[rs1];
        rs1_valid = read_valid_net_full[rs1];

        rs2_value = value_net_full[rs2];
        rs2_valid = read_valid_net_full[rs2];
    end

endmodule
