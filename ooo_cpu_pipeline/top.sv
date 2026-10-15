// module segment_display (
//     input logic [3:0]  num,
//     output logic [6:0]  seg
// );
//     always_comb begin
//         case (num)
//             4'd0: seg = 7'b0000001;
//             4'd1: seg = 7'b1001111;
//             4'd2: seg = 7'b0010010;
//             4'd3: seg = 7'b0000110;
//             4'd4: seg = 7'b1001100;
//             4'd5: seg = 7'b0100100;
//             4'd6: seg = 7'b0100000;
//             4'd7: seg = 7'b0001111;
//             4'd8: seg = 7'b0000000;
//             4'd9: seg = 7'b0000100;
//             4'd10: seg = 7'b0001000; // A
//             4'd11: seg = 7'b1100000; // b
//             4'd12: seg = 7'b0110001; // C
//             4'd13: seg = 7'b1000010; // d
//             4'd14: seg = 7'b0110000; // E
//             4'd15: seg = 7'b0111000; // F
//             default: seg = 7'b1111111; // blank display for invalid input
//         endcase
//     end
// endmodule

module top (
    input logic  [15:0]  SW,
    output logic        CA,
    output logic        CB,
    output logic        CC,
    output logic        CD,
    output logic        CE,
    output logic        CF,
    output logic        CG,
    output logic        CP,
    output logic [7:0]  AN,
    // output logic [1:0]  LED
);
    // segment_display seg_disp (
    //     .num(SW),
    //     .seg(CA)
    // );

    assign CA = SW[0];
    assign CB = SW[1];
    assign CC = SW[2];
    assign CD = SW[3];
    assign CE = SW[4];
    assign CF = SW[5];
    assign CG = SW[6];
    assign CP = SW[7];

    assign AN = SW[15:8];

endmodule
