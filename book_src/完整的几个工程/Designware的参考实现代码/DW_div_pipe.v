
//
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------------------------
// Module	: DW_div_pipe
// Author	: Nithin
// Company	:  Inc.
// Date		:
// Version	:
// Description	: This module is a generic pipe lined divider. The logic is divided based on
//		  the number of pipeline stages.
// Fixes	:  1. Functional mismatch when -A(max)/-1
//		   2. Remainder sign extended when tc_mode=1 and b = 0
//		   3. a_reg decl changed from b_width to a_width
//-------------------------------------------------------------------------------------------------
module DW_div_pipe
		#(
		  parameter a_width = 8,
			    b_width = 8,
			    tc_mode = 0,
			    rem_mode = 1,
			    num_stages = 2,
			    stall_mode = 1,
			    rst_mode = 2'b01,
			    op_iso_mode = 0
		  )
		  (
		    input   clk,			//Clock
		    input   rst_n,			//Reset, active low
		    input   en,				//Load enable
		    input   [a_width-1:0] a,		//Dividend
		    input   [b_width-1:0] b,		//Divisor

		    output  [a_width-1:0] quotient,	//Quotient
		    output  [b_width-1:0] remainder,	//Remainder
		    output  divide_by_0			//Indicates if b equals 0
		  );

// Internal parameters
localparam  num_stages_int  = (a_width >= (num_stages-1)) ? num_stages : a_width;
localparam  rem_stages	    = (num_stages - num_stages_int);
localparam  num_adders	    =  a_width/(num_stages_int-1);
localparam  dist_adders     =  a_width%(num_stages_int-1);

wire  [b_width:0]	    sum_r       [num_stages_int-1:0];
wire  [a_width-1:0]	    dividend_r  [num_stages_int-1:0];
wire  [num_stages_int-1:0]  div_by_0_r;

wire  [b_width:0]	    rem_adjust;
wire  [b_width-1:0]	    rem;
wire  [a_width-1:0]	    quot;
wire  [a_width-1:0]	    quot_2s;
wire  [a_width-1:0]	    temp;

wire  [a_width-1:0]	    a_int;
wire  [b_width-1:0]	    b_int [num_stages_int-1:0];
wire  [b_width-1:0]	    b_temp;

wire  [num_stages_int-1:0]  b_max_r;
wire  [num_stages_int-1:0]  a_max_pos_r;
wire  [num_stages_int-1:0]  a_sign_r;
wire  [num_stages_int-1:0]  b_sign_r;

reg   [a_width-1:0]	    quot_int;
reg   [b_width-1:0]	    rem_int;


//wire  [b_width-1:0]         a_reg [num_stages_int-1:0];
wire  [a_width-1:0]         a_reg [num_stages_int-1:0];

wire  [num_stages_int-1:0]  div_0_rst;
wire                        div_0_rst_int;

//Internal signal assignment
assign a_int = tc_mode ? ( a[a_width -1] ? (~a + 1'b1) : a ) : a;
assign b_int[0] = tc_mode ? ( b[b_width -1] ? (~b + 1'b1) : b ) : b;

// Conditions for remainder and quotient
assign b_max_r[0]       = (b == {b_width{1'b1}});
assign a_max_pos_r[0]   = (a == {1'b1,{a_width - 1 {1'b0}}});
assign a_sign_r[0]      = a[a_width-1];
assign b_sign_r[0]      = b[b_width-1];

assign sum_r[0]         = 0;
assign dividend_r[0]    = a_int;
assign div_by_0_r[0]    = ~|b;
assign a_reg[0]         = a;

genvar i;
genvar j;

// ----------------------------------------------------------------
// Distribute the adders based on the dividend width and
// the number of pipeline stages
// ----------------------------------------------------------------
generate
  for(i=0;i<dist_adders;i=i+1)
    begin:u0
    div_int #(
	      .a_width(a_width),
	      .b_width(b_width),
	      .rst_mode(rst_mode),
	      .stall_mode(stall_mode),
	      .num_adders(num_adders+1)
	      )
	    u1(
		.rst_n(rst_n),
		.clk(clk),
		.en(en),

		.dividend(dividend_r[i]),
		.b_int(b_int[i]),
		.sum(sum_r[i]),
		.div_by_0(div_by_0_r[i]),

		.sum_r(sum_r[i+1]),
		.dividend_r(dividend_r[i+1]),
		.div_by_0_r(div_by_0_r[i+1])
	      );
    end
  for(j=dist_adders;j<num_stages_int-1;j=j+1)
    begin:u2
    div_int #(
	      .a_width(a_width),
	      .b_width(b_width),
	      .rst_mode(rst_mode),
	      .stall_mode(stall_mode),
	      .num_adders(num_adders)
	      )
	    u3(
		.rst_n(rst_n),
		.clk(clk),
		.en(en),

		.dividend(dividend_r[j]),
		.b_int(b_int[j]),
		.sum(sum_r[j]),
		.div_by_0(div_by_0_r[j]),

		.sum_r(sum_r[j+1]),
		.dividend_r(dividend_r[j+1]),
		.div_by_0_r(div_by_0_r[j+1])
	      );
    end
endgenerate

assign rem_adjust = sum_r[num_stages_int-1][b_width] ? (sum_r[num_stages_int-1] + b_int[num_stages_int-1]) : sum_r[num_stages_int-1];
assign rem        = rem_adjust[b_width-1:0];
assign quot       = dividend_r[num_stages_int-1];
assign quot_2s    = ~quot + 1;
assign temp       = (a_sign_r[num_stages_int-1] ^ b_sign_r[num_stages_int-1]) ? {1'b1,quot_2s} : {1'b0,quot};

assign div_by_0_int = div_by_0_r[num_stages_int-1];

assign div_0_rst[0] = 0;

genvar k;
generate
  for(k=0;k<num_stages_int-1;k=k+1)
    begin:l
      reg_rst_stall # (
		       .stall_mode(stall_mode),
		       .rst_mode(rst_mode),
		       .data_wid(4)
		      )
	     cr(
		  .rst_n(rst_n),
		  .clk(clk),
		  .din({b_max_r[k],a_max_pos_r[k],a_sign_r[k],b_sign_r[k]}),
		  .en(en),
		  .dout({b_max_r[k+1],a_max_pos_r[k+1],a_sign_r[k+1],b_sign_r[k+1]})
		);

      reg_rst_stall # (
		       .stall_mode(stall_mode),
		       .rst_mode(rst_mode),
		       .data_wid(a_width)
		      )
	     ar(
		  .rst_n(rst_n),
		  .clk(clk),
		  .din(a_reg[k]),
		  .en(en),
		  .dout(a_reg[k+1])
		);

      reg_rst_stall # (
		       .stall_mode(stall_mode),
		       .rst_mode(rst_mode),
		       .data_wid(b_width)
		      )
	     br(
		  .rst_n(rst_n),
		  .clk(clk),
		  .din(b_int[k]),
		  .en(en),
		  .dout(b_int[k+1])
		);

      reg_rst_stall # (
		       .stall_mode(stall_mode),
		       .rst_mode(rst_mode),
		       .data_wid(1),
		       .rst_val(1)
		      )
	   di_r(
		  .rst_n(rst_n),
		  .clk(clk),
		  .din(div_0_rst[k]),
		  .en(en),
		  .dout(div_0_rst[k+1])
		);

    end
endgenerate

assign div_0_rst_int = |div_0_rst;

// Convert the pipelined version of b to original  value if it was
// in two's complement form
assign b_temp = tc_mode ? ( b_sign_r[num_stages_int-1] ? (~b_int[num_stages_int-1] + 1'b1) : b_int[num_stages_int-1] ) : b_int[num_stages_int-1];
//Output assignment
always @ *
  if ( rem_mode == 1 )
    begin
      if(div_by_0_int)
	begin
	  if(tc_mode)
	    rem_int = $signed(a_reg[num_stages_int-1]);
	  else
	    rem_int = a_reg[num_stages_int-1];
	end
      else if (tc_mode == 1 && b_max_r[num_stages_int-1] && a_max_pos_r[num_stages_int-1])
	rem_int = 0;
      else if ((tc_mode == 1) && ( rem != 0 ) && ( a_sign_r[num_stages_int-1] == 1))
	rem_int = ~rem + 1'b1;  //The sign of the result is the sign of A input or B input based on rem_mode
      else
	rem_int = rem;
    end
  else
    begin
      if ( tc_mode )
	begin
	  if(div_by_0_int)
	    rem_int = $signed(a_reg[num_stages_int-1]);
	  else if ( b_max_r[num_stages_int-1] & a_max_pos_r[num_stages_int-1])
	    rem_int = 0;
	  else
	    case ({a_sign_r[num_stages_int-1],b_sign_r[num_stages_int-1]})
	      2'b00: rem_int = rem;
	      2'b01: if ( rem != 0)
		rem_int = b_temp + rem;
	      else
		rem_int = rem;

	      2'b10: if ( rem != 0)
		rem_int = b_temp - rem;
	      else
		rem_int = rem;

	      2'b11: if ( rem != 0)
		rem_int = ~rem + 1'b1;
	      else
		rem_int = rem;
	    endcase
	end
      else
	begin
	  if(div_by_0_int)
	    rem_int = a_reg[num_stages_int-1];
	  else
	    rem_int = rem;
	end
    end

//Output assignment
always @ *
  begin
    if (~div_by_0_int)
    begin
      case ( tc_mode )
	1'b1 : if ( b_max_r[num_stages_int-1] & a_max_pos_r[num_stages_int-1] )
	     //   quot_int = {1'b0, {(a_width - 1) {1'b1}}};
		quot_int = a_reg[num_stages_int-1];
	     else
	      quot_int = temp;

	1'b0 :  quot_int = quot;
      endcase

    end
    else
      begin
	case ( tc_mode )
	  1'b1 : quot_int = a_sign_r[num_stages_int-1] ?  {1'b1,{(a_width - 1){1'b0}}} : {1'b0, { (a_width - 1) {1'b1}}};
	  1'b0 : quot_int = {a_width{1'b1}};
	endcase
      end
  end




generate
  if(rem_stages > 0)
    begin:ppl
      genvar l;

      wire [b_width-1:0]  rem_reg   [rem_stages:0];
      wire  [a_width-1:0] quot_reg  [rem_stages:0];
      wire [rem_stages:0] div_0_reg;

      assign rem_reg[0] = rem_int;
      assign quot_reg[0] = quot_int;
      assign div_0_reg[0] = div_by_0_int;

      for(l=0;l<rem_stages;l=l+1)
	begin:ppl
	reg_rst_stall # (
			 .stall_mode(stall_mode),
			 .rst_mode(rst_mode),
			 .data_wid(a_width+b_width+1)
			)
	     ppl(
		  .rst_n(rst_n),
		  .clk(clk),
		  .din({rem_reg[l],quot_reg[l],div_0_reg[l]}),
		  .en(en),
		  .dout({rem_reg[l+1],quot_reg[l+1],div_0_reg[l+1]})
		);
	end
      assign remainder    = div_0_rst_int ? (tc_mode ? $signed(a) : a) : rem_reg[rem_stages];
      assign quotient     = div_0_rst_int ? (tc_mode ?  (a[a_width - 1] ?  {1'b1,{(a_width - 1){1'b0}}} : {1'b0, { (a_width - 1) {1'b1}}}) : {a_width{1'b1}})  : quot_reg[rem_stages];
      assign divide_by_0  = div_0_rst_int | div_0_reg[rem_stages];
    end
  else
    begin:no_ppl
      assign remainder    = div_0_rst_int ? 'h0 : rem_int;
      assign quotient     = div_0_rst_int ? (tc_mode ?  (a[a_width - 1] ?  {1'b1,{(a_width - 1){1'b0}}} : {1'b0, { (a_width - 1) {1'b1}}}) : {a_width{1'b1}})  : quot_int;
      assign divide_by_0  = div_0_rst_int | div_by_0_int;
    end
endgenerate
endmodule
