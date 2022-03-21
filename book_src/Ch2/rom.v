module single_port_rom #(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=8)(
  input [(ADDR_WIDTH-1):0] addr,
  input clk, 
  output reg [(DATA_WIDTH-1):0] q ); //ROM只有数据输出，没有数据输入
  reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0]; // ROM定义 
  initial 
    $readmemb("single_port_rom_init.txt", rom);// ROM中的内容，综合器自动识别
  always @ (posedge clk)
    q <= rom[addr]; // ROM 输出
endmodule

defparam <megafunction instance name>.lpm_hint ="ENABLE_RUNTIME_MOD = YES,
INSTANCE_NAME = <instantiation name>";
