`define N 16
`define POLY_CONST 0x1021
crc_new = {crc_old[N-2:0],1'b0} ^ ({N{(crc_old[N-1] ^ BitIn)}} & `POLY_CONST);

function [7:0] next_c8;
input [7:0] crc;
input B;
begin
  next_c8 = {crc[6:0],1'b0} ^ ({8{(crc[7] ^ B)}} & 8'h03 );//下划线的部分为本征多项式
end
endfunction

function [31:0] next_c8_ge; //M为输入带宽
input [M-1:0] data;
input [7:0] crc;
integer  i;
begin
 next_c8_ge = crc;
 for(i=0; i<M; i=i+1) begin
      next_c8_ge = next_c8(next_8_ge,data[M-i-1]);
 end
end
endfunction

function [31:0] next_c32_ge; //M+1 is the data maximum with
input [M:0] data;
input [31:0] crc;
integer  i;
begin
 next_c32_ge = crc;
 for(i=0; i<=M; i="i"+1) begin
      next_c32_ge = next_c32(next_c32_ge,data[M-i]);
 end
end
endfunction

//------------------------------------------------------------------
// CRC module for data[7:0] ,   crc[4:0]=1+x^2+x^5;
//------------------------------------------------------------------
module crc(
  input [7:0] data_in,
  input crc_en,
  output [4:0] crc_out,
  input rst,
  input clk);

  reg [4:0] lfsr_q,lfsr_c;

  assign crc_out = lfsr_q;

  always @(*) begin
    lfsr_c[0] = lfsr_q[0]^lfsr_q[2]^lfsr_q[3]^data_in[0]^data_in[3]^data_in[5]^data_in[6];
    lfsr_c[1] = lfsr_q[1]^lfsr_q[3]^lfsr_q[4]^data_in[1]^data_in[4]^data_in[6]^data_in[7];
    lfsr_c[2] = lfsr_q[0]^lfsr_q[3]^lfsr_q[4]^data_in[0]^data_in[2]^data_in[3]^data_in[6]^data_in[7];
    lfsr_c[3] = lfsr_q[0]^lfsr_q[1]^lfsr_q[4]^data_in[1]^data_in[3]^data_in[4]^data_in[7];
    lfsr_c[4] = lfsr_q[1]^lfsr_q[2]^data_in[2]^data_in[4]^data_in[5];
  end // always

  always @(posedge clk, posedge rst) begin
    if(rst) begin
      lfsr_q <= {5{1'b1}};
    end
    else begin
      lfsr_q <= crc_en ? lfsr_c : lfsr_q;
    end
  end // always
endmodule // crc

