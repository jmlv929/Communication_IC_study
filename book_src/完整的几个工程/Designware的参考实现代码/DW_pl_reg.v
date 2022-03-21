
////////////////////////////////////////////////////////////////////////////////


module DW_pl_reg (
		clk,
		rst_n,
		enable,
		data_in,
		data_out
  // set_ungroup current_design
  // if ( find("cell", "data_pipe*") ) {
  //   set_transform_for_retiming find( "cell", "data_pipe*" ) multiclass
  // }
  // if ( find("cell", "in_reg*") ) {
  //   set_dont_retime find("cell", "in_reg*" )
  // }
  // if ( find("cell", "out_reg*") ) {
  //   set_dont_retime find("cell", "out_reg*" )
  // }
		);

parameter width = 8;	// NATURAL
parameter in_reg = 0;   // RANGE 0 to 1
parameter stages = 4;	// RNAGE 1 to 1024
parameter out_reg = 0;  // RANGE 0 to 1
parameter rst_mode = 0;	// RANGE 0 to 1

`define en_msb  ((stages-1+in_reg+out_reg < 1)? 0 : (stages+in_reg+out_reg-2))

input			clk;
input			rst_n;
input  [`en_msb : 0]	enable;
input  [width-1 : 0]	data_in;

output [width-1 : 0]	data_out;

reg    [width-1 : 0]	in_reg_a;
reg    [width-1 : 0]	in_reg_s;
wire   [width-1 : 0]	pipe_input_data;
reg    [width-1 : 0]	data_pipe_a [0 : stages-1];
reg    [width-1 : 0]	data_pipe_s [0 : stages-1];
reg    [width-1 : 0]	out_reg_a;
reg    [width-1 : 0]	out_reg_s;


  assign pipe_input_data = (in_reg == 0)? data_in : ( (rst_mode == 0)? in_reg_a : in_reg_s );

  always @ (pipe_input_data) begin : PROC_connect_data_in
    data_pipe_a[0] = pipe_input_data;
    data_pipe_s[0] = pipe_input_data;
  end


  always @ (posedge clk or negedge rst_n) begin : PROC_async_rst_regs
    integer i;

    if (rst_n == 1'b0) begin
      in_reg_a  <= {width{1'b0}};
      for (i=0 ; i < stages-1 ; i=i+1)
        data_pipe_a[i+1] <= {width{1'b0}};
      out_reg_a <= {width{1'b0}};
    end else begin
      if (enable[0] == 1'b1)
	in_reg_a <= data_in;
      for (i=0 ; i < stages-1 ; i=i+1) begin
        if (enable[i+in_reg] == 1'b1)
	  data_pipe_a[i+1] <= data_pipe_a[i];
      end
      if (enable[`en_msb] == 1'b1)
	out_reg_a <= data_pipe_a[stages-1];
    end
  end


  always @ (posedge clk) begin : PROC_sync_rst_regs
    integer i;

    if (rst_n == 1'b0) begin
      in_reg_s  <= {width{1'b0}};
      for (i=0 ; i < stages-1 ; i=i+1)
        data_pipe_s[i+1] <= {width{1'b0}};
      out_reg_s <= {width{1'b0}};
    end else begin
      if (enable[0] == 1'b1)
	in_reg_s <= data_in;
      for (i=0 ; i < stages-1 ; i=i+1) begin
        if (enable[i+in_reg] == 1'b1)
	  data_pipe_s[i+1] <= data_pipe_s[i];
      end
      if (enable[`en_msb] == 1'b1)
	out_reg_s <= data_pipe_s[stages-1];
    end
  end


  assign data_out =	(out_reg != 0)? ((rst_mode == 0)? out_reg_a : out_reg_s) :
			((rst_mode == 0)? data_pipe_a[stages-1] : data_pipe_s[stages-1]);

endmodule
