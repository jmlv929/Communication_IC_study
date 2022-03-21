
//-------------------------------------------------------------------------------------------------
//
// Title       : DW_bc_9
// Design      : Boundary Scan Cell Type BC_9
//
//-------------------------------------------------------------------------------------------------
// Description : DW_bc_9 is a boundary scan cell is an output cell that observes the signal at the 
// corresponding pin for EXTEST and observes the signal driven from the system logic for INTEST and 
// SAMPLE. It allows a connected system network both to be driven and captured at the same pin, 
// thus allowing such networks to be tested for shorts to others even when there are no other 
// connected boundary scan device pins.

//-------------------------------------------------------------------------------------------------			
module DW_bc_9 ( 
         capture_clk,  //Clocks data into the capture stage
         update_clk,   //Clocks data into the update stage
         capture_en,   //Enable for data clocked into the capture stage, active low
         update_en,    //Enable for data clocked into the update stage, active high
         shift_dr,     //Enables the boundary scan chain to shift data one stage
                       //toward its serial output (tdo)
         mode1,        //Determines whether data_out is controlled by the
                       //boundary scan cell or by the data_in signal
         mode2,        //Determines whether data_out is controlled by the
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
input   mode1;
input   mode2;
input   si;
input   pin_input;
input   output_data;
output  data_out;
output  so;

//Singnal declaration
reg     update_out;
reg     capt_out;

wire data_out = mode2 ? update_out : output_data;
wire update_sig = update_en ? capt_out : update_out;

always @(posedge update_clk)
  update_out <= update_sig; 

wire po_out = mode1 ? pin_input : output_data;
wire shft_out = shift_dr ? si : po_out;
wire capt_sig = capture_en ? ~capt_out : ~shft_out; 

always @(posedge capture_clk)
  capt_out <= ~capt_sig;

wire so = capt_out;

endmodule
