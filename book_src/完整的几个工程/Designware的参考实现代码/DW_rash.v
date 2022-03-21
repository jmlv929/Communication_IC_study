
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_rash
// Design      : Airthmertic Shifter with Preferred Right Direction

// Date	   : 04-01-07	
//-------------------------------------------------------------------------------------------------
//
// Description : DW_rash is a general-purpose arithmetic shifter similar to DW01_ash, but with preferred right 
// direction for shifting. The input data A is shifted right or left by the number of bits specified by the control input SH.
//
//-------------------------------------------------------------------------------------------------

module DW_rash ( 
                  A,        //Input data
                  DATA_TC,  //Data two's complement control 0 - unsigned, 1 - signed
                  SH,       //Shift control
                  SH_TC,    //Shift two's complement control 0 - unsigned, 1 - signed
                  B         //Output data
                  )/* synthesis syn_builtin_du = "weak" */;

	parameter	A_width = 256; //Word length of A and B
	parameter	SH_width = 8;  //Word length of SH
	
      //input/output declaration
	input	[ A_width - 1 : 0 ]		A;
	input	[ SH_width -1 : 0 ]		SH;
	input						DATA_TC;
	input						SH_TC;
	
	output	[ A_width - 1 : 0 ]	B;	

	//internal decleration
	reg		[ A_width - 1 : 0 ]		A_reg;
	reg		[ SH_width - 1 : 0 ]    sh_2s;					
    wire    [A_width:0]             A_SREG;
	wire    [A_width:0]             bsh;
    
    assign A_SREG = {(DATA_TC & A[A_width - 1]),A};
  
    srash #(A_width, SH_width) US(.a(A_SREG), .sh(SH), .b(bsh));

	// Shifting input A based on input control signals
	always @(*)
		begin
		    A_reg 	=  A;	  
		    sh_2s	= ~SH + 1'b1;
		    if (SH_TC && SH[SH_width - 1]) 
				A_reg = A_reg << sh_2s;
			else 				
                    A_reg  = bsh[A_width - 1 : 0];
            end
				
assign B = A_reg;//output B being assigned

endmodule	
