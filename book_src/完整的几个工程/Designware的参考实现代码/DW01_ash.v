
//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_ash
// Design      : Airthmertic Shifter

// Company     : 	Software India Pvt. Ltd.
// Date		   : 16-02-05	
//-------------------------------------------------------------------------------------------------
//
// Description : DW01_ash is a general-purpose arithmetic shifter. The input data A is shifted 
// left or right by the number of bits specified by the control input SH.
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps
module DW01_ash ( B, A, DATA_TC, SH, SH_TC )/* synthesis syn_builtin_du = "weak" */;
	parameter	A_width = 16; //parameter specifying the data line width
	parameter	SH_width = 4;  //parameter specifying the shift line width
	
	input	[ A_width - 1 : 0 ]		A;//input A
	input	[ SH_width -1 : 0 ]		SH;//input Shift
	input							DATA_TC;//if 1, then A = 2's complement else normal
	input							SH_TC;//if 1, then Sh = 2's complement else normal
	
	output	[ A_width - 1 : 0 ]		B;//output B
	
    /****************** Internal parameter declaration *******************/
	parameter SEL_width = SH_width;   
	parameter SHIFT = 1 << SH_width;
//	parameter SHIFT_CNT = SHIFT > A_width ? SHIFT : A_width;
	parameter STG1_CNT = SHIFT/4 + ((SHIFT % 4 ) ? 1 : 0);
	parameter STG2_CNT = STG1_CNT/4 + ( STG1_CNT % 4  ? 1 : 0);
	parameter STG3_CNT = STG2_CNT/4 + ( STG2_CNT % 4  ? 1 : 0);
	/*********************************************************************/
	
	//internal decleration
	reg	[ (1'b1 << SH_width) - 1 : 0 ]	mux_in;
	reg	[ A_width - 1 : 0 ]		B;
	integer	i;
	integer	j;
	wire [ SH_width - 1 : 0 ]		SH_2s;//Count for right shift
      assign SH_2s = ~SH + 1;
	//Using MUXs for implementing arithmetic shift - the data bits are properly aligned based on the control inputs
	always @ ( A or DATA_TC or SH or SH_TC or SH_2s )
		if ( SH_width == 1 )
			begin
				if ( SH_TC && SH ) //right shift
					begin
					// synthesis loop_limit 2000  
						for ( i = 1; i < A_width; i = i + 1 )
							B[i-1] = A[i];
						if ( DATA_TC )
							B[A_width - 1] = A[A_width - 1];
						else
							B[A_width - 1] = 1'b0;					
					end
				else //left shift	
					begin
						B[0] = SH ? 1'b0 : A[0];
						// synthesis loop_limit 2000  
						for ( i = 1; i < A_width; i = i + 1 )
							if (SH)
								B[i] = A[i-1];
							else
								B[i] = A[i];
					end			
			end
		else	
		begin  
			if ( SH_TC && SH[SH_width - 1] ) //right shift 
				begin
				// synthesis loop_limit 2000  
					for ( i = 0; i < A_width; i = i + 1 )
						begin
						// synthesis loop_limit 2000  
							for ( j = 0; j < SHIFT; j = j + 1 )
								begin
									if ( (j+i) < A_width ) 
										mux_in[j] = A[j + i];
									else 
										begin
											if ( DATA_TC )
												mux_in[j] = A[A_width - 1];	//Sign-extend
											else
												mux_in[j] = 1'b0; //0-extend
										end
								end	
							B[i] = call_mux(mux_in, SH_2s); 
						end
				end			
			else	//left shift
				begin
				// synthesis loop_limit 2000  
					for ( i = 0; i < A_width; i = i + 1 )
						begin 
							// synthesis loop_limit 2000  
							for ( j = 0; j < SHIFT; j = j + 1 )
								begin		   
									if ( j <= i )
										mux_in[j] = A[i-j];
									else
										mux_in[j] = 1'b0;
								end	
							B[i] = call_mux(mux_in, SH); 
						end //for ( i = 0; i < A_width; j = i + 1 )
				end  //else	 -- left shift
		end  //else
		
		//MUX implementation
		function call_mux;
		input [(1'b1 << SH_width) - 1 :0] A; //A is power of 2 always
		input [SEL_width-1:0] SEL;
		reg [(1'b1 << SH_width) - 1 :0] new_A;
		reg                             MUX;
		integer	                        IN_WIDTH;
		
		begin 
			MUX = 0; 
			IN_WIDTH = (1'b1 << SH_width);
			new_A = A;
			if ( SEL_width % 2 )
				begin	
					if ( IN_WIDTH <= 4 )
						begin
							if ( SEL_width == 1 )
								MUX = SEL ?  new_A[1] : new_A[0];
							else
								MUX = mux4(A,SEL);
						end		
					else if ( IN_WIDTH <= 16 )
						begin: stg1_odd
							reg  temp_1;
							reg [3:0] MUX_1; 
							reg [3:0] temp_A;
							integer i,y;
							// synthesis loop_limit 2000  
							for ( i = 0; i < STG1_CNT; i = i + 1 )				  
								begin  
									// synthesis loop_limit 2000
									for ( y = 0; y < 4; y = y + 1 )
										temp_A[y] = new_A[4*i+y];
									temp_1 = mux4(temp_A,SEL[1:0]);
									MUX_1[i] = temp_1;
								end	
								
								MUX = SEL[2] ? MUX_1[1] : MUX_1[0];
						end
					else if ( IN_WIDTH <= 64 )
						begin: stg2_odd	
							reg  temp_1;
							reg  temp_2;
							reg [15:0] MUX_1;
							reg [3:0] MUX_2;
							reg [3:0] temp_A, temp_B;
							integer i,j;
							integer	y,z;
							// synthesis loop_limit 2000  
							for ( i = 0; i < STG1_CNT; i = i + 1 )
								begin
									// synthesis loop_limit 2000
									for ( y = 0; y < 4; y = y + 1 )
										temp_A[y] = new_A[4*i + y];
									temp_1 = mux4(temp_A,SEL[1:0]);
									MUX_1[i] = temp_1;
								end
								// synthesis loop_limit 2000  
								for ( j = 0; j < STG2_CNT; j = j + 1 )	
									begin
										// synthesis loop_limit 2000
										for ( z = 0; z < 4; z = z + 1 )
											temp_B[z] = MUX_1[4*j+z];
										temp_2 = mux4(temp_B,SEL[3:2]);
										MUX_2[j] = temp_2;
									end
									
								MUX = SEL[4] ? MUX_2[1] : MUX_2[0];
						end
					else if (IN_WIDTH <= 256)
						begin: stg3_odd	 
							reg temp_1;
							reg temp_2;
							reg temp_3;
							reg [63:0] MUX_1;
							reg [15:0] MUX_2;
							reg [3:0] MUX_3; 
							reg [3:0] temp_A, temp_B, temp_C;
							integer i,j,k;
							integer	u,y,z;
							// synthesis loop_limit 2000  
							for ( i = 0; i < STG1_CNT; i = i + 1 )
								begin
									// synthesis loop_limit 2000
									for ( y = 0; y < 4; y = y + 1 )
										temp_A[y] = new_A[4*i + y];
									temp_1 = mux4(temp_A,SEL[1:0]);
										MUX_1[i] = temp_1;
								end
							// synthesis loop_limit 2000  	
							for ( j = 0; j < STG2_CNT; j = j + 1 )	
								begin
									// synthesis loop_limit 2000
									for ( z = 0; z < 4; z = z + 1 )
										temp_B[z] = MUX_1[4*j+z];
									temp_2 = mux4(temp_B,SEL[3:2]);
										MUX_2[j] = temp_2;
								end
							// synthesis loop_limit 2000  
							for ( k = 0; k < STG3_CNT; k = k + 1 )	
								begin
									// synthesis loop_limit 2000
									for ( u = 0; u < 4; u = u + 1 )
										temp_C[u] = MUX_2[4*k+u];
									temp_3 = mux4(temp_C,SEL[5:4]);
										MUX_3[ k] = temp_3;
								end
							MUX = SEL[6] ? MUX_3[1] : MUX_3[0];
					    end
					else	
						begin:all
								MUX = A[SEL]; 
						end
				end
			else
				begin
					if ( IN_WIDTH <= 4 )
						MUX = mux4(A,SEL);
					else if ( IN_WIDTH <= 16 )
						begin: stg_1
							reg       temp_1;
							reg [3:0] MUX_1; 
							reg [3:0] temp_A;
							integer   i,x,y;
							// synthesis loop_limit 2000  
							for ( i = 0; i < STG1_CNT; i = i + 1 )				  
								begin  
									// synthesis loop_limit 2000
									for ( y = 0; y < 4; y = y + 1 )
										temp_A[y] = new_A[4*i + y];
									temp_1 = mux4(temp_A, SEL[1:0]);
									MUX_1[i] = temp_1;
								end		
							MUX = mux4(MUX_1, SEL[3:2]);
						end
					else if ( IN_WIDTH <= 64 )
						begin: stg_2	
							reg temp_1;
							reg temp_2;
							reg [15:0] MUX_1;
							reg [3:0] MUX_2;
							reg [3:0] temp_A, temp_B;
							integer i,j;
							integer	y,z;
							// synthesis loop_limit 2000  
							for ( i = 0; i < STG1_CNT; i = i + 1 )
								begin
									// synthesis loop_limit 2000
									for ( y = 0; y < 4; y = y + 1 )
										temp_A[y] = new_A[4*i + y];
									temp_1 = mux4(temp_A,SEL[1:0]);
									MUX_1[i] = temp_1;
								end
							// synthesis loop_limit 2000  
							for ( j = 0; j < STG2_CNT; j = j + 1 )	
								begin
									// synthesis loop_limit 2000
									for ( z = 0; z < 4; z = z + 1 )
										temp_B[z] = MUX_1[4*j+z];
									temp_2 = mux4(temp_B,SEL[3:2]);
									MUX_2[j] = temp_2;
								end
							MUX = mux4(MUX_2,SEL[5:4]);
						end
					else if (IN_WIDTH <= 256)
						begin: stg_3	 
							reg temp_1;
							reg temp_2;
							reg temp_3;
							reg [63:0] MUX_1;
							reg [15:0] MUX_2;
							reg [3:0] MUX_3; 
							reg [3:0] temp_A, temp_B, temp_C;
							integer i,j,k;
							integer	u,y,z;
              // synthesis loop_limit 2000  
							for ( i = 0; i < STG1_CNT; i = i + 1 )
								begin
									// synthesis loop_limit 2000
									for ( y = 0; y < 4; y = y + 1 )
										temp_A[y] = new_A[4*i + y];
									temp_1 = mux4(temp_A,SEL[1:0]);
									MUX_1[i] = temp_1;
								end
							// synthesis loop_limit 2000  
							for ( j = 0; j < STG2_CNT; j = j + 1 )	
								begin
									// synthesis loop_limit 2000
									for ( z = 0; z < 4; z = z + 1 )
										temp_B[z] = MUX_1[4*j+z];
									temp_2 = mux4(temp_B,SEL[3:2]);
										MUX_2[j] = temp_2;
								end
							// synthesis loop_limit 2000  
							for ( k = 0; k < STG3_CNT; k = k + 1 )	
								begin
									// synthesis loop_limit 2000
									for ( u = 0; u < 4; u = u + 1 )
										temp_C[u] = MUX_2[4*k+u];
									temp_3 = mux4(temp_C,SEL[5:4]);
										MUX_3[k] = temp_3;
								end
							MUX = mux4(MUX_3,SEL[7:6]);					
						end
					else
						begin:all_even
								MUX = A[SEL]; 
						end
				end	
				call_mux = MUX;
		end 
		endfunction
		
		//MUX-4 Implementation
		function  mux4;
		input [3:0]  a;
		input [1:0]  sel;
		
		begin
			case ( sel ) /* synthesis parallel_case */
				2'b00: mux4 = a[0];
				2'b01: mux4 = a[1];
				2'b10: mux4 = a[2];
				2'b11: mux4 = a[3];
				default: mux4 = 'bx;
			endcase
		end	
		endfunction
						
	
endmodule
