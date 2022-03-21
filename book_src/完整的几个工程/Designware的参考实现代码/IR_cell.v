
//Implementation of IR cell
module IR_cell ( tck, rst_val, shiftIR, data_in, scan_in, clockIR, updateIR, reset_n, trst_n, flag, data_out, scan_out )/* synthesis syn_builtin_du = "weak" */;
	parameter sync_mode = 1;   
	input   tck;	 
	input   rst_val;
	input   shiftIR;
	input   data_in;
	input   scan_in;
	input   clockIR;
	input   updateIR;
	input   reset_n;
	input   trst_n;	 
	input   flag;
	output  data_out;
	output  scan_out;
	
	//Signal declaration
	reg   q1_a;	 
	reg   q1_s;	 
	reg   data_out_s;
	reg   data_out_a; 
	
	wire tck_n = ~tck;
	
	//Scan output async implementation
	always @( posedge clockIR )
		if ( !shiftIR )
			q1_a <= data_in;
		else
			q1_a <= scan_in;		   
			
	//Scan output sync implementation
	always @( posedge tck )
		if ( shiftIR )
			q1_s <= scan_in;
		else if ( flag )
			q1_s <= data_in;
		else
			q1_s <= q1_s;	
			
	wire rst_instr_n = reset_n & trst_n;
	
	//data output async implementation
	always @( posedge updateIR or negedge rst_instr_n )
		if ( !rst_instr_n )
			data_out_a <= rst_val;
		else
			data_out_a <= q1_a;
	
	//data output sync implementation
	always @( posedge tck_n or negedge rst_instr_n )
		if ( !rst_instr_n )
			data_out_s <= rst_val;
		else if (updateIR)
   			data_out_s <= q1_s; 
			
	assign scan_out = sync_mode ? q1_s : q1_a;	
	assign data_out = sync_mode ? data_out_s : data_out_a;//changed on 16/6	
	
endmodule			
