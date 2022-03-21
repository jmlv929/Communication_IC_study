  
//--------------------------------------------------------------------------------------------------
//
// Title       : DW03_updn_ctr
// Design      : DW03_updn_ctr

// Company     : 
// Date	       : 08-12-03	
//-------------------------------------------------------------------------------------------------
//
// Description : DW03_updn_ctr is a general-purpose binary up-down counter. The counter is width bits 
// wide and has 2 power width states from "000...000" to "111...111", depending on the specified width.
// The counter is clocked on the positive edge of the clk input.
// 
// The counter is loaded with data by asserting load (LOW) and applying data on the data input.
// The data load operation is synchronous with respect to the positive edge of clk.
//-------------------------------------------------------------------------------------------------
module DW03_updn_ctr (
	data,     //Counter load input 
	up_dn,    //High for count up and low for count down
	load,	  //Enable data load to counter, active low
	cen,      //Count enable, active high
	clk,      //Clock
	reset,	  //Counter reset, active low
	count,	  //Output count bus
	tercnt	  //Terminal count flag
	)/* synthesis syn_builtin_du = "weak" */;
	
	parameter width = 12;
	//Input/output declaration
	input 				  cen;   
	input 				  clk;   
	input 				  reset; 
	input 				  up_dn; 
	input 				  load;  
	input [width - 1:0]   data;
	
	output [width - 1:0]  count;
	output                tercnt;
	
	//Internal signal declaration
	wire [width - 1:0] count;  	
	reg [width - 1:0]  bin_out;	
	reg [width - 1:0]  bin_out_r;	
	reg                tercnt;
    wire [width-1:0]   add_bits;

    //Addend or subtrahend based on up_dn control input 
    assign add_bits = up_dn ? {{width-1{1'b0}},1'b1} : {width{1'b1}};
	
	//Counter - combo block
	always @( load or data or add_bits or bin_out_r or cen )
		if (!load)
			bin_out = data;					
		else if (cen)
			bin_out = bin_out_r + add_bits;
		else
			bin_out = bin_out_r;
		
	//Counter - sequential block
	always @(negedge reset or posedge clk )	
		if (!reset)
			bin_out_r <= 0;
		else
			bin_out_r <= bin_out;
	
	//Terminal count implementation
	always @( bin_out_r or up_dn )
		if (up_dn && (bin_out_r == {width{1'b1}}))
			tercnt = 1'b1; 
		else if (!up_dn && (bin_out_r == 0))
			tercnt = 1;
		else
			tercnt = 0;
	 
	assign count = bin_out_r;
		
endmodule
