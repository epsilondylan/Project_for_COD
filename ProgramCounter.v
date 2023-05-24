`timescale  1ns / 1ps

module ProgramCounter (
         clk,
         reset,
         write_enable,
         pc_next,
         pc
       );
input clk, reset, write_enable;
input [31: 0] pc_next;
output reg [31: 0] pc;


always @(posedge clk)
  begin
    if (reset)
      begin
		  pc <= 32'h00400000;
      end
    else
      begin
        if (write_enable)
          pc <= pc_next;
      end
  end

endmodule
