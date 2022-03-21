
	//--------------------------------------------------------------------------------------------------
//
// Title       : DW03_lfsr_load
// Design      : DW03_lfsr_load

//-------------------------------------------------------------------------------------------------
//
// Description : DW03_lfsr_load is a parameterized word-length up counter with loadable data input.
// DW03_lfsr_load implements a counter as LFSR (linear feedback shift register) which also acts as 
// a pseudorandom counter constructed as primitive characteristic polynomials.
//
//-------------------------------------------------------------------------------------------------

module DW03_lfsr_load ( data, load, cen, clk, reset, count )/* synthesis syn_builtin_du = "weak" */;
	parameter width =	12;
	
	//Input/output declaration
	input  [width - 1 : 0]	data;//data to be loaded
	input					cen;//active high     
	input					load;//active low     
	input					clk;                  
	input					reset;//active low    
	
	output	[width - 1 : 0]	count;//output data out
	//Internal signal declaration
	reg		[width - 1 : 0]	tap;
	reg		[width - 1 : 0] cnt;
	reg		[width - 1 : 0] cnt_c;
	reg		[width - 1 : 0] cnt_r;
	reg					    tmp;
	integer				    i;
	
	//Selecting the tap based on input width
	always@( reset )
	begin	 	
		if (width == 1)
			tap = 1'b1;	
		else if(width == 2)
			tap = 2'b11;
		else if(width == 3)
			tap = 3'b011; 
		else if(width == 4)
			tap = 4'b0011;
		else if(width == 5)
			tap = 5'b0_0101;  
		else if(width == 6)
			tap = 6'b00_0011;
		else if(width == 7)
			tap = 7'b000_0011;
		else if(width == 8)
			tap = 8'b0110_0011;
		else if(width == 9)
			tap = 9'b0_0001_0001;
		else if(width == 10)
			tap = 10'b00_0000_1001;
		else if(width == 11)
			tap = 11'b000_0000_0101;
		else if(width == 12)
			tap = 12'b0000_1001_1001;
		else if(width == 13)
			tap = 13'b0_0000_0001_1011;
		else if(width == 14)
			tap = 14'b01_1000_0000_0011;	 
		else if(width == 15)
			tap = 15'b000_0000_0000_0011;
		else if(width == 16)
			tap = 16'b0000_0000_0010_1101;
		else if(width == 17)	
			tap = 17'b0_0000_0000_0000_1001;
		else if(width == 18)
			tap = 18'b00_0000_0000_1000_0001;
		else if(width == 19)
			tap = 19'b000_0000_0000_0110_0011;
		else if(width == 20)
			tap = 20'b0000_0000_0000_0000_1001;
		else if(width == 21)
			tap = 21'b0_0000_0000_0000_0000_0101;
		else if(width == 22)
			tap = 22'b00_0000_0000_0000_0000_0011; 
		else if(width == 23)
			tap = 23'b000_0000_0000_0000_0010_0001; 	
		else if(width == 24)
			tap = 24'b0000_0000_0000_0000_0001_1011; 	
		else if(width == 25)
			tap = 25'b0_0000_0000_0000_0000_0000_1001; 	
		else if(width == 26)
			tap = 26'b00_0000_0000_0000_0001_1000_0011; 		
		else if(width == 27)
			tap = 27'b000_0000_0000_0000_0001_1000_0011; 		
		else if(width == 28)
			tap = 28'b0000_0000_0000_0000_0000_0000_1001; 			
		else if(width == 29)
			tap = 29'b0_0000_0000_0000_0000_0000_0000_0101; 				
		else if(width == 30)
			tap = 30'b00_0000_0000_0001_1000_0000_0000_0011; 					
		else if(width == 31)
			tap = 31'b000_0000_0000_0000_0000_0000_0000_1001; 					
		else if(width == 32)
			tap = 32'b0001_1000_0000_0000_0000_0000_0000_0011; 					
		else if(width == 33)
			tap = 33'b0_0000_0000_0000_0000_0010_0000_0000_0001; 					
		else if(width == 34)
			tap = 34'b00_0000_0000_0000_0000_1100_0000_0000_0011; 					
		else if(width == 35)
			tap = 35'b000_0000_0000_0000_0000_0000_0000_0000_0101; 						
		else if(width == 36)
			tap = 36'b0000_0000_0000_0000_0000_0000_1000_0000_0001; 							
		else if(width == 37)
			tap = 37'b0_0000_0000_0000_0000_0000_0001_0100_0000_0101; 								
		else if(width == 38)
			tap = 38'b00_0000_0000_0000_0000_0000_0000_0000_0110_0011; 
		else if(width == 39)
			tap = 39'b000_0000_0000_0000_0000_0000_0000_0000_0001_0001; 	
		else if(width == 40)
			tap = 40'b0000_0000_0000_0000_0010_1000_0000_0000_0000_0101; 		
		else if(width == 41)
			tap = 41'b0_0000_0000_0000_0000_0000_0000_0000_0000_0000_1001; 			
		else if(width == 42)
			tap = 42'b00_0000_0000_0000_0000_1100_0000_0000_0000_0000_0011; 			
		else if(width == 43)
			tap = 43'b000_0000_0000_0000_0000_0000_0000_0000_0000_0001_1011; 			
		else if(width == 44)
			tap = 44'b0000_0000_0000_0000_1100_0000_0000_0000_0000_0000_0011; 
		else if(width == 45)
			tap = 45'b0_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_1011; 
		else if(width == 46)
			tap = 46'b00_0000_0000_0000_0000_0000_0011_0000_0000_0000_0000_0011; 
		else if(width == 47)
			tap = 47'b000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0001; 
		else if(width == 48)
			tap = 48'b0000_0000_0000_0000_0000_0000_0011_0000_0000_0000_0000_0011; 
		else if(width == 49)
			tap = 49'b0_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0001; 	
		else if(width == 50)
			tap = 50'b00_0000_0000_0000_0000_0000_1100_0000_0000_0000_0000_0000_0011; 		
	end	

	//Implementing sequential part
	always @( posedge clk or negedge reset )
		if( !reset )
			cnt_r <= 0;
		else
		begin	
			if( cen )
				cnt_r <= cnt_c;
		end
 
		//Implementing combo block
		always @( cnt_r or load or data or tap )
			begin
				tmp = cnt_r[0];
				// synthesis loop_limit 2000  
					for( i = 1; i < width; i = i + 1 )
					begin
						if( tap[i] )
						begin
							tmp = tmp ^ cnt_r[i];
						end	
					end
					cnt = cnt_r >> 1;
					cnt[width - 1] = ~tmp; 
					
					if(!load ) 
						cnt_c = cnt ^ data;	
					else
						cnt_c = cnt;
			end	 
		
		//Updating the output	
		assign count = cnt_r;	


endmodule
