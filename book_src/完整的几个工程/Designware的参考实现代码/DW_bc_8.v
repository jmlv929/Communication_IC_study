
//-------------------------------------------------------------------------------------------------
//
// Title       : DW_bc_8
// Design      : Boundary Scan Cell Type BC_8
//
//-------------------------------------------------------------------------------------------------
// Description : DW_bc_8 is a boundary scan cell that can be used to control and observe both input 
// and output data. This component is intended to be used with DW_bc_2 boundary scan cell to form
// a bidirectional cell. The DW_bc_8 cell controls the input and output and the DW_bc_2 cell controls 
// the enable of the bidirectional pad. It lacks the INTEST supports and is used to observe the signal 
// at the corresponding input even while operating in output mode.
//-------------------------------------------------------------------------------------------------			
module DW_bc_8 ( 
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
         ic_input,     //Connected to IC input logic
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
output  ic_input;
output  data_out;
output  so;

//Singnal declaration
reg     update_out;
reg     capt_out;

wire ic_input = pin_input;
wire data_out = mode ? update_out : output_data;
wire update_sig = update_en ? capt_out : update_out;

always @(posedge update_clk)
  update_out <= update_sig; 

wire shft_out = shift_dr ? si : pin_input;
wire capt_sig = capture_en ? ~capt_out : ~shft_out; 

always @(posedge capture_clk)
  capt_out <= ~capt_sig;

wire so = capt_out;

endmodule
