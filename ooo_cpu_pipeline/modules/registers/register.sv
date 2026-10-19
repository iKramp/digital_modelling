module cpu_register #(parameter BIT = 32) (
    input  logic             clk,
    input  logic             write_enable,
    input  logic             reserve_write,
    input  logic [BIT - 1:0] write_num,
    output logic [BIT - 1:0] read_num,
    output logic             read_valid
);

    reg [BIT - 1:0] value;
    reg             valid;

    //easier names for valid flag
    logic clear_valid;
    logic set_valid;
    assign clear_valid = reserve_write;
    assign set_valid = write_enable;

    assign read_valid = valid || set_valid;
    
    always_comb begin
        if (set_valid) begin //special case, bypass written value
            read_num = write_num;
        end else begin
            read_num = value;
        end
    end

    always @(posedge clk) begin
       valid <= (valid || set_valid) && !clear_valid;
       if (write_enable) begin
           value <= write_num;
       end
    end
endmodule
