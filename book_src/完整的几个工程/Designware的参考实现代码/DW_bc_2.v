
//-------------------------------------------------------------------------------------------------
//
// Title       : DW_bc_2
// Design      : Boundary Scan Cell Type BC_2
//
//-------------------------------------------------------------------------------------------------
// Description : DW_bc_2 is a boundary scan cell that can be used as a system input cell or as an 
// output cell. The DW_bc_2 cell may be synchronous or asynchronous with respect to tck (Test Clock
// system pin), depending on the port connections.
//-------------------------------------------------------------------------------------------------			
module DW_bc_2 ( 
         capture_clk,  //Clocks data into the capture stage
         update_clk,   //Clocks data into the update stage
         capture_en,   //Enable for data clocked into the capture stage, active low
         update_en,    //Enable for data clocked into the update stage, active high
         shift_dr,     //Enables the boundary scan chain to shift data one stage
                       //toward its serial output (tdo)
         mode,         //Determines whether data_out is controlled by the
                       //boundary scan cell or by the data_in signal
         si,           //Serial path from the previous boundary scan cell
         data_in,      //Input data
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
input   data_in;
output  data_out;
output  so;

//Singnal declaration
reg     capt_out;
reg     update_out;

wire data_out = mode ? update_out : data_in;
wire update_sig = update_en ? capt_out : update_out;

always @( posedge update_clk )
   update_out <= update_sig;

wire shft_out = shift_dr ? si : data_out;
wire capt_sig =  capture_en ? ~capt_out : ~shft_out;

always @( posedge capture_clk )
   capt_out <= ~capt_sig;

wire so = capt_out;

endmodule
