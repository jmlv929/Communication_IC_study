assign D0_in[3:0]=D[3:0];
assign D1_in[3:0]=S[0] ? {D0_in[2:0],D0_in[3] } :D0_in[3:0];
assign D2_in[3:0]=S[1] ? {D1_in[2:0],D1_in[3] } :D1_in[3:0];
