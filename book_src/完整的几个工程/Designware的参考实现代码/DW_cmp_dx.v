

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_cmp_dx
// Design      : Duplex Comparator

// Company     : 
//-------------------------------------------------------------------------------------------------
// Description : The DW_cmp_dx compares operands a and b as either:
//  A single comparison of width bits (simplex mode [dplx is 0]), or
//  Two comparisons: one of p1_width (least significant) bits and one of
// (width - p1_width) (most significant) bits (duplex mode [dplx is 1]).
//
//-------------------------------------------------------------------------------------------------

module DW_cmp_dx ( a, b, tc, dplx, eq1, lt1, gt1, eq2, lt2, gt2 )/* synthesis syn_builtin_du = "weak" */;
	parameter width = 4;
	parameter p1_width = 2;
	
	//Input/output declaration
	input [width - 1 : 0]        a;               
	input [width - 1 : 0] 	   	 b;               
	input                 	   	 tc;              
	input                 	   	 dplx;            
							   	                  
	output                	   	 eq1;             
	output                	   	 lt1;             
	output                	   	 gt1;             
	output                	   	 eq2;             
	output                	   	 lt2;             
	output                	   	 gt2;             
							     
	//Internal signal declaration
	wire   						 lt_full;       
	wire   						 eq_full;       
	wire   						 lt_part1;      
	wire   						 eq_part1;	  
	wire   						 lt_part2;      
	wire   						 eq_part2;      
	
	

wire LESS_p1 = a[p1_width - 1 : 0] < b[p1_width - 1 : 0];  
wire LESS_p2 =  a[width - 1 : p1_width] < b[width - 1 : p1_width];  


/************P1_Width Comparision*********/	

assign lt_part1 = tc ? 
			( a[p1_width-1] ? ( b[p1_width - 1] ? LESS_p1 : 1'b1 ) : ( b[p1_width - 1] ? 1'b0 : LESS_p1 ) ) : LESS_p1;

assign eq_part1 = (a[p1_width - 1 : 0] == b[p1_width - 1 : 0]) ;

/************P2_Width Comparision*********/	

assign lt_part2 = tc ?
			( a[width - 1] ? ( b[width - 1] ? LESS_p2 : 1'b1 ) : ( b[width - 1] ? 1'b0 : LESS_p2 ) ) : LESS_p2;

assign eq_part2 = (a[width - 1 : p1_width] == b[width - 1 : p1_width]);

/************Full Width Comparision*********/	
wire LESS = ( eq_part2 & LESS_p1 | LESS_p2 );

assign lt_full = tc ? ( a[width-1] ? ( b[width-1] ? LESS : 1'b1 ) : ( b[width-1] ? 1'b0 : LESS ) ) : LESS;

assign eq_full = eq_part1 & eq_part2;			

// Update the output ports based on duplex input

// For Part1 comparision 			 
	
assign eq1 = dplx &  eq_part1;
assign lt1 = dplx &  lt_part1;
assign gt1 = dplx & ~eq1 & ~lt_part1; //dplx ?  ( (eq1) ? 0 : ~lt_part1 ): 0 ; 

// For part2 or full width comparision
	
assign eq2 = dplx ?  eq_part2 : eq_full;
assign lt2 = dplx ?  lt_part2 : lt_full;
assign gt2 = dplx ? (~eq2 & ~lt_part2) : (~eq2 & ~lt_full);

endmodule
