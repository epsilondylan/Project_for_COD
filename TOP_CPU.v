module TOP_CPU (
       clk,
       reset,
       WB_result,
       cycles_out,
       out_PC,
       load_use_hazard,
       );

input wire clk, reset;


output [31: 0] out_PC;
output load_use_hazard;
output [31:0] cycles_out;
output [31:0] WB_result;



wire [1: 0] out_id_forward_1; 
wire [1: 0] ex_mem_MemToReg;
wire [2: 0] out_PCSrc;
wire [4: 0] mem_wb_Rd;

wire [31: 0] write_data;
wire [4: 0] Rd;
wire IF_wen, IF_Flush, ID_Flush;

wire [31: 0] id_ex_PC_p4, id_ex_rs_data, id_ex_rt_data, id_ex_Imm;
wire [4: 0] id_ex_Rs, id_ex_Rt, id_ex_Rd;
wire [2: 0] id_ex_ALUOp;
wire [2: 0] id_ex_ALUSrc, id_ex_BranchOp;
wire [1: 0] id_ex_RegDst, id_ex_MemToReg;
wire id_ex_MemWrite, id_ex_MemRead, id_ex_RegWrite;


wire [31: 0] mem_wb_write_data;
wire mem_wb_RegWrite;

wire [31: 0] ex_mem_PC_p4, ex_mem_alu_out, ex_mem_rt_data;
wire [4: 0] ex_mem_Rd;

wire ex_mem_MemWrite, ex_mem_MemRead,ex_mem_RegWrite;

wire ImmSrc;
wire [2: 0] BranchOp;
wire [1: 0] RegDst;
wire [2: 0] ALUSrc;
wire [2: 0] ALUOp;
wire RegWrite;
wire MemWrite;
wire MemRead;
wire jump_hazard;
wire [1: 0] MemToReg;

//IF stage
wire ins_en, ins_wen;
wire [31: 0] branch_target;
wire [31: 0] jump_target;
wire [31: 0] jr_target;
wire branch_hazard;
wire [2: 0] PCSrc;

assign out_PCSrc = PCSrc;

//PC update
wire [31: 0] PC, PC_next, PC_p4, if_id_PC_p4, if_id_Instruction;

assign out_PC = PC;
wire PC_wen;
assign PC_p4 = {PC[31], PC[30: 0] + 31'd4};
assign PC_next =
       branch_hazard ? branch_target :
       (PCSrc == 3'b001) ? jump_target :
       (PCSrc == 3'b010) ? jr_target :PC_p4;

ProgramCounter program_counter(
                 .clk(clk),
                 .reset(reset),
                 .write_enable(PC_wen),
                 .pc_next(PC_next),
                 .pc(PC)
               );

//fetch instruction
wire [31: 0] Instruction;

InstructionMem Icache(
                 .Address(PC[10: 2]),
                 .dout(Instruction)
               );

//IF-ID REG
IF_ID_Reg if_id(
            .clk(clk),
            .reset(reset),
            .write_enable(IF_wen),
            .Flush(IF_Flush),
            .IF_Instruction(Instruction),
            .IF_PC_p4(PC_p4),
	     .IF_ID_PC_p4(if_id_PC_p4),
	     .IF_ID_Instruction(if_id_Instruction)
          );

//ID stage

//control center
Control ctrl(
          .Opcode(if_id_Instruction[31: 26]),
          .Funct(if_id_Instruction[5: 0]),
          .ImmSrc(ImmSrc),
          .load_use_hazard(load_use_hazard),
          .PCSrc(PCSrc),
          .BranchOp(BranchOp),
          .RegDst(RegDst),
          .ALUSrc(ALUSrc),
          .ALUOp(ALUOp),
          .RegWrite(RegWrite),
          .MemWrite(MemWrite),
          .MemRead(MemRead),
          .MemToReg(MemToReg),
          .jump_hazard(jump_hazard)
        );

//Hazard execution
Hazard hazard(
         .reset(reset),
         .PCSrc(PCSrc),
         .branch_hazard(branch_hazard),
         .jump_hazard(jump_hazard),
         .ID_EX_MemRead(id_ex_MemRead),
         .ex_mem_MemRead(ex_mem_MemRead),
         .ID_EX_Rt(id_ex_Rt),
         .IF_ID_Rs(if_id_Instruction[25: 21]),
         .IF_ID_Rt(if_id_Instruction[20: 16]),
         .PC_wen(PC_wen),
         .IF_Flush(IF_Flush),
         .IF_wen(IF_wen),
         .ID_Flush(ID_Flush),
	  .load_use_hazard(load_use_hazard),
	  .out_id_forward_1(out_id_forward_1)
       );

//Register
wire [31: 0] rs_data, rt_data;

Register regs(
           .clk(clk),
           .reset(reset),
           .write_enable(mem_wb_RegWrite),
           .read_register_1(if_id_Instruction[25: 21]),
           .read_register_2(if_id_Instruction[20: 16]),
           .write_register(mem_wb_Rd),
           .din(mem_wb_write_data),
           .dout1(rs_data),
           .dout2(rt_data),
         );

//consider LUI instruction.
wire [31: 0] Imm;
assign Imm = ImmSrc ?
       {16'b0, if_id_Instruction[15 : 0]}//unsign-extension
       : {if_id_Instruction[15 : 0], 16'b0};

// jump
assign jump_target = {if_id_PC_p4[31: 28], if_id_Instruction[25: 0], 2'b00};

//ID Forward
wire [1: 0] id_forward_1;
wire [1: 0] id_forward_2;
ID_Forward ID_Forward_ctrl(
    .EX_MEM_Rd(ex_mem_Rd),
    .MEM_WB_Rd(mem_wb_Rd),
    .EX_MEM_RegWrite(ex_mem_RegWrite),
    .MEM_WB_RegWrite(mem_wb_RegWrite),
    .IF_ID_Rs(if_id_Instruction[25: 21]),
    .IF_ID_Rt(if_id_Instruction[20: 16]),
    .ID_Forward_1(id_forward_1),
    .ID_Forward_2(id_forward_2)
           );
//forward data mux
wire [31: 0] rs_data_forward_id, rt_data_forward_id;
wire [31: 0] alu_out;

assign rs_data_forward_id =
       (id_forward_1 == 2'b00) ? rs_data :
       (id_forward_1 == 2'b01) ? ex_mem_alu_out :
       mem_wb_write_data;//choose from three possible sourses based on the result of ID_FORWARD unit
// assign rt_data_forward_id = id_forward_2 ? mem_wb_write_data : rt_data;
assign rt_data_forward_id =
       (id_forward_2 == 2'b00) ? rt_data :
       (id_forward_2 == 2'b01) ? ex_mem_alu_out :
       mem_wb_write_data;

// jr target
assign jr_target = rs_data_forward_id;
assign out_id_forward_1 = id_forward_1;


//ID-EX REG
ID_EX_Reg id_ex(
    .clk(clk),
    .reset(reset),
    .Flush(ID_Flush),
    .ID_PC_p4(if_id_PC_p4),
    .ID_rs_data(rs_data_forward_id),
    .ID_rt_data(rt_data_forward_id),
    .ID_Imm(Imm),
    .ID_Rs(if_id_Instruction[25: 21]),
    .ID_Rt(if_id_Instruction[20: 16]),
    .ID_Rd(if_id_Instruction[15: 11]),
    .ID_BranchOp(BranchOp),
    .ID_ALUSrc(ALUSrc),
    .ID_ALUOp(ALUOp),
    .ID_RegDst(RegDst),
    .ID_MemWrite(MemWrite),
    .ID_MemRead(MemRead),
    .ID_MemToReg(MemToReg),
    .ID_RegWrite(RegWrite),
    .PC_p4(id_ex_PC_p4), 
    .rs_data(id_ex_rs_data), 
    .rt_data(id_ex_rt_data), 
    .Imm(id_ex_Imm), 
    .Rs(id_ex_Rs), 
    .Rt(id_ex_Rt), 
    .Rd(id_ex_Rd), 
    .ALUOp(id_ex_ALUOp), 
    .ALUSrc(id_ex_ALUSrc), 
    .BranchOp(id_ex_BranchOp), 
    .RegDst(id_ex_RegDst), 
    .MemToReg(id_ex_MemToReg), 
    .MemWrite(id_ex_MemWrite), 
    .MemRead(id_ex_MemRead), 
    .RegWrite(id_ex_RegWrite)
);

//EX stage

//ALU control
wire [4: 0] ALUCtrl;
wire sign;

ALUControl ALU_ctrl(
    .ALUOp(id_ex_ALUOp),
    .Funct(id_ex_Imm[5: 0]),
    .ALUCtrl(ALUCtrl),
    .sign(sign)
);

//EX forward
wire [1: 0] ex_forward_1, ex_forward_2;
EX_Forward EX_Forward_ctrl(
    .EX_MEM_Rd(ex_mem_Rd),
    .MEM_WB_Rd(mem_wb_Rd),
    .EX_MEM_RegWrite(ex_mem_RegWrite),
    .MEM_WB_RegWrite(mem_wb_RegWrite),
    .ID_EX_Rs(id_ex_Rs),
    .ID_EX_Rt(id_ex_Rt),
    .EX_Forward_1(ex_forward_1),
    .EX_Forward_2(ex_forward_2)
           );
//forward data mux
wire [31: 0] rs_data_forward_ex, rt_data_forward_ex;
assign rs_data_forward_ex =
       (ex_forward_1 == 2'b01) ? ex_mem_alu_out :
       (ex_forward_1 == 2'b10) ? mem_wb_write_data :
       id_ex_rs_data;
assign rt_data_forward_ex =
       (ex_forward_2 == 2'b01) ? ex_mem_alu_out :
       (ex_forward_2 == 2'b10) ? mem_wb_write_data :
       id_ex_rt_data;

//ALU operation data mux
wire [31: 0] alu_src1, alu_src2;
assign alu_src1 =
       (id_ex_ALUSrc[1 : 0] == 2'b01) ? id_ex_Imm :
       (id_ex_ALUSrc[1 : 0] == 2'b10) ? 32'h0 :
       rs_data_forward_ex;
assign alu_src2 = id_ex_ALUSrc[2] ? id_ex_Imm : rt_data_forward_ex;

//ALU
wire zero;

ALU alu(
      .input_1(alu_src1),
      .input_2(alu_src2),
      .ALUCtrl(ALUCtrl),
      .sign(sign),
      .zero(zero),
      .result(alu_out)
    );

//Branch
assign branch_target = id_ex_PC_p4 + {id_ex_Imm[29: 0], 2'b00};

Branch branch(
         .input_1(rs_data_forward_ex),
         .input_2(rt_data_forward_ex),
         .BranchOp(id_ex_BranchOp),
         .branch_hazard(branch_hazard)
       );

//RegDst mux
assign Rd =
       (id_ex_RegDst == 2'b01) ? id_ex_Rd :
       (id_ex_RegDst == 2'b10) ? 5'd31 :
       id_ex_Rt;
/*assign RegDst = (load_use_hazard) ? 2'b00 :
       (Opcode == 6'h03 || (Opcode == 6'h00 && Funct == 6'h09)) ? 2'b10 :
       R_ins ? 2'b01 : 2'b00;*/

//EX-MEM REG
EX_MEM_Reg ex_mem(
    .clk(clk),
    .reset(reset),
    .EX_PC_p4(id_ex_PC_p4),
    .EX_alu_out(alu_out),
    .EX_rt_data(rt_data_forward_ex),
    .EX_Rd(Rd),
    .EX_MemWrite(id_ex_MemWrite),
    .EX_MemRead(id_ex_MemRead),
    .EX_MemToReg(id_ex_MemToReg),
    .EX_RegWrite(id_ex_RegWrite),			 
    .PC_p4(ex_mem_PC_p4), 
    .alu_out(ex_mem_alu_out), 
    .rt_data(ex_mem_rt_data), 
    .Rd(ex_mem_Rd), 
    .MemToReg(ex_mem_MemToReg), 
    .MemWrite(ex_mem_MemWrite), 
    .MemRead(ex_mem_MemRead), 
    .RegWrite(ex_mem_RegWrite)
           );

//MEM stage

//BUS
wire [31: 0] mem_out;

Bus bus(
    .clk(clk),
    .reset(reset),
    .enable(ex_mem_MemRead),
    .write_enable(ex_mem_MemWrite),
    .Address(ex_mem_alu_out),
    .din(ex_mem_rt_data),
    .dout(mem_out),
    .cycles_dout(cycles_out)
    );

//Write-back data MUX
assign write_data =
    (ex_mem_MemToReg == 2'b10) ?
    (ex_mem_PC_p4) :
    (ex_mem_MemToReg == 2'b01) ? mem_out :
    ex_mem_alu_out;
		 
assign WB_result = write_data;

//MEM_WB REG
MEM_WB_Reg mem_wb(
    .clk(clk),
    .reset(reset),
    .MEM_write_data(write_data),
    .MEM_Rd(ex_mem_Rd),
    .MEM_RegWrite(ex_mem_RegWrite),
    .MEM_WB_write_data(mem_wb_write_data),
    .MEM_WB_Rd(mem_wb_Rd),
    .MEM_WB_RegWrite(mem_wb_RegWrite)
           );


endmodule