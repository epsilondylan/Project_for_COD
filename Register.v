`timescale 1ns / 1ps

module Register (
        clk,
        reset,
        write_enable,
        read_register_1,
        read_register_2,
        write_register,
        din,
        dout1,
        dout2
       );

input clk, reset, write_enable;
input [4: 0] read_register_1, read_register_2, write_register; 
input [31: 0] din;

//with read_output and test port
output [31: 0] dout1, dout2;

//inside registers
parameter REG_SIZE = 512;
reg [31: 0] registers[0:REG_SIZE-1];

//read
always @(negedge clk)
  begin
    dout1 <= (read_register_1 == 5'b0) ? 32'h0 : registers[read_register_1];
    dout2 <= (read_register_2 == 5'b0) ? 32'h0 : registers[read_register_2];
  end

//assign dout1 = (read_register_1 == 5'b0) ? 32'h0 : registers[read_register_1];
//assign dout2 = (read_register_2 == 5'b0) ? 32'h0 : registers[read_register_2];

//reset and write
integer i;
always @(posedge reset or posedge clk)
  if (reset)
    begin
      for (i = 0; i < 32; i = i + 1)
        registers[i] <= 32'h00000000;
		  registers[28] <= 32'h11111111;//10008000
		  registers[29] <= 32'h22222222;//7fffeffc
    end
  else if (write_enable && (write_register != 5'b00000))
    registers[write_register] <= din;


endmodule