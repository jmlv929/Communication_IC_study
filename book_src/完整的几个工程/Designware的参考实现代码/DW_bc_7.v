
//-------------------------------------------------------------------------------------------------
//
// Title       : DW_bc_7
// Design      : Boundary Scan Cell Type BC_7
//
//-------------------------------------------------------------------------------------------------
// Description : DW_bc_7 is a boundary scan cell used to control and observe both input and output 
// data. DW_bc_7 is intended to be used with a type BC_2 boundary scan cell to form a bidirectional 
// cell. The DW_bc_7 cell controls the input and ouptput and the DW_bc_2 cell controls the enable
// of the bidirectional pad.
//-------------------------------------------------------------------------------------------------			
module DW_bc_7 ( 
         capture_clk,  //Clocks data into the capture stage
         update_clk,   //Clocks data into the update stage
         capture_en,   //Enable for data clocked into the capture stage, active low
         update_en,    //Enable for data clocked into the update stage, active high
         shift_dr,     //Enables the boundary scan chain to shift data one stage
                       //toward its serial output (tdo)
         mode1,        //Determines whether data_out is controlled by the
                       //boundary scan cell or by the output_data signal
         mode2,        //Determines whether ic_input is controlled by the
                       //boundary scan cell or by the pin_input signal
         si,           //Serial path from the previous boundary scan cell
         pin_input,    //IC system input pin
         control_out,  //Control signal for the output enable
         output_data,  //IC output logic signal
         ic_input,     //IC input logic signal
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
input   control_out;
input   output_data;
output  ic_input;
output  data_out;
output  so;

//Singnal declaration
reg     update_out;
reg     capt_out;

wire data_out_i = mode1 ? ~update_out : ~output_data ;
wire data_out = ~data_out_i;
wire update_sig = update_en ? ~capt_out : ~update_out;

always @(posedge update_clk)
  update_out <= ~update_sig; 

wire ic_out = mode2 ? update_out : pin_input;
wire poc_out = ~(~control_out | mode1) ? ~output_data : ~ic_out;
wire shft_out = shift_dr ? si : ~poc_out;
wire capt_sig = capture_en ? ~capt_out : ~shft_out; 

always @(posedge capture_clk)
  capt_out <= ~capt_sig;

wire so = capt_out;
wire ic_input = ic_out;

endmodule
