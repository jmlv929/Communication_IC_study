always @(posedge CLK or negedge RESET_N)
begin
	if(~RESET_N)
		p_shiftreg <= 32'b0;
	else if(S_VIN && ~s_vin_1q)
		p_shiftreg <= {E[15:0],16'hffff};
	else if(s_vin_1q)
		p_shiftreg<={^(DISTURB_POLY & p_shiftreg),p_shiftreg[31:1]};
end

g[1] =	(d & P1[0])^ (d1q & P1[1]) ^ (d2q & P1[2]) ^ (d3q & P1[3]) ^ (d4q & P1[4]) ^ 
(d5q & P1[5]) ^ (d6q & P1[6]);
g[2] =	(d & P2[0])   ^ (d1q & P2[1]) ^ (d2q & P2[2]) ^ (d3q & P2[3]) ^ (d4q & P2[4]) ^ 
(d5q & P2[5]) ^ (d6q & P2[6]);

g[1] =(d & 1) ^ (d1q & 1) ^ (d2q & 1) ^ (d3q & 1) ^ (d4q & 0) ^ (d5q & 0) ^ (d6q & 1)
     = d ^ d1q ^ d2q ^ d3q ^ d6q;

generate
  genvar i;
  for(i = 0; i < 64; i = i + 1)
  begin:gen_acs
    dec_viterbi_acs u_acs
    (
      .VITERBI_TYPE         (VITERBI_TYPE            ),
      .RCPC217_POLY1        (RCPC217_POLY1           ),
      .RCPC217_POLY2        (RCPC217_POLY2           ),
      .RCPC317_POLY1        (RCPC317_POLY1           ),
      .RCPC317_POLY2        (RCPC317_POLY2           ),
      .RCPC317_POLY3        (RCPC317_POLY3           ),
      .STATE                (i                       ),
      .DIN0                 (din0                    ), //g0
      .DIN1                 (din1                    ), //g1
      .DIN2                 (din2                    ), //g2
      .PRESTATE0_DISTANCESUM(sum_state[{1'b0,i[5:1]}]),
      .PRESTATE1_DISTANCESUM(sum_state[{1'b1,i[5:1]}]),
      .DISTANCESUM0         (distancesum0_state[i]   ),
      .DISTANCESUM1         (distancesum1_state[i]   ),
      .DISTANCESUM          (distancesum_state[i]    ),
      .ACSBIT                (acsbit_state[i]         )
    );
  end
endgenerate

