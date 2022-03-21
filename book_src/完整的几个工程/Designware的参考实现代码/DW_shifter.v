

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_shifter
// Design      : Shifter

// Company     : 
// Date	       : 16-02-05	
//-------------------------------------------------------------------------------------------------
//
// Description : Combined Airthmetic & Barrel Shifter is implemented.
//				 if sh_mode 	== 0 then Barrel shifter is implemented.
//				 else sh_mode	== 1 then Airtmetic shifter is implemented.
//
//-------------------------------------------------------------------------------------------------
`timescale 1 ns / 10 ps
module DW_shifter ( data_out, data_in, data_tc, sh, sh_tc, sh_mode)/* synthesis syn_builtin_du = "weak" */;
	parameter	data_width	=	17;//parameter specifying the input data line width
	parameter	sh_width	=	4;//parameter specifying the shift line width
	parameter	inv_mode	=	0; //0->normal  0--padding,1->normal 1--padding ,2->inverted 0--padding ,3->inverted 1--padding
	
    /****************** Internal parameter declaration *******************/	 
	parameter SH_width = sh_width;	  
	parameter A_width = data_width;
	parameter SHIFT = 1 << SH_width;
//	parameter SHIFT_CNT = SHIFT > A_width ? SHIFT : A_width;
	parameter SEL_width = SH_width; 
	parameter STG1_CNT = SHIFT/4 + ((SHIFT % 4 ) ? 1 : 0);
	parameter STG2_CNT = STG1_CNT/4 + ( STG1_CNT % 4  ? 1 : 0);
	parameter STG3_CNT = STG2_CNT/4 + ( STG2_CNT % 4  ? 1 : 0);
	/*********************************************************************/
	//Input/output port declaration	
	input		[data_width - 1 : 0]	data_in; //input data line
	input		[sh_width - 1 : 0]		sh;//input shift line
	input							    data_tc;//0->unsigned ,1->signed
	input							    sh_tc;//  0->unsigned ,1->signed
	input							    sh_mode;//0->barrel shift 1->arithmetic shift
	
	output		[data_width - 1 : 0]	data_out;//output data line	 
	
	//internal signal decleration	
	reg	                				pad;
	reg	[data_width - 1 : 0]	        data_out;
	reg									t_data_tc,t_sh_tc;
	reg	[sh_width-1:0]					t_sh;
	
	//mode selection depending upon parameter inv_mode
	always@( sh or data_tc or sh_tc )
	begin
		if( inv_mode == 0 )					 
		begin	
			t_sh		=	sh;
			t_data_tc	=	data_tc;
			t_sh_tc		=	sh_tc;
			pad			=	1'b0;
		end								 
		else if( inv_mode == 1 )					 
		begin	
			t_sh		=	sh;
			t_data_tc	=	data_tc;
			t_sh_tc		=	sh_tc;
			pad			=	{data_width{1'b1}};
		end								 	   
		else if( inv_mode == 2 )					 
		begin	
			t_sh		=	~sh;
			t_data_tc	=	~data_tc;
			t_sh_tc		=	~sh_tc;
			pad			=	{data_width{1'b0}};
		end								 	   
		else if( inv_mode == 3 )					 
		begin	
			t_sh		=	~sh;
			t_data_tc	=	~data_tc;
			t_sh_tc		=	~sh_tc;
			pad			=	{data_width{1'b1}};
		end								 	   
	end										
		
	//module for barrel and airthmatic shifter  block -- only right shift/rotation operator used
	//Left shift/rotation is acheived by shifting right/rotating the data by data_width - shift left count	
	always @ ( t_sh or t_sh_tc or pad or sh_mode or data_in or t_data_tc )
		if ( sh_mode )
			data_out = ash(data_in, t_sh_tc, t_sh, t_data_tc, pad);
		else
			data_out = bsh(data_in, t_sh, t_sh_tc);
//Function definition
	//Using MUXs for implementing arithmetic shift - the data bits are properly aligned based on the control inputs
		function [data_width - 1:0] ash;
		input [data_width - 1:0] A;
		input SH_TC;
		input [SH_width -1 : 0 ] SH;
		input DATA_TC; 
		input pad;
		
	    reg	[ (1'b1 << SH_width) - 1 : 0 ]	mux_in;
	    reg	[data_width - 1 : 0] B;
    	integer	i;
	    integer	j;
	    reg [SH_width -1 : 0 ] SH_2s; //Only for Right shifts
		begin
        SH_2s = ~SH + 1;
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
							B[A_width - 1] = pad;					
					end
				else //left shift	
					begin
						//B[0] = SH ? 1'b0 : A[0];
						B[0] = SH ? pad : A[0];
						// synthesis loop_limit 2000  
						for ( i = 1; i < A_width; i = i + 1 )
							if ( SH )
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
												mux_in[j] = pad; //0 or 1 based on mode										
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
										mux_in[j] = pad;
								end	
							B[i] = call_mux(mux_in, SH); 
						end //for ( i = 0; i < A_width; j = i + 1 )
				end  //else	 -- left shift
		end  //else	
		ash = B;
	end	
	endfunction	
	//Barrel shifter
	function [data_width - 1:0] bsh;
    input [data_width - 1:0] A;
	input [SH_width-1:0]     SH;
	input                    SH_TC;
	
	reg [A_width - 1:0]     B;
	reg	[ (1'b1 << SH_width) - 1 : 0 ]	mux_in;
	integer i,j;
	reg [SH_width-1:0]    SH_2s;//Only for Right Shifts
	
	//The data inputs to the MUX are properly aligned.
	begin  
	    SH_2s = ~SH + 1;
		if ( SH_width == 1 )
			begin
				if ( SH_TC && SH ) //right shift 
					begin 
					// synthesis loop_limit 2000  
						for ( i = 0; i < A_width - 1; i = i + 1 )
							if ( SH )
								B[i] = A[i+1];
							else
								B[i] = A[i];
						B[A_width - 1] = SH ?  A[0] : A[A_width - 1];	
					end
				else //left shift
					begin
					// synthesis loop_limit 2000  
						for ( i = 1; i < A_width; i = i + 1 )
							if ( SH )
								B[i] = A[i-1];
							else
								B[i] = A[i];
						B[0] = SH ? A[A_width - 1] : A[0];	
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
									mux_in[j] = A[(j + i)%A_width];
								B[i] = call_mux(mux_in, SH_2s);
							end				   
					end
				else //left shift
					begin
					// synthesis loop_limit 2000  
						for ( i = 0; i < A_width; i = i + 1 )
							begin	
						    // synthesis loop_limit 2000  
								for ( j = 0; j < SHIFT; j = j + 1 )
									mux_in[j] = A[(A_width+i-(j%A_width))%A_width];
								B[i] = call_mux(mux_in, SH);
							end
					end		
		    end
		bsh = B;	
	end	
	endfunction			   
	
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
