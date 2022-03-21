parameter M=9;
parameter N=5;

assign DATA_N[N-1:0]=DATA_M[M-1:M-N]+DATA_M[M-N-1];

7'b111_1111 {N{1'b1}}
