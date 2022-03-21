`define LAST_TIME 3_000_000
`define DLY_1 1
module write_enable_signal#(parameter signal_WIDTH=10,
parameter FILENAME="./pat/result.dat" )(
  input clk,
  input enable,
  input signed [signal_WIDTH-1:0] signal_out
);
integer signal_FILE;
reg signal_isNotFirstRise = 0;
reg signal_isSimulationEnd= 0;
reg signed [signal_WIDTH-1:0] tmp_sig_I;

initial begin
#`DLY_1;signal_FILE = $fopen(FILENAME,"wb");
if(signal_FILE ==0) begin
  $display("Error at opening file: %s",FILENAME);
  $stop;
end else
  $display("Loading %s .........",FILENAME);
end

always @(posedge clk) signal_isNotFirstRise <= #`DLY_1 1;
always@(posedge clk)
if(signal_isNotFirstRise) begin
  if(enable)begin
    if ($fwrite(signal_FILE, "%d\n", signal_out)<1)begin
      signal_isSimulationEnd = 1;
      #`LAST_TIME;
      $finish(2);
    end else begin `ifdef DATA_DEBUG
     $display("Data is %d",signal_out);`endif
    end
  end
end
endmodule
