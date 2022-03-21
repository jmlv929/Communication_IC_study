

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_crc_p
// Design      : Combinational CRC generator and Checker 

// 

//-------------------------------------------------------------------------------------------------
//
// Description : A Combinational Cyclic Redundancy Check Generator & Checker is Implemented.
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps

module DW_crc_p (crc_ok,crc_out,data_in,crc_in)/* synthesis syn_builtin_du = "weak" */;
	parameter	data_width	=	8;//default 16
	parameter	poly_size	=	32;//default 16
	parameter	crc_cfg		=	1;//default 7,1
	parameter	bit_order	=	1;//default 3,1
	parameter	poly_coef0	=	7607;//(1-65535)default(1021)H ,poly coefficient(0 - 15), 4129
	parameter	poly_coef1 	=	1217;//(0-65535)default Zero ,poly coefficient(16 - 31)
	parameter	poly_coef2	=	0;   //(0-65535)default Zero ,poly coefficient(32-47)
	parameter	poly_coef3 	=	0;   //(0-65535)default Zero ,poly coefficient(48-63)

		
	//input decleration
	input 	[ data_width - 1 : 0 ]	data_in;
	input 	[ poly_size  - 1 : 0 ]	crc_in;
	
	//output decleration
	output 	[ poly_size  - 1 : 0 ]	crc_out;
	output  		   				crc_ok;
	
	//internal decleration
	reg [data_width - 1 : 0]  data_cal;       
	reg [poly_size - 1 : 0]	  crc;           
	reg [poly_size - 1 : 0]	  tmp_crc_out;   
	reg                       crc_bit;    
	reg [63:0]                temp_crc;
	
	wire [data_width - 1 : 0] tmp_data_in;
	wire [data_width - 1 : 0] tmp_crc_in;
	wire [poly_size - 1 : 0]  crc_intial;
	
	integer 				  i; 
	
	/*******************************************************************************************
	  Initial Bit-reordering is done depending upon the parameter BIT_ORDER
	********************************************************************************************/
	
	assign tmp_data_in = bit_ordering_data_in(data_in);
	//assign tmp_crc_in = bit_ordering_crc_in(crc_in);	 
	
	/*******************************************************************************************
	CRC value is pre-setted depending upon the parameter CRC_CFG value being specified 
	either 0 or 1.
	********************************************************************************************/
	
	assign crc_intial = crc_cfg[0] ? {poly_size{1'b1}} : {poly_size{1'b0}};
	
	/*********************************************************************************************
	Generation of CRC codes depending upon the polynomial specified in parameter POLY_COEF(0--3) 
	and the input data line (DATA_IN).
	**********************************************************************************************/

	always	@ ( tmp_data_in or crc_intial )	
		begin
			crc = crc_intial;
			data_cal = tmp_data_in;
			temp_crc = crc;
			// synthesis loop_limit 2000				
			for( i = 0; i < data_width; i = i + 1 )
				begin
					crc_bit = crc[poly_size - 1] ^ data_cal[data_width - 1];
					crc = crc << 1'b1;
					if( crc_bit == 1'b1 )	
						begin  						
							temp_crc = crc;
							temp_crc[63:48] = temp_crc[63:48] ^ poly_coef3;
							temp_crc[47:32] = temp_crc[47:32] ^ poly_coef2; 
							temp_crc[31:16] = temp_crc[31:16] ^ poly_coef1; 
							temp_crc[15:0] = temp_crc[15:0] ^ poly_coef0;
							crc = temp_crc[poly_size - 1:0];

						end	  							
					data_cal = data_cal << 1'b1;	
				end	
		    tmp_crc_out = bit_inversion_crc(crc);	
	    end		
	
	
	/*******************************************************************************************
	The final Generated CRC value is Bit Reorderd again before being given out
	********************************************************************************************/
	
	assign crc_out = bit_ordering_crc_in(tmp_crc_out);
	
	/*******************************************************************************************
		CRC Validation at the reciver end : CRC is calculated using the received data and compared with
	  	the trasmitted CRC(CRC_IN) value, if both are equal then CRC_OK is made HIGH else LOW	
	********************************************************************************************/
	assign crc_ok = crc_in == crc_out;
	
	/******************************************************************************************
	Function for Bit Inversion of the Generated CRC value ,
		Bit Inversion is done depending upon the parameter crc_cfg value .
	*******************************************************************************************/
		
	function [poly_size - 1 : 0 ] bit_inversion_crc;
	input [poly_size - 1 : 0 ] crc_tmp_out; //input Generated CRC value
	
	begin	   
		if ( ( crc_cfg == 0 ) | ( crc_cfg == 1 ) )				
			bit_inversion_crc = crc_tmp_out; //Not Inverted Value
		else if ( ( crc_cfg == 2 ) | ( crc_cfg == 3 ) )				
			bit_inversion_crc = crc_tmp_out ^ {( (poly_size/2) + poly_size%2 ){2'b01}};//0101//Exor'd with 010101 , Even Check Bits
		else if ( ( crc_cfg == 4 ) | ( crc_cfg == 5 ) )				
			bit_inversion_crc = crc_tmp_out ^ {( (poly_size/2) + poly_size%2 ){2'b10}};//1010;//Exor'd with 101010 , Odd  Check Bits
		else if ( ( crc_cfg == 6 ) | ( crc_cfg == 7 ) )				
			bit_inversion_crc = ~ crc_tmp_out;//Inverted Value
	end						
	
	endfunction

	/*******************************************************************************************
	Function for Bit Reordering of CRC_IN value ,
		Bit Reordering is dependent upon the parameter value of BIT_ORDER 
	********************************************************************************************/
		
	function [poly_size - 1 : 0 ] bit_ordering_crc_in;
	input [poly_size - 1 : 0] crc_in; //Input CRC_IN into Module
	integer                   i;
	integer                   j;
	integer                   k;
	
	begin
		bit_ordering_crc_in	= crc_in;	
		if( bit_order == 1 )	
			begin	
				for( i = 0; i < poly_size; i = i + 1 )
					bit_ordering_crc_in[i] = crc_in[poly_size - 1 - i];
			end		
		else if( bit_order == 2 )	
			begin	
				if( ( poly_size % 8 ) == 0 ) //check for multiple of 8
					begin
						k = 1;
						for( i = poly_size - 1; i > 0; i = i - 8 )
							begin	
								for( j = 0; j < 8; j = j + 1 )
									bit_ordering_crc_in[ k*8 - 1 - j ] = crc_in[ i - j ];
									k = k + 1;	
							end		
					end	
			end	
		else if( bit_order == 3 )
			begin	
				if(  ( poly_size % 8 ) == 0 ) //check for multiple of 8
					begin
						for( i = 0; i < poly_size; i = i + 8 )
							begin	
								for( j = 0; j < 8; j = j + 1 )
									bit_ordering_crc_in[ i + j ] = crc_in[ i + 8 - 1 - j ];
							end		
					end	
			end	

	end	
	endfunction
	
	/*******************************************************************************************
	Function for Bit Reordering of DATA_IN value ,
		Bit Reordering is dependent upon the parameter value of BIT_ORDER 
	*******************************************************************************************/
	
	function [data_width - 1 : 0] bit_ordering_data_in;
	input [data_width - 1 : 0] data_in;
	integer                    i;
	integer                    j;
	integer                    k;	 
	
	begin		  
		bit_ordering_data_in = data_in;	
		if( bit_order == 1 )	
			begin	
			// synthesis loop_limit 2000
				for( i = 0; i < data_width; i = i + 1 )
					bit_ordering_data_in[i] = data_in[data_width - 1 - i];
				end	
			else if( bit_order == 2 )	
				begin	
					if( (data_width % 8) == 0 ) //check for multiple of 8
						begin			
							k = 1;
							// synthesis loop_limit 2000
							for( i = data_width - 1; i > 0; i = i - 8 )
								begin	
									for( j = 0; j < 8; j = j + 1 )
										bit_ordering_data_in[ k*8 - 1 - j ] = data_in[ i - j ];
										k = k + 1;	
								end		
						end	
				end
			else if( bit_order == 3 )
				begin	
					if( (data_width % 8) == 0 ) //check for multiple of 8
						begin
						// synthesis loop_limit 2000
							for( i = 0; i < data_width; i = i + 8 )
								begin	
									for( j = 0; j < 8; j = j + 1 )
										bit_ordering_data_in[i + j] = data_in[i + 8 - 1 - j];
								end		
						end	
				end	

	end
	endfunction
	
endmodule
