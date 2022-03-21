

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_add_sub_dx
// Design      : DW_addsubdx


//-------------------------------------------------------------------------------------------------
//
// Description : DW_addsub_dx performs addition and subtraction of operands a and b as either:
// A single sum of width bits, or
// Two sums (one of p1_width bits and one of [width.... p1_width] bits).
// The sum or difference passes through a saturation unit and then through an arithmetic
// shifter. The saturation unit and shifter are controlled through the input ports, sat and avg,
// respectively.
// The two's complement select input signal, tc, indicates the processing of unsigned or
// signed values. When tc is LOW, unsigned values are processed; when tc is HIGH, signed
// values are processed.
//
//-------------------------------------------------------------------------------------------------
`timescale 1 ns / 10 ps

module DW_addsub_dx ( sum, co1, co2, a, b, sat, avg, dplx, addsub, ci1, ci2, tc )/* synthesis syn_builtin_du = "weak" */;
					
	parameter	width		=	4;
	parameter	p1_width	=	2;
	
	/////////////////////////////////////////////////////////////
	/*****************internal parameter decleration************/
	parameter	p2_width	=	width	-	p1_width ;
	/////////////////////////////////////////////////////////////
	
	input	[width - 1 : 0]		a;//input data line
	input	[width - 1 : 0]		b;//input data line
	input				   	    sat;//saturation mode (AH)
	input						avg;//average mode    (AH)                      
	input						dplx;//duplex mode    (AH)                      
	input						addsub;//add/sub select line 0->add;1->sub      
	input						tc;//2'scomplement select (AH)                  
	input						ci1;//full | part1 carry input                  
	input						ci2;//part 2 carry input                        
	
	output	[width - 1 : 0]		sum;//output data
	output						co1;//part1 carry out
	output						co2;//full width/part2 carry out 
	
	//Internal signal declaration
	reg							cin1;	
	reg							cin2;	
	wire	[p1_width - 1 : 0]	tp_sum1;
	wire	[p2_width - 1 : 0]	tp_sum2;
	wire						tp_co1;
	wire						tp_co2;
		
	reg		[width - 1 : 0]		sum;
	reg						    co1;
	reg						    co2;
	wire    [p1_width - 1 : 0]	p1_sat_sum;
	wire    [p2_width - 1 : 0]	p2_sat_sum;
	reg		[width - 1 : 0]		sat_sum;
	
	
	//Instantiating two adder/subtractors of width p1 and p2
	DW01_addsub #(p1_width) addsub1 (
	.A(a[p1_width-1:0]),
	.B(b[p1_width-1:0]),
	.CI(cin1),
	.ADD_SUB(addsub),
	.SUM(tp_sum1),
	.CO(tp_co1)
	);

	DW01_addsub #(p2_width) addsub2 (
	.A(a[width-1:p1_width]),
	.B(b[width-1:p1_width]),
	.CI(cin2),
	.ADD_SUB(addsub),
	.SUM(tp_sum2),
	.CO(tp_co2));

	//Only two addsubs of width p1 and p2 are used. when dplx = 1, the ci to p2 becomes the co of p1. 
	always@(dplx or ci1 or ci2 or tp_co1)
		if(dplx)
		begin
			cin1 = ci1;
			cin2 = ci2;
		end	
		else	
		begin
			cin1 = ci1;
			cin2 = tp_co1;
		end	
	
	//Instantiating two saturation detection units of width p1 and p2
	sat #(p2_width) sat2(
	.sat_sum(p2_sat_sum),
	.sat_carry(p2_sat_carry),	 
	.out_10(p2_out_10),
	.out_01(p2_out_01),
	.out_00(p2_out_00),
	.out_11(p2_out_11),
	.carry(tp_co2),
	.a(a[width - 1]),
	.b(b[width - 1]),
	.sum(tp_sum2[p2_width - 1 : 0 ]),
	.sat(sat),
	.tc(tc),
	.addsub(addsub)
	);							  
	
	sat #(p1_width) sat1(  
	.sat_sum(p1_sat_sum),
	.sat_carry(p1_sat_carry),	 
	.out_10(),
	.out_01(),	
	.out_00(),
	.out_11(),
	.carry(tp_co1),
	.a(a[p1_width - 1]),
	.b(b[p1_width - 1]),
	.sum(tp_sum1[p1_width - 1 : 0]),
	.sat(sat),
	.tc(tc),
	.addsub(addsub)
	);							  
	
	//Obtain sat sum
	always @ ( dplx or p2_out_10 or p2_out_01 or p2_out_00 or p2_out_11 or p1_sat_sum or p2_sat_sum or tp_sum2 or tp_sum1)
		if ( dplx )
				sat_sum = { p2_sat_sum, p1_sat_sum };	
		else
			begin
				case ( {p2_out_10,p2_out_01,p2_out_00,p2_out_11} )
					4'b1000: sat_sum = {1'b1, {width - 1{1'b0}}};
					4'b0100: sat_sum = {1'b0, {width - 1{1'b1}}};
					4'b0010: sat_sum = { p2_sat_sum, {p1_width{1'b0}}};
					4'b0001: sat_sum = { p2_sat_sum, {p1_width{1'b1}}};
					default: sat_sum = { tp_sum2, tp_sum1 };
				endcase	
			end	  
				
	//Average sum calculation			
	always @ ( avg or dplx or sat_sum or p2_sat_sum or p1_sat_sum or p2_sat_carry or p1_sat_carry )
		if ( avg )
			if ( dplx )
				sum = {p2_sat_carry, p2_sat_sum[p2_width - 1 : 1], p1_sat_carry, p1_sat_sum[p1_width - 1 : 1]};   
			else
				sum = {p2_sat_carry, sat_sum[width - 1 : 1] };
		else
			sum = sat_sum;
						
			
	//Average carry calculation		
	always @ ( tc or avg or dplx or p2_sat_carry or p1_sat_carry )
		if ( avg )
			begin
				if ( tc )
					begin
						co1 = dplx & p1_sat_carry;
						co2 = p2_sat_carry;
					end
				else
					begin
						co1 = 0;
						co2 = 0;
					end	
			end
		else
			begin 
				co1 = dplx & p1_sat_carry;
				co2 = p2_sat_carry;
			end	
						
	
endmodule
