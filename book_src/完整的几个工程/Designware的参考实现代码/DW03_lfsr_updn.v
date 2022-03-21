
//--------------------------------------------------------------------------------------------------
//
// Title       : DW03_lfsr_updn
// Design      : DW03_lfsr_updn
 
// Company     : 
//
//-------------------------------------------------------------------------------------------------
//
// Description : DW03_lfsr_updn is a programmable word-length counter.
// DW03_lfsr_updn implements a counter as an LFSR (linear feedback shift register) which
// also acts as a pseudorandom counter constructed as primitive characteristic polynomials.
//
//-------------------------------------------------------------------------------------------------

module DW03_lfsr_updn(updn, cen, clk, reset, count, tercnt)/* synthesis syn_builtin_du = "weak" */;
parameter width = 15;

//Input/output declaration
input 			   clk;    //System clock             
input 			   reset;  //asynchronous reset active low                   
input 			   cen;    //active low                    
input              updn;   //Input high for count up and low for count down                 
output [width-1:0] count;  //Output count bus 
output             tercnt; //Output terminal count

//Internal signal declaration	 
    reg                     tercnt;
    reg	[width - 1 : 0]	    tap; 
	reg	[width - 1 : 0]     cnt;
	reg	[width - 1 : 0]     cnt_r;
	reg						tmp_msb;
	reg						tmp_lsb;
	reg						msb;
	reg						lsb;
	integer					i;	   
	
	//Get the taps for the specified width
	always@(reset)
	begin	 	
        if(width == 2)
			tap=2'b11;
		else if(width == 3)
			tap=3'b011; 
		else if(width == 4)
			tap=4'b0011;
		else if(width == 5)
			tap=5'b0_0101;  
		else if(width == 6)
			tap=6'b00_0011;
		else if(width == 7)
			tap=7'b000_0011;
		else if(width == 8)
			tap=8'b0110_0011;
		else if(width == 9)
			tap=9'b0_0001_0001;
		else if(width == 10)
			tap=10'b00_0000_1001;
		else if(width == 11)
			tap=11'b000_0000_0101;
		else if(width == 12)
			tap=12'b0000_1001_1001;
		else if(width == 13)
			tap=13'b0_0000_0001_1011;
		else if(width == 14)
			tap=14'b01_1000_0000_0011;	 
		else if(width == 15)
			tap=15'b000_0000_0000_0011;
		else if(width == 16)
			tap=16'b0000_0000_0010_1101;
		else if(width == 17)	
			tap=17'b0_0000_0000_0000_1001;
		else if(width == 18)
			tap=18'b00_0000_0000_1000_0001;
		else if(width == 19)
			tap=19'b000_0000_0000_0110_0011;
		else if(width == 20)
			tap=20'b0000_0000_0000_0000_1001;
		else if(width == 21)
			tap=21'b0_0000_0000_0000_0000_0101;
		else if(width == 22)
			tap=22'b00_0000_0000_0000_0000_0011; 
		else if(width == 23)
			tap=23'b000_0000_0000_0000_0010_0001; 	
		else if(width == 24)
			tap=24'b0000_0000_0000_0000_0001_1011; 	
		else if(width == 25)
			tap=25'b0_0000_0000_0000_0000_0000_1001; 	
		else if(width == 26)
			tap=26'b00_0000_0000_0000_0001_1000_0011; 		
		else if(width == 27)
			tap=27'b000_0000_0000_0000_0001_1000_0011; 		
		else if(width == 28)
			tap=28'b0000_0000_0000_0000_0000_0000_1001; 			
		else if(width == 29)
			tap=29'b0_0000_0000_0000_0000_0000_0000_0101; 				
		else if(width == 30)
			tap=30'b00_0000_0000_0001_1000_0000_0000_0011; 					
		else if(width == 31)
			tap=31'b000_0000_0000_0000_0000_0000_0000_1001; 					
		else if(width == 32)
			tap=32'b0001_1000_0000_0000_0000_0000_0000_0011; 					
		else if(width == 33)
			tap=33'b0_0000_0000_0000_0000_0010_0000_0000_0001; 					
		else if(width == 34)
			tap=34'b00_0000_0000_0000_0000_1100_0000_0000_0011; 					
		else if(width == 35)
			tap=35'b000_0000_0000_0000_0000_0000_0000_0000_0101; 						
		else if(width == 36)
			tap=36'b0000_0000_0000_0000_0000_0000_1000_0000_0001; 							
		else if(width == 37)
			tap=37'b0_0000_0000_0000_0000_0000_0001_0100_0000_0101; 								
		else if(width == 38)
			tap=38'b00_0000_0000_0000_0000_0000_0000_0000_0110_0011; 
		else if(width == 39)
			tap=39'b000_0000_0000_0000_0000_0000_0000_0000_0001_0001; 	
		else if(width == 40)
			tap=40'b0000_0000_0000_0000_0010_1000_0000_0000_0000_0101; 		
		else if(width == 41)
			tap=41'b0_0000_0000_0000_0000_0000_0000_0000_0000_0000_1001; 			
		else if(width == 42)
			tap=42'b00_0000_0000_0000_0000_1100_0000_0000_0000_0000_0011; 			
		else if(width == 43)
			tap=43'b000_0000_0000_0000_0000_0000_0000_0000_0000_0001_1011; 			
		else if(width == 44)
			tap=44'b0000_0000_0000_0000_1100_0000_0000_0000_0000_0000_0011; 
		else if(width == 45)
			tap=45'b0_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_1011; 
		else if(width == 46)
			tap=46'b00_0000_0000_0000_0000_0000_0011_0000_0000_0000_0000_0011; 
		else if(width == 47)
			tap=47'b000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0001; 
		else if(width == 48)
			tap=48'b0000_0000_0000_0000_0000_0000_0011_0000_0000_0000_0000_0011; 
		else if(width == 49)
			tap=49'b0_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0001; 	
		else if(width == 50)
			tap=50'b00_0000_0000_0000_0000_0000_1100_0000_0000_0000_0000_0000_0011; 		
	end	
	
	//Implementing sequential part
	always @( posedge clk or negedge reset)
		if( !reset )
			cnt_r <= 0;
		else
			begin
				if( cen )
					begin
						if ( updn )
							begin
								cnt_r[width-1] <= msb;
			          //synthesis loop_limit 2000  
								for ( i = width-1; i > 0; i = i - 1 )
									cnt_r[i-1] <= cnt_r[i];
							end
						else							  
							begin
								cnt_r[0] <= lsb;
			          //synthesis loop_limit 2000  
								for ( i = 0; i < width - 1; i = i + 1 )
									cnt_r[i+1] <= cnt_r[i];
							end
					end
			end		

	//Implementing combo part
	always @( cnt_r or tap )
		begin	   
			tmp_msb = cnt_r[0];
			//synthesis loop_limit 2000  
			for( i = 1; i < width; i = i + 1 )
				begin
					if( tap[i] )
						tmp_msb = tmp_msb ^ cnt_r[i];
				end
			msb = ~tmp_msb;			
			
			tmp_lsb = cnt_r[width-1];
			//synthesis loop_limit 2000  
			for( i = 1; i < width; i = i + 1 )
				begin
					if( tap[i] )
						tmp_lsb = tmp_lsb ^ cnt_r[i-1];
				end	  
			lsb = ~tmp_lsb;	
		end	

	//Implementation of tercnt
    always@(cnt_r or updn)
		if (( !updn && (cnt_r == {1'b1, {width-1{1'b0}}})) || (updn && (cnt_r == {{width-1{1'b0}},1'b1})))
			tercnt = 1'b1;
		else
			tercnt = 1'b0;

	assign count =  cnt_r;  
	
endmodule
