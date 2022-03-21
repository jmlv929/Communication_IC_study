
//-------------------------------------------------------------------------------------------------
//
// Title       : DW_bc_4
// Design      : Boundary Scan Cell Type BC_4
//
//-------------------------------------------------------------------------------------------------
// Description : DW_bc_4 is a boundary scan cell for performance-sensitive IC inputs such as clocks.
// It is an obseve-only cell and does not support INTEST or RUNBIST instructions. 
//-------------------------------------------------------------------------------------------------			
module DW_bc_4 ( 
         capture_clk,  //Clocks data into the capture stage
         capture_en,   //Enable for data clocked into the capture stage, active low
         shift_dr,     //Enables the boundary scan chain to shift data one stage
                       //toward its serial output (tdo)
         si,           //Serial path from the previous boundary scan cell
         data_in,      //Input data from system input pin
         data_out,     //output data to IC logic
         so            //Serial path to the next boundary scan cell
)/* synthesis syn_builtin_du = "weak" */;

//Input/output declaration
input   capture_clk;
input   capture_en;
input   shift_dr;
input   si;
input   data_in;
output  data_out;
output  so;

//Singnal declaration
reg     capt_out;

wire data_out = data_in;

wire shft_out = shift_dr ? si : data_in;
wire capt_sig = capture_en ? ~capt_out : ~shft_out;

always @( posedge capture_clk )
   capt_out <= ~capt_sig;

wire so = capt_out;

endmodule
