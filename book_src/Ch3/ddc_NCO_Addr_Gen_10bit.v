`timescale 1ns/10ps
module	ddc_NCO_Addr_Gen_10bit(
			resetn,
			Clk_20P48,
			NCO_Addr);

input		resetn;
input   Clk_20P48;
output[11:0] NCO_Addr;
reg[11:0]	NCO_Addr;

parameter	NCO_Addr_Fixed	=	12'd992;			//12M
reg[11:0]	Sum_Reg;

always @ (posedge Clk_20P48)
begin
if(!resetn)
	begin
	Sum_Reg	<=	24'd0;
	NCO_Addr<=	12'd0;
	end
else
	begin
	Sum_Reg	<=	Sum_Reg + NCO_Addr_Fixed;
	NCO_Addr<=	Sum_Reg;
	end
end

endmodule
