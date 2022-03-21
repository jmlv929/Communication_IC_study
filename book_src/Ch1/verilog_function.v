Verilog HDL语言中共有以下一些系统函数和任务：
$bitstoreal, $rtoi,$display,$setup,$finish,$skew,$hold,$setuphold,
$itor,$strobe,$period,$time,$printtimescale,$timeformat,$realtime,
$width,$realtobits,$write,$recovery.

1.打开文件 
integer file_id;
file_id = fopen("file_path/file_name");
2.写入文件
//$fmonitor只要有变化就一直记录
$fmonitor(file_id, "%format_char", parameter_list);
$fmonitor(file_id, "%m: %t in1=%d o1=%h", $time, in1, o1);
//$fwrite需要触发条件才记录
$fwrite(file_id, "%format_char", parameter_list);
//$fdisplay需要触发条件才记录
$fdisplay(file_id, "%format_char", parameter_list);
$fstrobe();
3.读取文件
integer file_id;
file_id = $fread("file_path/file_name", "r");
4.关闭文件
$fclose(fjile_id);
5.由文件设定存储器初值
$readmemh("file_name", memory_name"); //初始化数据为十六进制
$readmemb("file_name", memory_name"); //初始化数据为二进制
 
提供了丰富的系统函数，这为Testbench的编写提供了方便。尤其是IEEE1364-2005，其系统级建模的能力更强。
    以前我一般常用到的系统函数只有几个：$readmemb，$readmemh，$display，$fmonitor，$fwrite，$fopen，$fclose等。通常需要对文件作预处理，才能用于Testbench读取。今天又尝试了几个其他的文件输入输出函数，不需要对文件进行预处理，直接使用需要的文件，只对需要的部分进行读取。
    $fseek，文件定位，可以从任意点对文件进行操作；
    $fscanf，对文件一行进行读写。
    下面是一些常见的应用：
    1、读写文件
`timescale 1 ns/1 ns
module FileIO_tb;
integer fp_r, fp_w, cnt;
reg [7:0] reg1, reg2, reg3;
initial begin
  fp_r = $fopen("data_in.txt", "r");
  fp_w = $fopen("data_out.txt", "w");
 
  while(!$feof(fp_r)) begin
    cnt = $fscanf(fp_r, "%d %d %d", reg1, reg2, reg3);
    $display("%d %d %d", reg1, reg2, reg3);
    $fwrite(fp_w, "%d %d %d\n", reg3, reg2, reg1);
  end
 
  $fclose(fp_r);
  $fclose(fp_w);
end
endmodule
    2、
integer file, char;
reg eof;
initial begin
   file = $fopenr("myfile.txt");
   eof = 0;
   while (eof == 0) begin
       char = $fgetc(file);
       eof = $feof (file);
       $display ("%s", char); 
   end
end
    3、文件处理定位
`define SEEK_SET 0
`define SEEK_CUR 1
`define SEEK_END 2
integer file, offset, position, r;
r = $fseek(file, 0, `SEEK_SET);
r = $fseek(file, 0, `SEEK_CUR);
r = $fseek(file, 0, `SEEK_END);
r = $fseek(file, position, `SEEK_SET);
    4、
integer r, file, start, count;
reg [15:0] mem[0:10], r16;
r = $fread(file, mem[0], start, count);
r = $fread(file, r16);
    5、
integer file, position;
position = $ftell(file);
   6、
integer file, r, a, b;
reg [80*8:1] string;
file = $fopenw("output.log");
r = $sformat(string, "Formatted %d %x", a, b);
r = $sprintf(string, "Formatted %d %x", a, b);
r = $fprintf(file, "Formatted %d %x", a, b);
   7、
integer file, r;
file = $fopenw("output.log");
r = $fflush(file);
    8、
// This is a pattern file - read_pattern.pat
// time bin dec hex
10: 001 1 1
20.0: 010 20 020
50.02: 111 5 FFF
62.345: 100 4 DEADBEEF
75.789: XXX 2 ZzZzZzZz
`timescale 1ns / 10 ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000

module read_pattern;
integer file, c, r;
reg [3:0] bin;
reg [31:0] dec, hex;
real real_time;
reg [8*`MAX_LINE_LENGTH:0] line;

initial
  begin : file_block
  $timeformat(-9, 3, "ns", 6);
  $display("time bin decimal hex");
  file = $fopenr("read_pattern.pat");
  if (file == `NULL) // If error opening file
      disable file_block; // Just quit

  c = $fgetc(file);
  while (c != `EOF) begin
    
    if (c == "/")
      r = $fgets(line, `MAX_LINE_LENGTH, file);
    else begin
      // Push the character back to the file then read the next time
      r = $ungetc(c, file);
      r = $fscanf(file," %f:\n", real_time);
      // Wait until the absolute time in the file, then read stimulus
      if($realtime > real_time)
        $display("Error - absolute time in file is out of order - %t",
                real_time);
        else
            #(real_time - $realtime)
                r = $fscanf(file," %b %d %h\n",bin,dec,hex);
        end // if c else
      c = $fgetc(file);
    end // while not EOF

  r = $fcloser(file);
  end // initial

// Display changes to the signals
always @(bin or dec or hex)
    $display("%t %b %d %h", $realtime, bin, dec, hex);

endmodule // read_pattern
    9、自动比较输出结果
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000
module compare;
integer file, r;
reg a, b, expect, clock;
wire out;
reg [`MAX_LINE_LENGTH*8:1];
parameter cycle = 20;

initial begin : file_block
  $display("Time Stim Expect Output");
  clock = 0;

  file = $fopenr("compare.pat");
  if (file == `NULL) disable file_block;

  r = $fgets(line, MAX_LINE_LENGTH, file); // Skip comments
  r = $fgets(line, MAX_LINE_LENGTH, file);

  while (!$feof(file))
    begin
    // Wait until rising clock, read stimulus
    @(posedge clock)
    r = $fscanf(file, " %b %b %b\n", a, b, expect);

    // Wait just before the end of cycle to do compare
    #(cycle - 1)
    $display("%d %b %b %b %b", $stime, a, b, expect, out);
    $strobe_compare(expect, out);
    end // while not EOF

  r = $fcloser(file);
  $stop;
  end // initial

always #(cycle / 2) clock = !clock; // Clock generator
and #4 (out, a, b); // Circuit under test
endmodule // compare

 10、从文件中读数据到mem（这个好像一般人用的最多了）
`define EOF 32'HFFFF_FFFF
`define MEM_SIZE 200_000
module load_mem;
integer file, i;
reg [7:0] mem[0:`MEM_SIZE];
reg [80*8:1] file_name;
initial begin    
  file_name = "data.txt";    
  file = $fopenr(file_name);    
  i = $fread(file, mem[0]);    
  $display("Loaded %0d entries \n", i);    
  i = $fcloser(file);    
  $stop;    
end 
endmodule // load_mem
