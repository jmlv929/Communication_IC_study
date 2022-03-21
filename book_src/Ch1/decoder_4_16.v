module decoder_4_16(
	input enable,				   
	input [3:0] in,
	output [15:0] out 
);
//	wire enable;
//	wire [3:0] in;
//	wire [15:0] out;
	wire [3:0] high_d;
	wire [3:0] low_d;

	assign high_d[3]=( in[3])&( in[2])&enable;
	assign high_d[2]=( in[3])&(~in[2])&enable;
	assign high_d[1]=(~in[3])&( in[2])&enable;
	assign high_d[0]=(~in[3])&(~in[2])&enable;

	assign low_d[3]=( in[1])&( in[0]);	
	assign low_d[2]=( in[1])&(~in[0]);
	assign low_d[1]=(~in[1])&( in[0]);
	assign low_d[0]=(~in[1])&(~in[0]);

	assign out[15]=high_d[3]&low_d[3];
	assign out[14]=high_d[3]&low_d[2];
	assign out[13]=high_d[3]&low_d[1];
	assign out[12]=high_d[3]&low_d[0];
	assign out[11]=high_d[2]&low_d[3];
	assign out[10]=high_d[2]&low_d[2];
	assign out[ 9]=high_d[2]&low_d[1];
	assign out[ 8]=high_d[2]&low_d[0];	
	assign out[ 7]=high_d[1]&low_d[3];
	assign out[ 6]=high_d[1]&low_d[2];
	assign out[ 5]=high_d[1]&low_d[1];
	assign out[ 4]=high_d[1]&low_d[0];
	assign out[ 3]=high_d[0]&low_d[3];
	assign out[ 2]=high_d[0]&low_d[2];
	assign out[ 1]=high_d[0]&low_d[1];
	assign out[ 0]=high_d[0]&low_d[0];	
endmodule
