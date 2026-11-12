module adder #(parameter BIT = 32) (
    input logic [BIT - 1:0]  in_a,
    input logic [BIT - 1:0]  in_b,
    input logic              subtract,
    output logic [BIT - 1:0] result,
    output logic             overflow
);
    logic [BIT + 1:0]in_a_carry;
    logic [BIT + 1:0]in_b_carry;
    logic [BIT + 1:0]out_carry ;
    assign in_a_carry = {1'b0, in_a, subtract};
    assign in_b_carry = {
        1'b0,
        subtract ? ~in_b : in_b,
        subtract
    };
    assign out_carry = in_a_carry + in_b_carry;
    assign result = out_carry[BIT:1];
    assign overflow = out_carry[BIT + 1];
endmodule

module compare_less #(parameter BIT = 32) (
    input logic  [2:0]       funct3,
    input logic  [BIT - 1:0] in_a,
    input logic  [BIT - 1:0] in_b,
    output logic [BIT - 1:0] result //keep all outputs BIT bits
);
    logic cmp_unsigned;
    assign cmp_unsigned = funct3[0];
    logic unsigned [BIT - 1:0] unsigned_in_a;
    logic unsigned [BIT - 1:0] unsigned_in_b;
    assign unsigned_in_a = in_a;
    assign unsigned_in_b = in_b;

    logic res_signed;
    logic res_unsigned;
    assign res_signed = in_a < in_b;
    assign res_unsigned = unsigned_in_a < unsigned_in_b;
    assign result[0] = cmp_unsigned ? res_unsigned : res_signed;
    assign result[BIT - 1:1] = {BIT - 1{1'b0}};
endmodule


module bitwise_logic #(parameter BIT = 32) (
    input logic  [2:0]       funct3,
    input logic  [BIT - 1:0] in_a,
    input logic  [BIT - 1:0] in_b,
    output logic [BIT - 1:0] result
);
    logic and_;
    logic or_;
    assign and_ = funct3[0];
    assign or_ = funct3[1];
    assign result = 
        and_ ? (in_a & in_b) :
        or_ ? (in_a | in_b) :
        (in_a ^ in_b);
endmodule

module shift #(parameter BIT = 32) (
    input logic  [2:0]       funct3,
    input logic  [BIT - 1:0] in_a,
    input logic  [BIT - 1:0] in_b,
    input logic              arithmetic,
    output logic [BIT - 1:0] result
);
    logic [BIT - 1:0]shift_amount;
    assign shift_amount[$clog2(BIT) - 1:0] = in_b[$clog2(BIT) - 1:0];
    assign shift_amount[BIT - 1:$clog2(BIT)] = 0;

    logic shift_left;
    assign shift_left = funct3[2] == 1'b0;

    logic [BIT - 1:0] sll;
    logic [BIT - 1:0] srl;
    logic [BIT - 1:0] sra;
    assign sll = in_a << shift_amount;
    assign srl = in_a >> shift_amount;
    assign sra = in_a >>> shift_amount;

    assign result = shift_left ? sll : 
        (arithmetic ? sra : srl);
endmodule

module op #(parameter BIT = 32) (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [BIT - 1:0] rs1,
    input logic [BIT - 1:0] rs2,
    input logic [BIT - 1:0] imm,

    output logic [BIT - 1:0] result,
    output logic             op_ready,
    output logic             invalid_instruction
);

    assign op_ready = 1'b1;
    assign invalid_instruction = 1'b0; //no checks for now

    logic is_imm;
    logic alternate; //add -> sub, srl -> sra
    assign is_imm = opcode[5] == 1'b0;
    assign alternate = funct7[5] && (!is_imm || (funct3 == 3'b101));

    logic [BIT - 1:0] value_2;
    assign value_2 = is_imm ? imm : rs2;

    logic [BIT - 1:0] add_result;
    logic             add_overflow;
    logic [BIT - 1:0] set_less_than_result;
    logic [BIT - 1:0] bitwise_logic_result;
    logic [BIT - 1:0] shift_result;

    adder #(.BIT(BIT)) adder (
        .in_a(rs1),
        .in_b(value_2),
        .subtract(alternate),
        .result(add_result),
        .overflow(add_overflow)
    );

    compare_less #(.BIT(BIT)) compare_less (
        .funct3(funct3),
        .in_a(rs1),
        .in_b(value_2),
        .result(set_less_than_result)
    );

    bitwise_logic #(.BIT(BIT)) bitwise_logic (
        .funct3(funct3),
        .in_a(rs1),
        .in_b(value_2),
        .result(bitwise_logic_result)
    );

    shift #(.BIT(BIT)) shift (
        .funct3(funct3),
        .in_a(rs1),
        .in_b(value_2),
        .arithmetic(alternate),
        .result(shift_result)
    );

    always_comb begin
        case (funct3)
            3'b000: result = add_result;
            3'b010,
            3'b011: result = set_less_than_result;
            3'b111,
            3'b110,
            3'b100: result = bitwise_logic_result;
            3'b001,
            3'b101: result = shift_result;
        endcase
    end
endmodule
