module segment_display (
    input logic [3:0]  num,
    output logic [6:0]  seg
);
    always_comb begin
        case (num)
            4'd0: seg = 7'b0000001;
            4'd1: seg = 7'b1001111;
            4'd2: seg = 7'b0010010;
            4'd3: seg = 7'b0000110;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100100;
            4'd6: seg = 7'b0100000;
            4'd7: seg = 7'b0001111;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0000100;
            4'd10: seg = 7'b0001000; // A
            4'd11: seg = 7'b1100000; // b
            4'd12: seg = 7'b0110001; // C
            4'd13: seg = 7'b1000010; // d
            4'd14: seg = 7'b0110000; // E
            4'd15: seg = 7'b0111000; // F
            default: seg = 7'b1111111; // blank display for invalid input
        endcase
    end
endmodule

module n_digit_display #(parameter N = 1) (
    input logic            CLK,
    input logic [N*7-1:0]  segments,
    output logic           SEG_TOP,
    output logic           SEG_TOP_RIGHT,
    output logic           SEG_BOT_RIGHT,
    output logic           SEG_BOT,
    output logic           SEG_BOT_LEFT,
    output logic           SEG_TOP_LEFT,
    output logic           SEG_CENTER,
    output logic [N-1:0]   AN
);

    reg [6:0] counter = 7'd0;
    logic [2:0] current_digit;
    logic display_enable;
    
    always_comb begin
        display_enable <= (counter > 7'b0110000 && counter < 7'b1000000);
    end

    always_comb begin
        {SEG_TOP, SEG_TOP_RIGHT, SEG_BOT_RIGHT, SEG_BOT, SEG_BOT_LEFT, SEG_TOP_LEFT, SEG_CENTER} <= segments[current_digit*7 +: 7];
    end

    always @(posedge CLK) begin
        counter <= counter + 1;

        if (counter == 0) begin
            if (current_digit + 1 == N) begin
                current_digit <= 0;
            end else begin
                current_digit <= current_digit + 1;
            end
        end


        if (display_enable) begin
            AN <= {N{1'b1}} ^ (1 << current_digit);
        end else begin
            AN <= {N{1'b1}};
        end
    end
endmodule

module n_digit_display_numbers #(parameter N = 1) (
    input logic            CLK,
    input logic [N*4-1:0]  numbers,
    output logic           SEG_TOP,
    output logic           SEG_TOP_RIGHT,
    output logic           SEG_BOT_RIGHT,
    output logic           SEG_BOT,
    output logic           SEG_BOT_LEFT,
    output logic           SEG_TOP_LEFT,
    output logic           SEG_CENTER,
    output logic [N-1:0]   AN
);

    logic [N*7-1:0] segments;

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : gen_segment_display
            segment_display seg_disp (
                .num(numbers[i*4 +: 4]),
                .seg(segments[i*7 +: 7])
            );
        end
    endgenerate

    n_digit_display #(.N(N)) n_disp (
        .CLK(CLK),
        .segments(segments),
        .SEG_TOP(SEG_TOP),
        .SEG_TOP_RIGHT(SEG_TOP_RIGHT),
        .SEG_BOT_RIGHT(SEG_BOT_RIGHT),
        .SEG_BOT(SEG_BOT),
        .SEG_BOT_LEFT(SEG_BOT_LEFT),
        .SEG_TOP_LEFT(SEG_TOP_LEFT),
        .SEG_CENTER(SEG_CENTER),
        .AN(AN)
    );
endmodule

module top #(parameter N = 5) (
    input  logic         CPU_RESETN,
    input  logic         CLK100MHZ,
    output logic         SEG_TOP,
    output logic         SEG_TOP_RIGHT,
    output logic         SEG_BOT_RIGHT,
    output logic         SEG_BOT,
    output logic         SEG_BOT_LEFT,
    output logic         SEG_TOP_LEFT,
    output logic         SEG_CENTER,
    output logic         SEG_DECIMAL,
    output logic [7:0]   AN
);

    reg [31:0] counter = 32'd0;
    reg [29:0] increment_counter = 30'd0;

    logic [6:0] seg0;
    logic [6:0] seg1;
    logic [6:0] seg2;
    logic [6:0] seg3;

    logic [7:0] tmp_an;

    logic decimal_net[19:0];
    // assign decimal_net = bin2bcd(counter[15:0]);
    bin_to_bcd #(.INPUT_WIDTH(16)) bcd_converter (
        .clk(CLK100MHZ),
        .rst_n(CPU_RESETN),
        .in_valid(increment_counter == 30'd0),
        .bin_in(counter[15:0]),
        .bcd_out(decimal_net)
    );
    
    n_digit_display_numbers #(.N(N)) n_disp (
        .CLK(CLK100MHZ),
        .numbers(decimal_net),
        .SEG_TOP(SEG_TOP),
        .SEG_TOP_RIGHT(SEG_TOP_RIGHT),
        .SEG_BOT_RIGHT(SEG_BOT_RIGHT),
        .SEG_BOT(SEG_BOT),
        .SEG_BOT_LEFT(SEG_BOT_LEFT),
        .SEG_TOP_LEFT(SEG_TOP_LEFT),
        .SEG_CENTER(SEG_CENTER),
        .AN(tmp_an[N-1:0])
    );

    assign tmp_an[7:N] = -1; // Turn off unused anodes
    assign AN = tmp_an;

    assign SEG_DECIMAL = 1'b1; // Decimal point is always off

    always @(posedge CLK100MHZ, negedge CPU_RESETN) begin
        if (!CPU_RESETN) begin
            counter <= 32'd0;
            increment_counter <= 30'd0;
        end else if (increment_counter + 1 == 30'd100000000) begin
            counter <= counter + 1;
            increment_counter <= 0;
        end else begin
            increment_counter <= increment_counter + 1;
        end
    end

endmodule
