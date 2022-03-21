			
//TAP FSM implementation
module tap_FSM ( tck, trst_n, tms, tdi, byp_out, tap_state, clockDR, updateDR, clockIR, updateIR, tdo_en, reset_n, shiftDR, shiftIR, selectIR, sync_capture_en, sync_update_dr, flag )/* synthesis syn_builtin_du = "weak" */; 
      parameter sync_mode = 1;
	input    			tck;	     
	input	 			trst_n;	
	input	 			tms;
      input                   tdi;
	output [15:0]           tap_state;
      output                  byp_out;
	output				clockDR, updateDR, clockIR, updateIR, tdo_en, reset_n, shiftDR;
	output				shiftIR, selectIR, sync_capture_en, sync_update_dr, flag;
	
	//Inter signal declaration
	reg [15:0] state;
	reg scan_out_a, scan_out_s, updateIR_a;

	localparam TEST_LOGIC_RESET = 16'h0001, RUN_TEST_IDLE = 16'h0002, SELECT_DR_SCAN = 16'H0004,
	           CAPTURE_DR = 16'h0008, SHIFT_DR = 16'h0010, EXIT1_DR = 16'h0020, PAUSE_DR = 16'h0040,
			   EXIT2_DR = 16'h0080, UPDATE_DR = 16'h0100, SELECT_IR_SCAN = 16'h0200,
			   CAPTURE_IR = 16'h0400, SHIFT_IR = 16'h0800, EXIT1_IR = 16'h1000, 
			   PAUSE_IR = 16'h2000, EXIT2_IR = 16'h4000, UPDATE_IR = 16'h8000;
			   
	assign tap_state = state;		
	wire updateIR_s = state == UPDATE_IR;
	wire updateIR = sync_mode ? updateIR_s : updateIR_a;   
	wire flag = state[10] || state[11];
	//Implementation of FSM
	always @(posedge tck or negedge trst_n)
		if ( !trst_n )
			state <= TEST_LOGIC_RESET;
		else
			begin
				case ( state )
					TEST_LOGIC_RESET: if ( tms )
						                  state <= TEST_LOGIC_RESET;
					                  else
						                  state <= RUN_TEST_IDLE;
					RUN_TEST_IDLE: if ( tms )
						              state <= SELECT_DR_SCAN;
					               else
						              state <= RUN_TEST_IDLE; 
					SELECT_DR_SCAN: if ( tms )
						              state <= SELECT_IR_SCAN;
					                else
									  state <= CAPTURE_DR;  
					CAPTURE_DR: if ( tms )
						              state <= EXIT1_DR;
					            else
									state <= SHIFT_DR; 
					SHIFT_DR: if ( tms )
						            state <= EXIT1_DR;
					          else
								  state <= SHIFT_DR; 	
					EXIT1_DR: if ( tms )
						          state <= UPDATE_DR;
					          else
						          state <= PAUSE_DR; 
					PAUSE_DR: if ( tms )
						          state <= EXIT2_DR;
					          else
							      state <= PAUSE_DR;  
					EXIT2_DR: if ( tms )
						          state <= UPDATE_DR;
					          else
							      state <= SHIFT_DR; 
					UPDATE_DR: if ( tms )
						          state <= SELECT_DR_SCAN;
					          else
								  state <= RUN_TEST_IDLE; 	
	                SELECT_IR_SCAN: if ( tms )
						                state <= TEST_LOGIC_RESET;
					                else
									    state <= CAPTURE_IR;  
					CAPTURE_IR: if ( tms )
						            state <= EXIT1_IR;
					            else
									state <= SHIFT_IR; 
					SHIFT_IR: if ( tms )
						          state <= EXIT1_IR;
					          else
								  state <= SHIFT_IR; 	
					EXIT1_IR: if ( tms )
						           state <= UPDATE_IR;
					          else
						           state <= PAUSE_IR; 
					PAUSE_IR: if ( tms )
						          state <= EXIT2_IR;
					          else
							      state <= PAUSE_IR;  
					EXIT2_IR: if ( tms )
						          state <= UPDATE_IR;
					          else
							      state <= SHIFT_IR; 
					UPDATE_IR: if ( tms )
						          state <= SELECT_DR_SCAN;
					          else
								  state <= RUN_TEST_IDLE; 	
				endcase
			end		 
			
			//FSM outputs	
			reg  clockDR, updateDR, clockIR, tdo_en, rst_n, shiftDR, shiftIR;
			//ClockDR/ClockIR - posedge occurs at the posedge of tck
            //updateDR/updateIR - posedge occurs at the negedge of tck
			always @( tck or state )
				begin
					if ( !tck && ( state == CAPTURE_DR || state == SHIFT_DR ))
						clockDR = 0;
					else
						clockDR = 1;
						
					if ( !tck && ( state == UPDATE_DR ))
						updateDR = 1;
					else
						updateDR = 0;  
						
					if ( !tck && ( state == CAPTURE_IR || state == SHIFT_IR ))
						clockIR = 0;
					else
						clockIR = 1;
						
					if ( !tck && ( state == UPDATE_IR ))
						updateIR_a = 1;
					else
						updateIR_a = 0;												
				end					 
			
                  //Registered outputs	
			always	@( negedge tck )
				begin
					if ( state == SHIFT_IR || state == SHIFT_DR )
						tdo_en <= 1;
					else
						tdo_en <= 0;
						
					if ( state == TEST_LOGIC_RESET )
						rst_n <= 0;
					else
						rst_n <= 1;	
				end		
	        always @(negedge tck or negedge trst_n)
				if ( !trst_n )
					begin 
						shiftDR <= 0;
						shiftIR <= 0;
					end
				else
					begin
						if ( state == SHIFT_DR )	
							shiftDR <= 1;
						else
							shiftDR <= 0;  
						
					    if ( state == SHIFT_IR )	
							shiftIR <= 1;
						else
							shiftIR <= 0;
				    end		

	wire    reset_n = rst_n & trst_n;	
	wire	selectIR = state == SHIFT_IR;//( state == TEST_LOGIC_RESET | state == RUN_TEST_IDLE	| state == CAPTURE_IR | state == SHIFT_IR | state == EXIT1_IR | state == PAUSE_IR |	state == EXIT2_IR | state == UPDATE_IR );
	wire    sync_capture_en = ~(shiftDR | (state == CAPTURE_DR) | (state == SHIFT_DR));
 	wire    sync_update_dr = state == UPDATE_DR;
    reg sel; 
      //Implementation of Bypass register
      //Async impl   
      always @( posedge clockDR )
	   scan_out_a <= shiftDR & tdi & ~(state == CAPTURE_DR);  

      //Sync impl
      wire nxt_st_3 = (state == SELECT_DR_SCAN) & ~tms;
      wire nxt_st_4 = ((state == CAPTURE_DR) & ~tms) || ( state == SHIFT_DR & ~tms);
     
      always @(posedge tck or negedge trst_n)
	   if ( !trst_n )
		    sel <= 0;
         else
            sel <= ~(nxt_st_3 | nxt_st_4);
 
      wire scan_out = sel ? scan_out_s : shiftDR & tdi;
      
   
     	always @(posedge tck )
	   scan_out_s <= scan_out & ~(state == CAPTURE_DR);

	wire byp_out = sync_mode ? scan_out_s : scan_out_a;

endmodule
