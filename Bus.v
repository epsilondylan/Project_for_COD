module Bus (
        clk,
        reset,
        write_enable,
        enable,
        Address,
        din,
        dout,
	cycles_dout
       );
input clk, reset, enable, write_enable;
input [31: 0] Address, din;
output [31: 0] dout;
output [31: 0] cycles_dout;

wire Data_Mem_en, Data_Mem_wen;
wire [31: 0] Data_Mem_dout;

//if address is valid,then enable.
assign Data_Mem_en = (Address < 32'h40000000) && enable;
assign Data_Mem_wen = (Address < 32'h40000000) && write_enable;

//inside datamem
DataMem data_mem(
          .clk(clk),
          .wen(Data_Mem_wen),
          .Address(Address[10: 2]),
          .din(din),
          .dout(Data_Mem_dout)
        );

//calculate how many cycles
Timer timer(
          .clk(clk),
          .reset(reset),
          .cycles(cycles_dout)
        );

//read 
assign dout =  Data_Mem_en ? Data_Mem_dout : 32'h0;

endmodule
