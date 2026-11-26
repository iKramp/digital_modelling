//always reads BIT bits
module cache_mod #(
    parameter BIT = 32, 
    parameter  BUS_BIT = 128, 
    parameter ADDR_BIT = BIT,
    parameter CACHE_LINES = 4
) (
    input logic                  clk,
    input logic                  rst_n,

    input logic [ADDR_BIT - 1:0] addr,
    input logic                  read,
    input logic                  write,
    input logic [1:0]            data_width,
    inout wire  [BIT - 1:0]      cpu_data,
    output logic                 cpu_data_valid,

    input logic                  mem_ready,
    inout wire  [BUS_BIT - 1:0]  mem_data,
    output logic                 mem_read,
    output logic                 mem_write,
    output logic [ADDR_BIT - 1:0] mem_addr
);
    localparam CACHE_LINE_CNT_BITS = $clog2(CACHE_LINES);
    localparam ADDR_IGNORED_BITS = $clog2(BUS_BIT / 8);
    localparam CACHE_ADDR_BITS = ADDR_BIT - ADDR_IGNORED_BITS;

    reg [ADDR_BIT - 1:0] cpu_addr_reg;

    reg [BUS_BIT - 1:0] cache_data [CACHE_LINES - 1:0];
    reg [CACHE_ADDR_BITS - 1:0] cache_addr [CACHE_LINES - 1:0];
    reg [CACHE_LINES - 1:0] cache_line_valid;
    reg [CACHE_LINES - 1:0] cache_line_dirty;

    reg [CACHE_LINE_CNT_BITS - 1:0] cache_line_counter;
    // reg [1:0] state;
    typedef enum bit [1:0] {
        IDLE,
        WAITING_FOR_MEM_READ,
        WAITING_FOR_MEM_WRITE
    } state_t;
    state_t state;

    logic addr_match;
    logic [CACHE_LINE_CNT_BITS - 1:0] matched_line;

    logic cpu_data_in;
    logic [BIT - 1:0] cpu_data_out;
    assign cpu_data = cpu_data_in ? 'z : cpu_data_out;
    assign cpu_data_in = write;

    logic mem_data_in;
    logic [BUS_BIT - 1:0] mem_data_out;
    assign mem_data = mem_data_in ? 'z : mem_data_out;
    assign mem_data_in = mem_read;


    //cache line matching
    logic [CACHE_ADDR_BITS - 1:0] cache_addr_to_check;
    assign cache_addr_to_check = addr[ADDR_BIT - 1:ADDR_IGNORED_BITS];
    always_comb begin
        addr_match = 0;
        matched_line = 0;
        for (int i = 0; i < CACHE_LINES; i++) begin
            if (cache_line_valid[i] && cache_addr[i] == cache_addr_to_check) begin
                addr_match = 1;
                matched_line = i;
            end
        end
    end
    reg [CACHE_LINE_CNT_BITS-1:0] selected_line;

    logic [ADDR_IGNORED_BITS - 1:0] in_line_offset;
    assign in_line_offset = addr[ADDR_IGNORED_BITS - 1:0];


    //empty cache line selection
    logic [CACHE_LINE_CNT_BITS - 1:0] empty_line;
    logic has_to_be_emptied;

    always_comb begin
        logic found;
        empty_line = 0;
        has_to_be_emptied = 1;
        found = 0;
        for (int i = 0; i < CACHE_LINES; i++) begin
            if (!found && !cache_line_valid[i]) begin
                empty_line = i;
                has_to_be_emptied = 0;
                found = 1;
            end
        end
        for (int i = 0; i < CACHE_LINES; i++) begin
            if (!found && !cache_line_dirty[(cache_line_counter + i) % CACHE_LINES]) begin
                empty_line = (cache_line_counter + i) % CACHE_LINES;
                has_to_be_emptied = 0;
                found = 1;
            end
        end
        if (!found) begin
            empty_line = cache_line_counter;
            has_to_be_emptied = 1;
        end
    end

    logic cpu_data_64bit;
    generate
        if (BIT == 64) begin
            assign cpu_data_64bit = cpu_data;
        end else begin
            assign cpu_data_64bit = 0;
        end
    endgenerate


    state_t next_state;

    always_comb begin
        next_state = state;
        cpu_data_valid = 0;

        mem_read = 0;
        mem_write = 0;
        mem_addr = 0;

        cpu_data_out = '0;
        mem_data_out = '0;

        case (state)
            IDLE: begin
                if (read && addr_match) begin
                    cpu_data_out = cache_data[matched_line][in_line_offset * 8 +: BIT];
                    cpu_data_valid = 1;
                end else if (read && !addr_match) begin
                    if (has_to_be_emptied) begin
                        next_state = WAITING_FOR_MEM_WRITE;
                    end else begin
                        next_state = WAITING_FOR_MEM_READ;
                    end
                end else if (write && addr_match) begin
                    //cpu data written on posedge clk
                    cpu_data_valid = 1;
                end else if (write && !addr_match) begin
                    if (has_to_be_emptied) begin
                        next_state = WAITING_FOR_MEM_WRITE;
                    end else begin
                        next_state = WAITING_FOR_MEM_READ;
                    end
                end
            end
            WAITING_FOR_MEM_READ: begin
                if (mem_ready) begin
                    next_state = IDLE;
                end
                
                mem_addr = cpu_addr_reg;
                mem_read = 1;
                mem_write = 0;
            end
            WAITING_FOR_MEM_WRITE: begin
                if (mem_ready) begin
                    next_state = IDLE;
                end

                mem_read = 0;
                mem_write = 1;
                mem_addr = cache_addr[selected_line];
                mem_data_out = cache_data[selected_line];
            end
            default: begin
                next_state = IDLE;
                mem_read = 0;
                mem_write = 0;
                mem_addr = 0;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cache_line_valid <= 0;
            cache_line_dirty <= 0;
            cache_line_counter <= 0;
        end else begin
            case (state)
                WAITING_FOR_MEM_READ: begin
                    if (mem_ready) begin
                        cache_data[selected_line] <= mem_data;
                        cache_addr[selected_line] <= cpu_addr_reg[ADDR_BIT - 1:ADDR_IGNORED_BITS];
                        cache_line_valid[selected_line] <= 1;
                        cache_line_dirty[selected_line] <= 0;
                        cache_line_counter <= (cache_line_counter + 1) % CACHE_LINES;
                    end
                end
                WAITING_FOR_MEM_WRITE: begin
                    if (mem_ready) begin
                        cache_line_dirty[selected_line] <= 0;
                    end
                end
                IDLE: begin
                    cpu_addr_reg <= addr;
                    selected_line <= empty_line;

                    if (write && addr_match) begin
                        case (data_width)
                            2'b00: cache_data[matched_line][in_line_offset * 8 +: 8] <= cpu_data[7:0];
                            2'b01: cache_data[matched_line][in_line_offset * 8 +: 16] <= cpu_data[15:0];
                            2'b10: cache_data[matched_line][in_line_offset * 8 +: 32] <= cpu_data[31:0];
                            2'b11: cache_data[matched_line][in_line_offset * 8 +: 64] <= cpu_data_64bit;
                            default: begin end
                        endcase
                        cache_line_dirty[matched_line] <= 1;
                    end
                end
                default: begin end
            endcase
            state <= next_state;
        end
    end
endmodule
