module ALU (
         input_1,
         input_2,
         ALUCtrl,
         sign,
         zero,
         result
       );

input [31: 0] input_1, input_2;
input [4: 0] ALUCtrl;
input sign;

output zero;
output reg [31 : 0] result;

assign zero = (result == 0);

wire [1: 0] ss;
assign ss = {input_1[31], input_2[31]};

wire compare_31;
assign compare_31 = (input_1[30: 0] < input_2[30: 0]);

wire compare_signed;
assign compare_signed = (input_1[31] ^ input_2[31]) ? ((ss == 2'b01) ? 1'b0 : 1'b1) : compare_31;
//not taken strategy
always @( * )
  begin
    case (ALUCtrl)
      5'b00000:
        result <= input_1 & input_2;
      5'b00001:
        result <= input_1 | input_2;
      5'b00010:
        result <= input_1 + input_2;
      5'b00110:
        result <= input_1 - input_2;
      5'b00111:
        result <= {31'h00000000,  compare_signed };
      5'b01100:
        result <= ~(input_1 | input_2);
      5'b01101:
        result <= input_1 ^ input_2;
      5'b10000://sll
        result <= (input_2 << input_1[10: 6]);
      5'b10001://srl
        result <= (input_2 >> input_1[10: 6]);
      5'b10010://sra
        result <= ({{32{input_2[31]}}, input_2} >> input_1[10: 6]);
      default:
        result <= 32'h00000000;
    endcase
  end

endmodule