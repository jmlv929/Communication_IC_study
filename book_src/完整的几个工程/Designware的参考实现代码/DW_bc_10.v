
//-------------------------------------------------------------------------------------------------
//
// Title       : DW_bc_10
// Design      : Boundary Scan Cell Type BC_10
//
//-------------------------------------------------------------------------------------------------
// Description : DW_bc_10 is a boundary scan cell, lacking INTEST support, that can be used to 
// monitor a signal at the corresponding pin instead of the signal driven from the system logic.
//-------------------------------------------------------------------------------------------------			
module DW_bc_10 ( 
         capture_clk,  //Clocks data into the capture stage
         update_clk,   //Clocks data into the update stage
         capture_en,   //Enable for data clocked into the capture stage, active low
         update_en,    //Enable for data clocked into the update stage, active high
         shift_dr,     //Enables the boundary scan chain to shift data one stage
                       //toward its serial output (tdo)
         mode,         //Determines whether data_out is controlled by the
                       //boundary scan cell or by the data_in signal
         si,           //Serial path from the previous boundary scan cell
         pin_input,    //IC system input pin
         output_data,  //IC output logic signal
         data_out,     //output data
         so            //Serial path to the next boundary scan cell
)/* synthesis syn_builtin_du = "weak" */;

//Input/output declaration
input   capture_clk;
input   update_clk;
input   capture_en;
input   update_en;
input   shift_dr;
input   mode;
input   si;
input   pin_input;
input   output_data;
output  data_out;
output  so;

//Singnal declaration
reg     capt_out;
reg     update_out;

wire data_out = mode ? update_out : output_data;
wire update_sig = update_en ? capt_out : update_out;

always @( posedge update_clk )
   update_out <= update_sig;

wire shft_out = shift_dr ? si : pin_input;
wire capt_sig =  capture_en ? ~capt_out : ~shft_out;

always @( posedge capture_clk )
   capt_out <= ~capt_sig;

wire so = capt_out;

endmodule
