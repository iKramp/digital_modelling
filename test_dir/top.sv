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

    reg [5:0] counter = 6'd0;
    logic [$clog2(N)-1:0] current_digit;
    logic display_enable;
    
    always_comb begin
        display_enable <= (counter > 6'b010000 && counter < 6'b110000);
    end

    generate
        genvar i;
        for (i = 0; i < N; i = i + 1) begin : digit_selection
            always_comb begin
                if (current_digit == i) begin
                    {SEG_TOP, SEG_TOP_RIGHT, SEG_BOT_RIGHT, SEG_BOT, SEG_BOT_LEFT, SEG_TOP_LEFT, SEG_CENTER} = segments[i*7 +: 7];
                end
            end
        end

        if (N > 8) begin
            initial begin
                $error("N cannot be greater than 8");
            end
        end
    endgenerate

    always_comb begin
        if (current_digit + 1 == N) begin
            current_digit = {N{1'b0}};
        end else begin
            current_digit = current_digit + 1;
        end
    end

    always @(posedge CLK) begin
        counter <= counter + 1;

        if (display_enable) begin
            AN <= {N{1'b1}} ^ (1 << current_digit);
        end else begin
            AN <= {N{1'b1}};
        end
    end


endmodule

module top #(parameter N = 8) (
    input logic  [15:0]  SW,
    input  wire       CLK100MHZ,
    output logic         SEG_TOP,
    output logic         SEG_TOP_RIGHT,
    output logic         SEG_BOT_RIGHT,
    output logic         SEG_BOT,
    output logic         SEG_BOT_LEFT,
    output logic         SEG_TOP_LEFT,
    output logic         SEG_CENTER,
    output logic [7:0]  AN,
);

    reg [31:0] counter = 32'd0;
    reg [29:0] increment_counter = 30'd0;

    logic [6:0] seg;
    logic [6:0] out_seg;

    assign {
            SEG_TOP, 
            SEG_TOP_RIGHT, 
            SEG_BOT_RIGHT, 
            SEG_BOT,
            SEG_BOT_LEFT,
            SEG_TOP_LEFT,
            SEG_CENTER
    } = out_seg;
    
    segment_display seg_disp (
        .num(counter[3:0]),
        .seg(seg)
    );

    n_digit_display #(.N(N)) n_disp (
        .CLK(CLK100MHZ),
        .segments(seg),
        .SEG_TOP(SEG_TOP),
        .SEG_TOP_RIGHT(SEG_TOP_RIGHT),
        .SEG_BOT_RIGHT(SEG_BOT_RIGHT),
        .SEG_BOT(SEG_BOT),
        .SEG_BOT_LEFT(SEG_BOT_LEFT),
        .SEG_TOP_LEFT(SEG_TOP_LEFT),
        .SEG_CENTER(SEG_CENTER),
        .AN(AN[N-1:0])
    );

    always @(posedge CLK100MHZ) begin
        if (increment_counter + 1 == 30'd100000000) begin
            counter <= counter + 1;
            increment_counter <= 0;
        end else begin
            increment_counter <= increment_counter + 1;
        end
    end

endmodule
