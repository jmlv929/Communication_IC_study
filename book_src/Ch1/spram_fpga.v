module spram #(parameter ADDR_WIDTH=6 ,DATA_WIDTH=8)(
    input [(DATA_WIDTH-1):0] data,
    input [(ADDR_WIDTH-1):0] addr,
    input we, clk,
    output [(DATA_WIDTH-1):0] q
);
reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
reg [ADDR_WIDTH-1:0] addr_reg;

always @ (posedge clk)begin
  if (we)
      ram[addr] <= data;
  addr_reg <= addr;
end
assign q = ram[addr_reg]; // RAM�����������ӦFPGA RAM�첽���

`ifdef BLANK_RAM // ��RAM��ʼ��Ϊȫ0��Altera ֧����������
integer i;
initial begin
    for(i=0;i<2**ADDR_WIDTH;i=i+1) ram[i]=0;
end
`endif
 endmodule
