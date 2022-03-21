

//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_bsh
// Design      : Barrel Shifter

// 
//-------------------------------------------------------------------------------------------------
//
// Description : A parameterized Barrel Shifter is implemented using funnel shifter technique.
//
//-------------------------------------------------------------------------------------------------

module DW01_bsh (A, SH, B)/* synthesis syn_builtin_du = "weak" */;
	parameter A_width	= 8;	//parameter for specifying the input A width
	parameter SH_width = 3;  //parameter for specifying the input SH width
	
	input	[A_width-1:0]	A;
	input	[SH_width-1:0]	SH;
	
	output	[A_width-1:0]	B;
	
	//internal decleration
	reg		[A_width + A_width - 1 : 0]	A_reg;

	wire [(A_width - 1):0] B;

	integer SH2,j;
	
	//Check whether the Shift value(SH) > A_width. If so, successively subtract A_width
	//from SH. 
    always @( SH )
	begin : main
		if (SH > A_width)
			  begin 
				SH2 = SH;
				// synthesis loop_limit 2000  
				for (j = 0;j < SH_width; j = j + 1)
					    if (SH2 > A_width)
						      SH2 = SH2 - A_width;
		   	  end	
		    
		else
		    SH2 = SH;
	end	

	//First concatenate input data and then shift.
	always@(A or SH2)
	begin
	   	A_reg = {A,A}; 
		A_reg = A_reg << SH2;
	end									
	
    //Output assignment : select the top word of concatenated register.
	assign B = A_reg[A_width + A_width - 1 : A_width];
	
endmodule
