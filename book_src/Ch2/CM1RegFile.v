01 module CM1RegFile (
02  input         HCLK,
03  input         SYSRESETn,
04 
05  input [3:0]   RegFile1RAddr,
06  input [3:0]   RegFile2RAddr,
07  input          REGFileWE,
08  input [3:0]   REGFileWAddr,
09  input [31:0]  RegFileDataIn,
10  output         InvalidOut1,
11  output [31:0] RegFile1DataOut1,
12  output [31:0] InvalidDataOut1,
13  output          InvalidOut2,
14  output [31:0] RegFile2DataOut2,
15  output [31:0] InvalidDataOut2
16 );
17 (* ramstyle = "MLAB" *) reg [31:0] RegFile1[15:0]/* synthesis keep */;
18 (* ramstyle = "MLAB" *) reg [31:0] RegFile2[15:0]/* synthesis keep */;
19  reg [3:0]     RegFile1RAddr_reg;
20  reg [3:0]     RegFile2RAddr_reg;
21  always @ (posedge HCLK)
22    begin
23      RegFile1RAddr_reg <= RegFile1RAddr;
24      RegFile2RAddr_reg <= RegFile2RAddr;
25    end
26 
27  assign InvalidOut1 = 1'b0;
28  assign InvalidOut2 = 1'b0;
29 
30  assign RegFile1DataOut1 = RegFile1[RegFile1RAddr_reg];
31  assign RegFile2DataOut2 = RegFile2[RegFile2RAddr_reg];
32 
33  assign InvalidDataOut1 = {32{1'bx}};
34  assign InvalidDataOut2 = {32{1'bx}};
35  always @ (posedge HCLK)
36    if (REGFileWE)
37      begin
38        RegFile1[REGFileWAddr] <= RegFileDataIn;
39        RegFile2[REGFileWAddr] <= RegFileDataIn;
40      end
41 endmodule