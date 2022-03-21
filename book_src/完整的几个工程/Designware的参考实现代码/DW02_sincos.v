
//--------------------------------------------------------------------------------------------------
//
// Title       : DW02_sincos.v
// Design      : Trigonometric Functions
//
//-------------------------------------------------------------------------------------------------
//
// Description :  DW02_sincos is a combinational cosine. This component takes the input sine or cosine 
// function of pi times the input angle A.
// 
// If the control signal SIN_COS is LOW, DW02_sincos calculates sin(pi x A). If the control signal 
// SIN_COS is HIGH, DW02_sincos calculates cos(pi x A).
//-------------------------------------------------------------------------------------------------

module DW02_sincos ( 
	A, //Angle in Binary 
	SIN_COS, //Sine (SIN_COS=0) or cosine(SIN_COS=1)
	WAVE //Sine or Cosine value of A
	)/* synthesis syn_builtin_du = "weak" */;

parameter A_width = 16;
parameter wave_width = 32;

//Input/output declaration
input [A_width - 1 : 0]      A; 
input                        SIN_COS;

output [wave_width - 1 : 0] WAVE;

//Internal signal declaration
wire [wave_width - 1:0]   WAVE;
wire [1:0]                msb_2s;
reg  [A_width - 1 : 0]    new_A;

assign msb_2s = A[A_width-1:A_width-2] - 1;

always @ ( A or SIN_COS or msb_2s )
	if ( SIN_COS )
		new_A = A; //Cosine of pi x A
	else
		new_A = {msb_2s, A[A_width-3:0]};//Sine of pi x A


DW02_cos #(A_width, wave_width) rtl( 
	          .A(new_A),   
	          .COS(WAVE)  
			 );	  
			 
endmodule			 
