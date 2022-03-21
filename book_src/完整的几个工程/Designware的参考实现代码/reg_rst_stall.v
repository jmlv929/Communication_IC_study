


//------------------------------------------------------------
// Register based on configuration
// -----------------------------------------------------------
module reg_rst_stall # (
			parameter   stall_mode = 0,
			            rst_mode   = 0,
			            data_wid   = 32,
			            rst_val    = 0
		       )
		       (
			input                       rst_n,
			input                       clk,
			input   [data_wid-1:0]      din,
			input                       en,
			output  reg [data_wid-1:0]  dout
		       );


  wire		en_int;

generate if (stall_mode == 1)
    assign en_int = en;
  else
    assign en_int = 1'b1;
endgenerate


generate
  case(rst_mode)
    1: begin:ar
      always @ (posedge clk or negedge rst_n)
	begin
	  if(~rst_n)
	    dout <= rst_val;
	  else if (en_int)
	    dout <= din;
	end
    end

    2: begin:sr
      always @ (posedge clk)
	begin
	  if(~rst_n)
	    dout <= rst_val;
	  else if (en_int)
	    dout <= din;
	end
    end

    default: begin:nr		// use default for rst_mode = 0
      always @ (posedge clk)
	begin
	  if(en_int)
	    dout <= din;
	end
    end
  endcase
endgenerate

endmodule
