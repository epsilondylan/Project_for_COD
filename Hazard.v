module Hazard (
        reset,
        PCSrc,
        branch_hazard,
        jump_hazard,
        ID_EX_MemRead,
        ex_mem_MemRead,
        ID_EX_Rt,
        IF_ID_Rs,
        IF_ID_Rt,
        PC_wen,
        IF_Flush,
        IF_wen,
        ID_Flush,
		load_use_hazard,
		out_id_forward_1
       );

input branch_hazard, jump_hazard, ID_EX_MemRead, reset, ex_mem_MemRead;
input wire [2: 0] PCSrc;
input [4: 0] ID_EX_Rt, IF_ID_Rs, IF_ID_Rt;
input [1:0] out_id_forward_1;

output PC_wen, IF_Flush, IF_wen, ID_Flush;
output load_use_hazard;

//load_use hazard(include jr/jalr)
wire load_use_hazard;
assign load_use_hazard =
       reset ? 1'b0 :
       (ID_EX_MemRead &&
       (ID_EX_Rt == IF_ID_Rs ||
        ID_EX_Rt == IF_ID_Rt))||
	(PCSrc == 3'b010 &&
	out_id_forward_1 == 2'b01 && ex_mem_MemRead);

//as long as load_use hazard, stop writting.
assign PC_wen = ~load_use_hazard;
assign IF_wen = ~load_use_hazard;

//as long as has hazard,flush the pipeline
assign IF_Flush = reset ? 1'b0 : (jump_hazard || branch_hazard) && (PCSrc != 3'b011 && PCSrc != 3'b100);
assign ID_Flush = reset ? 1'b0 : branch_hazard;


endmodule