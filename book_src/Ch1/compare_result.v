`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000
module compare_result;
integer file, r;
reg a, b, expect_v, clock;
//reg [`MAX_LINE_LENGTH*8:1];
wire out;
parameter cycle = 20;
always #(cycle / 2) clock = !clock; // Clock generator

initial begin : file_block
  clock = 0;
  file = $fopen("compare.pat");
  if (file == `NULL) disable file_block;

  r = $fgets(line, MAX_LINE_LENGTH, file); // Skip comments
  r = $fgets(line, MAX_LINE_LENGTH, file);

  while (!$feof(file)) begin
    // Wait until rising clock, read stimulus
    @(posedge clock)
    r = $fscanf(file, " %b %b %b\n", a, b, expect_v);
    // Wait just before the end of cycle to do compare
    #(cycle-1)$display("%d %b %b %b %b", $stime, a, b, expect_v, out);
    $strobe_compare(expect_v, out);
  end // while not EOF

  r = $fcloser(file);
  $stop;
end // initial

DUT U_dut(.a(a),.b(b),.out(out)); //被测试的电路
endmodule // compare