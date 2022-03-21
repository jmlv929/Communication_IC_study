			
//IR register implementation
module IR_reg (tck, shiftIR, clockIR, updateIR, reset_n, trst_n, scan_in, flag, scan_out, data_in, data_out)/* synthesis syn_builtin_du = "weak" */;
	parameter width = 4; 
	parameter sync_mode = 1;  
	parameter id = 0;
	//Input/output declaration 
	input		 		   tck;     
	input        		   shiftIR; 
	input        		   clockIR; 
	input        		   updateIR;
	input        		   reset_n; 
	input        		   trst_n;  
	input        		   scan_in;  
	input        		   flag;  
	output        		   scan_out;
	input [width - 1: 0]   data_in; 
	output [width - 1: 0]  data_out;
	//Signal declarartion
	wire [width - 2:0] int_scan; //MSB gets scan_in, hence one less than width
	wire id_val = id;
	genvar i;
	generate
	for ( i = 0; i < width; i = i + 1 )
		begin:g1
			if (i == 0)	 
			    IR_cell #(sync_mode) u0( .tck(tck), .rst_val(1'b1), .shiftIR(shiftIR), .data_in(data_in[0]), .scan_in(int_scan[i]), .flag(flag),.clockIR(clockIR), .updateIR(updateIR), .reset_n(reset_n), .trst_n(trst_n), .data_out(data_out[i]), .scan_out(scan_out) );
				
	            if ( (i < width-1) && (i > 0))
			    IR_cell #(sync_mode) u1( .tck(tck), .rst_val(~id_val), .shiftIR(shiftIR), .data_in(data_in[i]), .scan_in(int_scan[i]), .flag(flag),.clockIR(clockIR), .updateIR(updateIR), .reset_n(reset_n), .trst_n(trst_n), .data_out(data_out[i]), .scan_out(int_scan[i-1]) );
				
			if ( i == width -1 )
			    IR_cell #(sync_mode) u2( .tck(tck), .rst_val(~id_val), .shiftIR(shiftIR), .data_in(data_in[i]), .scan_in(scan_in), .flag(flag),.clockIR(clockIR), .updateIR(updateIR), .reset_n(reset_n), .trst_n(trst_n), .data_out(data_out[i]), .scan_out(int_scan[i-1]) );
		end
	endgenerate
	
endmodule	
