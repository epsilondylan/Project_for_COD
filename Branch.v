`timescale  1ns / 1ps

module Branch (
         input_1,
         input_2,
         BranchOp,
         branch_hazard
       );

input [31: 0] input_1, input_2;
input [2: 0] BranchOp;
//input [4: 0] flag;
output reg branch_hazard;

//if is branch_ins and branch happened indeed,
//then branch_hazard=1.
always @( * )
  begin
    case (BranchOp)
      3'h4:       // beq
        branch_hazard <= input_1 == input_2;
      3'h7:       // bgtz
        branch_hazard <= ~(input_1[31] || | input_1);
      3'h6:       // blez
        branch_hazard <= input_1[31] || ~| input_1;
      3'h5:       // bne
        branch_hazard <= ~(input_1 == input_2);
      default:
        branch_hazard <= 0;
    endcase
  end

endmodule