

//--------------------------------------------------------------------------------------------------
//
// Title       : DW03_bictr_scnto
// Design      : DW03_bictr_scnto

//-------------------------------------------------------------------------------------------------
//
// Description : DW03_bictr_scnto is a general-purpose up/down counter with static count-to logic.
// 
// When the count value equals count_to, the signal tercnt (terminal count) is asserted(HIGH). tercnt 
// can be connected to load through an inversion to synchronously reset the counter to a predefined 
// value on the input pin of the data bus. The up_dn input controls whether the counter counts up 
// (up_dn HIGH) or down (up_dn LOW), starting on the next positive edge of clk.
//-------------------------------------------------------------------------------------------------
module DW03_bictr_scnto (
	data,   //Counter load input
	up_dn,  //High for count up and low for count down
	load,	//Enable data load to counter, active low
	cen,    //Count enable, active high
	clk,    //Clock
	reset,	//Counter reset, active low
	count,	//Output count bus
	tercnt	//Terminal count flag
	)/* synthesis syn_builtin_du = "weak" */;

parameter width = 12;
parameter count_to = 12;

input [width-1:0]  data;
input 			   up_dn;  
input 			   load;   
input 			   cen;    
input 			   clk;    
input 			   reset;  
output [width-1:0] count;
output             tercnt; 

//Internal register declaration
reg [width-1:0]    count_i;
reg [width-1:0]    count_r;
wire [width-1:0]   add_bits;
reg                tercnt;		

//Addend or subtrahend based on up_dn control input 
assign add_bits = up_dn ? {{width-1{1'b0}},1'b1} : {width{1'b1}};

//The combo part of the counter
always @( count_r or load or data or cen or add_bits ) 
	if (!load) 
		count_i = data;
	else if (cen)
		count_i = count_r + add_bits;
	else
		count_i = count_r;
		
//The sequential part of counter		
always @ (posedge clk or negedge reset)
	if (!reset )
		count_r <= 0;
	else	   
		count_r <= count_i;
       
assign count = count_r;			

//Generation of terminal count
always @ (count_r)
	if(count_r == count_to) 
		tercnt = 1'b1;
	else
		tercnt = 1'b0;

endmodule
