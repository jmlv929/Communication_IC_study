
//IR decoder implementation
module IR_decoder ( instructions, extest, idcode, samp_load, selectBR )/* synthesis syn_builtin_du = "weak" */;
	parameter width = 4;
	input [width -1 : 0]  instructions;
	output                extest;
	output                idcode;
	output                samp_load;
	output                selectBR;
	
	wire extest = (instructions == {width{1'b0}});
	wire samp_load = (instructions == {{width-2{1'b0}},2'b10});
	wire idcode = (instructions == {{width-2{1'b0}},2'b01});
	wire selectBR = (instructions == {width{1'b1}});

endmodule	
