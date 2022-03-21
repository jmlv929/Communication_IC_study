

//-------------------------------------------------------------------------------------------------
//
// Title       : DW_tap
// Design      : Boundary Scan Cell Type BC_10
//
//							 Enhancements : 1. Added a dummy test port to be in accordance
//																 with the updated version of Synopsys
//-------------------------------------------------------------------------------------------------
// Description : DW_tap provides access to on-chip boundary scan logic. DW_tap contains the IEEE 
// standard 1149.1 TAP finite state machine, instruction register, bypass register, and the optional 
// device identification register.
//
// Control of DW_tap is through the pins tck, tms, tdi, tdo, and trst_n. tck, tms, and trst_n control 
// the states of the boundary scan test logic. tdi and tdo provide serial access to the instruction 
// and data registers.
//-------------------------------------------------------------------------------------------------		

`timescale 1ps / 1ps
module DW_tap (	tck, trst_n, tms, tdi, so, bypass_sel, sentinel_val, clock_dr, shift_dr, update_dr, tdo, tdo_en, tap_state, extest, samp_load, instructions, sync_capture_en, sync_update_dr,test )/* synthesis syn_builtin_du = "weak" */;
	parameter width = 2;  
	parameter id = 0;  
	parameter version = 0;  
	parameter part = 0;  
	parameter man_num = 0;  
	parameter sync_mode = 0; 
	//Input/output declaration
	input				 tck;
	input				 trst_n;
	input				 tms;
	input				 tdi;
	input				 so; 
	input                bypass_sel;
	input				 test;
	input  [width-2:0]   sentinel_val;
	output               clock_dr;
	output               shift_dr;	
	output               update_dr;
	output			   	 tdo;
	output               tdo_en;
	output [15:0]        tap_state;
	output               extest;
	output               samp_load;
	output [width-1:0]   instructions;
    output               sync_capture_en;
    output               sync_update_dr;

	//Signal declaration
	wire        reset_n, selectIR, tdo_en, shiftIR, clockIR, updateIR,  selectBR;
	wire         IR_SO, BR_SO, TDR_SO, TDO_data;
 	wire [15:0] tap_state;
	reg         TDO_reg;
	wire [width-1:0]  instructions;
      reg [31:0] idcode_rs, idcode_ra;

      reg so_out;
	assign TDR_SO = (selectBR | bypass_sel)? BR_SO : so_out;
	assign TDO_data = selectIR ? IR_SO : TDR_SO;
//	wire [width-1:0] IR_PI = width > 2 ?  {sentinel_val[width-3:0],2'b01} : 2'b01;
	wire [width-1:0] IR_PI = width > 2 ?  {sentinel_val[((width==2 ? width+1 : width)-3):0],2'b01} : 2'b01; // Modified by Nithin (work around for VCS) 

	integer i;

	tap_FSM #(sync_mode) u1( .tck(tck), .trst_n(trst_n), .tms(tms), .tdi(tdi), .byp_out(BR_SO), .tap_state(tap_state), .clockDR(clock_dr), .updateDR(update_dr), .clockIR(clockIR), .updateIR(updateIR), .tdo_en(tdo_en), .reset_n(reset_n), .shiftDR(shift_dr), .shiftIR(shiftIR), .selectIR(selectIR), .sync_capture_en(sync_capture_en), .sync_update_dr(sync_update_dr), .flag(flag)); 
      IR_reg #(width, sync_mode, id) u2(.tck(tck), .shiftIR(shiftIR), .clockIR(clockIR), .updateIR(updateIR), .reset_n(reset_n), .trst_n(trst_n), .scan_in(tdi), .flag(flag), .scan_out(IR_SO), .data_in(IR_PI), .data_out(instructions));	
	IR_decoder #(width) u3(.instructions(instructions), .extest(extest), .samp_load(samp_load), .idcode(idcode), .selectBR(selectBR) );
	
	always @( negedge tck )
	   TDO_reg = TDO_data;	 

	wire tdo = TDO_reg;	
	wire [10:0] vendor_id = man_num;
	wire [15:0] type_no = part;
	wire [3:0]  ver = version;
	wire [31:0] idcode_reg = {ver, type_no, vendor_id, 1'b1}; 
	
    always @(posedge clock_dr)  
        if ( id == 1 && idcode )
          begin
              idcode_ra[31] <= shift_dr ? tdi : idcode_reg[31];
              for ( i = 0; i < 31; i = i + 1 )
                  idcode_ra[i] <= shift_dr ? idcode_ra[i+1] : idcode_reg[i];
          end

      always @(posedge tck)  
        if ( id == 1 && idcode )
          begin
              idcode_rs[31] <= shift_dr ? tdi : idcode_reg[31];
              for ( i = 0; i < 31; i = i + 1 )
                  idcode_rs[i] <= shift_dr ? idcode_rs[i+1] : idcode_reg[i];
          end
                
      wire id_so = sync_mode ? idcode_rs[0] : idcode_ra[0];            
      
      always @( id_so or so or idcode )
       if ( id == 1 )
          so_out = idcode ? id_so : so;
       else
          so_out = so;
         
			
endmodule			
