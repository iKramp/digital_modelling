module top (
    input  wire       CLK100MHZ,
    input  wire       BTNC,
    output reg  [7:0] LED
);

    always @(posedge CLK100MHZ) begin
        if (BTNC)
            LED <= 8'b0;
        else
            LED <= LED + 1'b1;
    end

endmodule
