module Control (
         Opcode,
         Funct,
         ImmSrc,
         PCSrc,
         BranchOp,
         RegDst,
         ALUSrc,
         ALUOp,
         RegWrite,
         MemWrite,
         MemRead,
         MemToReg,
         jump_hazard,
         load_use_hazard
       );

 localparam R_Type 	= 6'h00;
 localparam j		= 6'h02;
 localparam jal	= 6'h03;
 localparam beq	= 6'h04;
 localparam bne	= 6'h05;
 localparam addi 	= 6'h08;
 localparam slti 	= 6'h0A;
 localparam sltiu	= 6'h0B;
 localparam andi	= 6'h0C;
 localparam ori	= 6'h0D;
 localparam xori	= 6'h0E;
 localparam lui	= 6'h0F;
 localparam lw	= 6'h23;
 localparam sw 	= 6'h2B;


input [5:0] Opcode,Funct;
input load_use_hazard;

output [2:0] ALUOp;
output [2:0] PCSrc,ALUSrc,BranchOp;
output [1:0] MemToReg,RegDst;
output ImmSrc,RegWrite,MemWrite,MemRead,jump_hazard;
/* OPCODE  funct  ImmSrc  PCSrc BranchOp RegWrite MemRead MemWrite RegDst ALUOp[2: 0] ALUSrc[2:0] MemToReg jump_hazard */
/*R_Type    0     0       000    000
R_Type      2     0       000    000
R_Type      3     0       000    000
R_Type      8	    0       010    000
R_Type      9	    0       010    000   
j		    0       001    000
jal	           0       001    000
beq	           0       000    100
bne	           0       000    101 
addi 	           0       000    000
andi	           0       000    000
ori	           0       000    000
xori	           0       000    000
lui	           0       000    000
lw	           0       000    000
sw 	           0       000    000                                                                                                             */
//juging if is R-type
wire R_ins;
assign R_ins = (Opcode==R_Type);

//juging if is lui(special)
assign ImmSrc = ~(Opcode==lui);


//juging how to find instruction address
assign PCSrc = (Opcode == j || Opcode == jal) ? 
    3'b001 :
    (Opcode == R_Type && (Funct == 6'h08 || Funct == 6'h09)) ? //jr,jalr
    3'b010 :3'b000;

//juging if is branch_ins and its type
assign BranchOp = (Opcode == beq ||  Opcode == bne ) ?Opcode[2 : 0] :3'h0;

//juging if write sth into reg
assign RegWrite = (load_use_hazard) ? 1'b0 :
    ~(Opcode == sw||( | BranchOp)||
    Opcode == j || (Opcode == R_Type && Funct == 6'h08));

//juging if read or write MEM
assign MemRead = (load_use_hazard) ? 1'b0 : (Opcode == lw) ;
assign MemWrite = (load_use_hazard) ? 1'b0 : (Opcode == sw) ;

//juging destination of register
//Funct = 6'h09 means jalr command
assign RegDst = (load_use_hazard) ? 2'b00 :
       (Opcode == jal || (Opcode == R_Type && Funct == 6'h09)) ? 2'b10 :
       R_ins ? 2'b01 : 2'b00;

//decide ALU's calculation type(and sign)
assign ALUOp[2: 0] =
       (Opcode == R_Type) ? 3'b001 :
       (Opcode == andi) ? 3'b010 :
       (Opcode == ori) ? 3'b011 :
       (Opcode == xori) ? 3'b100 :
       3'b000;


//decide ALU's operation object
assign ALUSrc[1: 0] = (load_use_hazard) ? 2'b0 :
       (R_ins &&
        (Funct == 6'h00 ||
         Funct == 6'h02 ||
         Funct == 6'h03)) ? 2'b01 :
       (Opcode == lui) ? 2'b10 :
       2'b00;

assign ALUSrc[2] = (load_use_hazard) ? 1'b0 : ~R_ins;

//decide Mem's write back object
assign MemToReg = (load_use_hazard) ? 2'b0 : 
       ((Opcode == jal ||
         (Opcode == R_Type &&
          Funct == 6'h09))) ? 2'b10 :
       (Opcode == lw) ? 2'b01 :
       2'b00;

//decide if has j-type jump hazard
assign jump_hazard =
       (Opcode == j) ||
       (Opcode == jal) ||
       (R_ins && (Funct == 6'h8 || Funct == 6'h9));//jr and jalr


endmodule