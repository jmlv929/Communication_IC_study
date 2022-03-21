//-----------------------------------------------------------
//Module Name:  LTE_crc.v
//Department: Beijing R&D Center
//Function Description: LTE common module, CRC part
//-----------------------------------------------------------
//Version Design    Coding    Simulate    Review  Rel data
//V1.0    Michael   wangxiao  wangxiao    Lili    2013-6-30
//V1.1    Michael   wangxiao  mamingli            2013-8-30
//
//-----------------------------------------------------------
//Version   Modified History
//V1.0      draft
//V1.1      add CRC parameter for serial output
//
//-----------------------------------------------------------

always @ (posedge clk )
begin
	if (syn_rst)
		................
	else
		..............
end

always @ (posedge clk_122p88 or posedge ext_asy_rst)
  if(ext_asy_rst)
    rst_shft[1:0]<= 2'b11;
  else
    rst_shft[1:0]<= {rst_shft[0] ,1'b0};

assign asy_rst_122p88 = rst_shft[1];

always @ (posedge clk_122p88 or posedge asy_rst_122p88)
begin
  if (asy_rst_122p88)
    ............................;
  else
    ............................;
end

// next_state默认状态定义为不定态，便于功仿时检验状态机的完备性
always @ ( * )
begin   
  next_state = n'bx;
  case {input,curr_state}
    s0: next_state = ....;
    s1: next_state = ....;
    ...................
    default: next_state =....;
  endcase
end

always @ (posedge clk or posedge asy_rst)
  if (asy_rst)
    curr_state <= P_IDLE;
  else
    curr_state <= next_state;

always @ (posedge clk or posedge asy_rst)
  if (asy_rst)
    output <=......;
  else
    case (curr_state)
      s0: out <=.....;
      s0: out <=.....;
      ..........
      default: out <=.....;
    endcase
	
always @ (sel, in0, in1,in2)
  if (sel=2'b00)
    out = in0;
  else if (sel=2'b01)
    out = in1;
  else if (sel=2'b10)
    out = in2;
	
always @ (sel, in0, in1,in2)
  if (sel=2'b00)
    out = in0;
  else if (sel=2'b01)
    out = in1;
  else 
    out = in2;
	
always @(a,b,c,d)
  begin
    t1 <= a & b;
    t2 <= c & d;
    out <= t1 | t2;
  end

always @(posedge clk)
  begin
    q1 = d;
    q2 = q1;
    q3 = q2;
  end
 
always @(posedge clk)
  begin
    q3 = q2;
    q2 = q1;
    q1 = d;
  end

always @(posedge clk)
  begin
    q1 <= d;
    q2 <= q1;
    q3 <= q2;
  end

always @(posedge clk)
  begin
    q3 <= q2;
    q2 <= q1;
    q1 <= d;
  end
	
always @ (posedge clk or posedge asy_rst)
begin
  if (asy_rst)
    inc_en <= 1'b0;
    cont <=4'd0;
  else if (start)
    inc_en <= 1'b1;
    cont <=4'd0;
  else if (cont==4'd11)
    inc_en <= 1'b0;
    cont <= cont+1'b1;
  else if (inc_en)
    inc_en <= inc_en;
    cont <= cont+1'b1;
  else
    inc_en <= inc_en;
	cont <= 4'd0;
end

always @ (posedge clk or posedge asy_rst)
begin
  if (asy_rst)
    inc_en <= 1'b0;
  else if (start)
    inc_en <= 1'b1;
  else if (cont==4'd11)
    inc_en <= 1'b0;
  else;
end

always @ (posedge clk or posedge asy_rst)
begin
  if (asy_rst)
    cont <=4'd0;
  else if (inc_en)
    cont <= cont+1'b1;
  else
    cont <=4'd0;
end

module upctrl(
	.......
);
//信号定义
  reg [7:0]  sg_cnt;     
  reg [7:0]  chip_cnt;
  wire[15:0]  .......;
//功能描述体
  always @ (posedge clk or posedge asy_rst)
  begin
  ...............................
  end
	............................
endmodule

always @(posedge asy_rst or posedge wrclk)
  begin
    if (asy_rst)
      wren_adv[4:0] <= 5'b00000;
    else
      wren_adv[4:0] <= {wren_adv[3:0], 1'b1};
  end

assign wren = wren_adv[4];

always @(posedge asy_rst or posedge rdclk)
  begin
    if (asy_rst)
      rden_adv[7:0] <= 8'h00;
    else
      rden_adv[7:0] <= { rden_adv[6:0], wren_adv[4]};
  end

assign rden = rden_adv[7];



always @ (.....)
if (....)
assign a = c + b；
b <= a && c;

always @ (posedge asy_rst or posedge clk)
begin
	if (asy_rst)
		irpkg_len[23:16] <= 8'd0;
	else if ((headmsg_cnt == 12'd13) && i_vld && o_rdy)
		irpkg_len[23:16] <= 8'd0;
	else if ((headmsg_cnt > 12'd13) && i_vld && o_rdy)
		begin
			if (irpkg_len[23:16] == 8'd2)
				irpkg_len[23:16] <= 8'd0;
		else
			irpkg_len[23:16] <= irpkg_len[23:16] + 1'b1;
		end
	else;
end

assign temp={x[L-1],x}+{y[L-1],y};
assign z=(temp[L-1]!=temp[L])?{temp[L],{{L-1}{~temp[L]}}}:temp[L-1:0];

assign temp=x>>(Px-Py) + y;
assign z=(Pz>Py)? temp <<(Pz-Py) : temp >> (Py-Pz);

DW02_mult #(IN1_WIDTH,IN2_WIDTH)U_mult( .A(X), .B(Y), .TC(1'b1), .PRODUCT(Z));
assign mult_result=z[IN1_WIDTH+IN2_WIDTH-2:0];

module div_17u4q(
  input         clk,
  input[16:0]   dividend,
  input[ 3:0]   divisor,
  output[15:0]  quotient,
  output[ 3:0]  remainder
);
  wire      divide_by_zero;

  assign quotient = quotient_17[15:0];
  DW_div #(17, 4, 0, 1) U_div_17u4q(
        .a           ( dividend ),
        .b           ( divisor ),
        .quotient    ( quotient_17),
        .remainder   ( remainder ),
        .divide_by_0 ( divide_by_zero ));

endmodule

assign c[z-1:0]={ {{z-x}{a[x-1]}} , a[x-1:0] } 
               +{ {{z-y}{b[y-1]}} , b[y-1:0] };
//
localparam N=10;
wire [N-1:0] x;
assign x_3div4=x[N-1:0]-{{2{x[N-1]}},x[N-1:2]};
