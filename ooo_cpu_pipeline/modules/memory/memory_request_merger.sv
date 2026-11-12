module memory_request_merger #(
    parameter BIT = 32, 
    parameter BUS_BIT = 128, 
    parameter ADDR_BIT = BIT
) (
    input logic                                    clk,
    input logic                                    rst_n,

    input logic [ADDR_BIT - $clog2(BUS_BIT) - 1:0] addr1,
    input logic                                    read1,
    input logic                                    write1,
    wire        [BUS_BIT - 1:0]                    data1,
    output logic                                   mem1_ready,

    input logic [ADDR_BIT - $clog2(BUS_BIT) - 1:0] addr2,
    input logic                                    read2,
    input logic                                    write2,
    wire        [BUS_BIT - 1:0]                    data2,
    output logic                                   mem2_ready,

    //memory

    output logic [ADDR_BIT - $clog2(BUS_BIT) - 1:0] addr,
    output logic                                    read,
    output logic                                    write,
    wire        [BUS_BIT - 1:0]                     data,
    input logic                                     mem_ready
);

    localparam STATE_IDLE = 0;
    localparam STATE_1    = 1;
    localparam STATE_2    = 2;

    reg [1:0] state;
    reg next_to_use;

    always_ff @(negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            next_to_use <= 0;
        end
    end

    always_comb begin
        case (state)
            STATE_IDLE: begin
                
            end
        endcase
    end

endmodule
