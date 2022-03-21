
//-------------------------------------------------------------------------------------------------
//
// Title       : DW_bc_3
// Design      : Boundary Scan Cell Type BC_3
//
//-------------------------------------------------------------------------------------------------
// Description : DW_bc_3 is a boundary scan cell that can be used as a system input cell.
// The DW_bc_3 cell may be synchronous or asynchronous with respect to tck (Test Clock
// system pin), depending on the port connections.
//-------------------------------------------------------------------------------------------------			
module DW_bc_3 ( 
         capture_clk,  //Clocks data into the capture stage
         capture_en,   //Enable for data clocked into the capture stage, active low
         shift_dr,     //Enables the boundary scan chain to shift data one stage
                       //toward its serial output (tdo)
         mode,         //Determines whether data_out is controlled by the
                       //boundary scan cell or by the data_in signal
         si,           //Serial path from the previous boundary scan cell
         data_in,      //Input data from system input pin
         data_out,     //output data to IC logic
         so            //Serial path to the next boundary scan cell
)/* synthesis syn_builtin_du = "weak" */;

//Input/output declaration
input   capture_clk;
input   capture_en;
input   shift_dr;
input   mode;
input   si;
input   data_in;
output  data_out;
output  so;

//Singnal declaration
reg     capt_out;

wire data_out = mode ? capt_out : data_in;

wire shft_out = shift_dr ? si : data_in; 
wire capt_sig =  capture_en ? ~capt_out : ~shft_out;

always @( posedge capture_clk )
   capt_out <= ~capt_sig;

wire so = capt_out;

endmodule
