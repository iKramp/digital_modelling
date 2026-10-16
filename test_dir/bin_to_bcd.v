//=====================================================================================
//			Bin to BCD Converter Module
//
//			Parameters:
//				INPUT_WIDTH - input (binary) data width
//				OUTPUT_WIDTH - output (BCD) data width
//
//			Control Signals:
//				clk - clock signal
//				rst_n – reset (Active-Low)
//				in_valid - signal to start calculating the BCD
//
//			Data:
//				bin_in - input (binary) data
//				bcd_out - output (BCD) data
//				out_valid - BCD out_valid signal				
//=====================================================================================

module bin_to_bcd
#(
	parameter INPUT_WIDTH = 16,
	parameter OUTPUT_WIDTH = ((INPUT_WIDTH * 302) / 1000 + 1) * 4 // OUTPUT_WIDTH = floor(INPUT_WIDTH * log10(2)) + 1
)
(
	input clk, // Clock
	input rst_n, // Reset
	input in_valid, // in_valid calculating the BCD
	input [INPUT_WIDTH - 1:0] bin_in, // Input (binary) data
	output reg [OUTPUT_WIDTH - 1:0] bcd_out, // Output (BCD) data
	output reg out_valid // BCD out_valid
);

localparam IDLE = 0; // Idle State
localparam ADD = 1; // Add State
localparam SHIFT = 2; // Shift State
localparam DONE = 3; // Done State

localparam SHIFT_CNT_WIDTH = $clog2(INPUT_WIDTH); // Shift counter width

reg [1:0] cstate, nstate; // Current and Next FSM States
reg [INPUT_WIDTH - 1:0] bin_reg; // Binary data register
reg [OUTPUT_WIDTH - 1:0] bcd_reg; // BCD data register
reg [SHIFT_CNT_WIDTH - 1:0] shift_counter; // Shift Counter
integer i;

//=====================================================================================
// FSM, transition to the next state
//=====================================================================================
always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cstate <= IDLE;
	end
	else begin
		cstate <= nstate;
	end
end	

//=====================================================================================
// FSM transition logic
//=====================================================================================
always @ (*) begin
	nstate = cstate;
	case (cstate)
		IDLE : nstate = in_valid ? ADD : IDLE;
		ADD : nstate = SHIFT;
		SHIFT : nstate = (shift_counter == INPUT_WIDTH - 1) ? DONE : ADD;
		DONE : nstate = IDLE;
		default : nstate = IDLE;
	endcase
end

//=====================================================================================
// FSM
//=====================================================================================
always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		bin_reg <= 0;
		bcd_reg <= 0;
		shift_counter <= 0;
		bcd_out <= 0;
		out_valid <= 1'b0;
	end
	else begin
		case (cstate)
//-------------------------------------------------------------------------------------
			IDLE : begin
				if (in_valid) begin
					bin_reg <= bin_in;
					bcd_reg <= 0;
					shift_counter <= 0;
				end
				bcd_out <= bcd_out;
				out_valid <= 1'b0;
			end
//-------------------------------------------------------------------------------------
			ADD : begin
				bin_reg <= bin_reg;
				for (i = 0; i < OUTPUT_WIDTH / 4; i = i + 1) begin
					if (bcd_reg[i * 4 +: 4] >= 5) begin
						bcd_reg[i * 4 +: 4] <= bcd_reg[i * 4 +: 4] + 3;
					end
				end
				shift_counter <= shift_counter;
				bcd_out <= bcd_out;
				out_valid <= out_valid;
			end
//-------------------------------------------------------------------------------------
			SHIFT : begin
				{bcd_reg, bin_reg} <= {bcd_reg, bin_reg} << 1;
				shift_counter <= shift_counter + 1;
				bcd_out <= bcd_out;
				out_valid <= out_valid;
			end
//-------------------------------------------------------------------------------------
			DONE : begin
				bin_reg <= 0;
				bcd_reg <= 0;
				shift_counter <= 0;
				bcd_out <= bcd_reg;
				out_valid <= 1'b1;
			end
//-------------------------------------------------------------------------------------
			default : begin
				if (in_valid) begin
					bin_reg <= bin_in;
					bcd_reg <= 0;
					shift_counter <= 0;
				end
				bcd_out <= bcd_out;
				out_valid <= 1'b0;
			end
		endcase
	end
end

endmodule
