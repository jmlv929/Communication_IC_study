// General Adder with carry bit
`timescale 1ns/1ps
module adderN #(parameter N=4) (
	input [N-1:0] a,
	input [N-1:0] b,
	input         cin,
	output        cout,
	output[N-1:0] sum
);
	assign {cout,sum} = a +b + cin;

endmodule

////assign {cout,sum[N-1:0]}={a[N-1],a[N-1:0]}+{b[N-1],b[N-1:0]} + cin;
//wire [N:0] adder_temp;
////assign {cout,sum}=adder_temp[N:0];
//assign cout=adder_temp[N];
//assign sum[N-1:0]=adder_temp[N-1:0];

