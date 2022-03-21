
//-------------------------------------------------------------------------------------------------

module DW_lbsh (
                 A,      //Input data 
                 SH,     //Shift control
                 SH_TC,  //Shift two's complement control, 0 - unsigned, 1 - signed 
                 B       //Shifted data out
                 )/* synthesis syn_builtin_du = "weak" */;
	parameter A_width	= 49;	//Word length of A and B
	parameter SH_width = 6;  //Word length SH
	
      /******** Internal Parameter **********/
      parameter pow_2_SH = 2**SH_width;
      /**************************************/

      //Input/output declaration
	input	[A_width-1:0]	A;
	input	[SH_width-1:0]	SH;
      input                   SH_TC;
	
	output [A_width-1:0]	B;
	
	//Internal decleration
	wire [A_width-1:0]               B;	
	reg  [A_width + A_width - 1 : 0] A_reg;
      reg  [SH_width-1:0]              sh_2s; 
      integer SH2,j;

	//Check whether the Shift value(SH) > A_width. If so, successively subtract A_width
	//from SH. 
      always @( SH or SH_TC )
	begin : main
            sh_2s = ~SH + 1'b1;
		if (SH > A_width)
			  begin 
                        
				SH2 = (SH_TC && SH[SH_width-1]) ? sh_2s : SH;
				
//				for (j = 0;j < SH_width; j = j + 1)
        // synthesis loop_limit 2000              
				for (j = 0;j < pow_2_SH ; j = j + 1)
					    if (SH2 > A_width)
						      SH2 = SH2 - A_width;
		   	  end	
		    
		else
		    SH2 = (SH_TC && SH[SH_width-1]) ? sh_2s : SH;
	end	

      //Check whether A_width == pow(2,SH), then just LSH is sufficient
      always @(A or SH2 or SH or SH_TC)  
      begin
        A_reg = {A,A};
        if ( A_width == pow_2_SH )
           A_reg = A_reg << SH;
        else
        begin
           if (SH_TC && SH[SH_width-1])
             A_reg  = A_reg >> SH2; 
           else              
             A_reg  = A_reg << SH2;     
        end
      end 

	assign B = ( A_width == pow_2_SH ) ? A_reg[A_width + A_width - 1 : A_width] : ((SH_TC && SH[SH_width-1]) ? A_reg[A_width-1:0] : A_reg[A_width + A_width - 1 : A_width]);
	
endmodule
