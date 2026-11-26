

//addr 1 is instruction fetch, addr 2 is mem unit
//addr 2 has priority
module memory_controller #(
    parameter BIT = 32, 
    parameter BUS_BIT = 128, 
    parameter ADDR_BIT = BIT
) (
    input logic                   clk,
    input logic                   rst_n,
    
    input logic [ADDR_BIT - 1:0]  addr1,
    input logic                   write1,
    input logic [1:0]             write1_width,
    input logic                   read1,
    wire        [BIT - 1:0]       data1,
    output logic                  data1_valid,

    input logic [ADDR_BIT - 1:0]  addr2,
    input logic                   write2,
    input logic [1:0]             write2_width,
    input logic                   read2,
    wire        [BIT - 1:0]       data2,
    output logic                  data2_valid,
    
    //on memory side
    wire         [BUS_BIT - 1:0]  data_mem, //128 bit data bus
    output logic [ADDR_BIT - 1:0] addr_mem, 
    output logic                  write_mem,
    output logic [1:0]            write_width,
    output logic                  read_mem,
    input  logic                  mem_ready
);

    localparam IDLE = 0;
    localparam WAITING_FOR_INSTRUCTION_READ = 1;
    localparam WAITING_FOR_DATA_READ = 1;
    localparam WAITING_FOR_DATA_WRITE = 2;

    reg [1:0] state;

    logic [ADDR_BIT - 1:0]   icache_addr;
    logic                    icache_read;
    logic                    icache_write;
    logic [BUS_BIT - 1:0]    icache_data_to_write;
    logic [BIT - 1:0]        icache_data_to_read;
    logic                    icache_data_valid;

    assign icache_addr = addr1;
    assign icache_write = write1;

    logic [5:0]              decision_line;
    assign decision_line = {read2, write2, read1, write1, state};

    cache_mod #(.BIT(BIT), .BUS_BIT(BUS_BIT), .ADDR_BIT(ADDR_BIT)) instruction_cache (
        .clk(clk),
        .rst_n(rst_n),
        .addr(icache_addr),
        .read(icache_read),
        .write(icache_write),
        .write_unit(1'b0),
        .write_width(2'b00),
        .data_in(icache_data_to_write),
        .data_out(icache_data_to_read),
        .data_valid(icache_data_valid),
    );

    // always_ff @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         state <= IDLE;
    //     end else begin
    //         if (state == WAITING_FROM_INSTRUCTION_READ) begin
    //             icache_read <= 1'b0;
    //             icache_data_to_write <= data_mem;
    //             icache_write <= mem_ready;
    //             if (mem_ready) begin
    //                 state <= IDLE;
    //                 data1 <= icache_data_to_read;
    //                 data2_valid <= 1'b1;
    //             end else begin
    //                 state <= WAITING_FOR_INSTRUCTION_READ;
    //                 data2_valid <= 1'b0;
    //             end
    //         end else begin
    //             icache_read <= read1;
    //         end
    //     end
    // end

    always_comb begin 
            
    end

endmodule
