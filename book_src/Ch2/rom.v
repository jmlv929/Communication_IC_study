module single_port_rom #(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=8)(
  input [(ADDR_WIDTH-1):0] addr,
  input clk, 
  output reg [(DATA_WIDTH-1):0] q ); //ROMֻ�����������û����������
  reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0]; // ROM���� 
  initial 
    $readmemb("single_port_rom_init.txt", rom);// ROM�е����ݣ��ۺ����Զ�ʶ��
  always @ (posedge clk)
    q <= rom[addr]; // ROM ���
endmodule

defparam <megafunction instance name>.lpm_hint ="ENABLE_RUNTIME_MOD = YES,
INSTANCE_NAME = <instantiation name>";
