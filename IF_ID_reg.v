module IF_ID_Reg (
         clk,
         reset,
         write_enable,
         Flush,
         IF_Instruction,
         IF_PC_p4,
		 IF_ID_Instruction,
         IF_ID_PC_p4
       );
input clk, reset, write_enable, Flush;
input [31: 0] IF_Instruction, IF_PC_p4;
output [31:0] IF_ID_PC_p4, IF_ID_Instruction;

reg [31: 0] Instruction, PC_p4;

assign IF_ID_PC_p4 = PC_p4;
assign IF_ID_Instruction = Instruction;

//if reset:all set to 0
//if worked: if write_enable and no Flush
//then send PC to next.

always @(posedge clk)
  begin
    if (reset)
      begin
        Instruction <= 32'h0;
        PC_p4 <= 32'h0;
      end
    else
      begin
        if (write_enable)
          begin
            Instruction <= Flush ? 32'h0 : IF_Instruction;
            PC_p4 <= IF_PC_p4;
          end
      end
  end
endmodule