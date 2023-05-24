module ID_EX_Reg (
        clk,
        reset,
        Flush,
        ID_PC_p4,
        ID_rs_data,
        ID_rt_data,
        ID_Imm,
        ID_Rs,
        ID_Rt,
        ID_Rd,
        ID_BranchOp,
        ID_ALUSrc,
        ID_ALUOp,
        ID_RegDst,
        ID_MemWrite,
        ID_MemRead,
        ID_MemToReg,
        ID_RegWrite,
		//output
        PC_p4, 
        rs_data, 
        rt_data, 
        Imm, 
        Rs, 
        Rt, 
        Rd, 
        ALUOp, 
        ALUSrc, 
        BranchOp, 
        RegDst, 
        MemToReg, 
        MemWrite, 
        MemRead, 
        RegWrite
       );

input clk, reset, Flush;

input [31: 0] ID_PC_p4, ID_rs_data, ID_rt_data, ID_Imm;
input [4: 0] ID_Rs, ID_Rt, ID_Rd;
input [2: 0] ID_ALUOp;
input [2: 0] ID_ALUSrc, ID_BranchOp;
input [1: 0] ID_RegDst, ID_MemToReg;
input ID_MemWrite, ID_MemRead, ID_RegWrite;

output reg [31: 0] PC_p4, rs_data, rt_data, Imm;
output reg [4: 0] Rs, Rt, Rd;
output reg [2: 0] ALUOp;
output reg [2: 0] ALUSrc, BranchOp;
output reg [1: 0] RegDst, MemToReg;
output reg MemWrite, MemRead, RegWrite;

//reset and work, if no flush then send signals to next stage and components
always @(posedge clk)
  begin
    if (reset)
      begin
        PC_p4 <= 32'h0;
        rs_data <= 32'h0;
        rt_data <= 32'h0;
        Imm <= 32'h0;
        Rs <= 5'h0;
        Rt <= 5'h0;
        Rd <= 5'h0;
        ALUOp <= 3'h0;
        BranchOp <= 3'b0;
        ALUSrc <= 3'b0;
        RegDst <= 2'b0;
        MemToReg <= 2'b0;
        MemWrite <= 1'b0;
        MemRead <= 1'b0;
        RegWrite <= 1'b0;
      end
    else
      begin
        PC_p4 <= ID_PC_p4;
        rs_data <= ID_rs_data;
        rt_data <= ID_rt_data;
        Imm <= ID_Imm;
        Rs <= ID_Rs;
        Rt <= ID_Rt;
        Rd <= ID_Rd;
        ALUOp <= ID_ALUOp;
        BranchOp <= ID_BranchOp;
        ALUSrc <= ID_ALUSrc;
        RegDst <= ID_RegDst;
        MemToReg <= ID_MemToReg;
        MemWrite <= Flush ? 1'b0 : ID_MemWrite;
        MemRead <= Flush ? 1'b0 : ID_MemRead;
        RegWrite <= Flush ? 1'b0 : ID_RegWrite;
      end
  end

endmodule