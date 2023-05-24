module Timer(clk,reset,cycles);
	input clk,reset;
	output reg [31:0] cycles;
	
	initial begin
		cycles = 32'b0;
	end

	//calculate cycle number and reset
	always @(posedge clk) begin
		if(reset)
			cycles <= 0;
		else
			cycles <= cycles + 1'b1;
	end

endmodule