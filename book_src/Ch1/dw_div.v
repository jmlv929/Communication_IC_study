`timescale 1ns / 10ps
module DW_div #(
parameter a_width = 32,
parameter b_width = 16,
parameter tc_mode = 0,
parameter rem_mode = 1
)(
input     [a_width-1: 0]a,
input     [b_width-1: 0]b,
output reg[b_width-1: 0]remainder,
output reg[a_width-1: 0]quotient,
output                  divide_by_0
);
//Internal signal declaration
wire [a_width - 1 : 0 ]    param1;
wire [b_width - 1: 0 ]     param2;
wire [a_width - 1 : 0 ]    quot;
wire [a_width - 1 : 0 ]    quotient_2s;
wire [a_width - 1 : 0 ]    temp;
wire [b_width - 1: 0 ]     mod;

//Output assignment
assign divide_by_0 = ~|b;

//Internal signal assignment
assign param1 = tc_mode ? ( a[a_width -1] ? (~a + 1'b1) : a ) : a;
assign param2 = tc_mode ? ( b[b_width -1] ? (~b + 1'b1) : b ) : b;

assign {quot,mod} = div ( param1, param2 );
// Function to get the quotient and remainder.
// Shift/subtract non-restoring algorithm is implemented
function [ a_width + b_width - 1 : 0 ] div;
input [a_width - 1 : 0 ] a;
input [b_width - 1: 0 ] b;

reg [b_width : 0 ] sum;//width = B_width + 1
reg [a_width - 1 : 0 ] dividend;
reg [b_width : 0 ] rem_adjust;
reg [b_width : 0 ] temp_b;
reg [b_width - 1: 0 ] rem;
integer i;

begin
  sum = {b_width{1'b0}};
  dividend = a;
  sum[0] = a[a_width - 1]; //MSB
  dividend = dividend << 1'b1;
  temp_b = ~b + 1'b1;
    sum = sum + temp_b;
  dividend[0] = ~sum[b_width];
  for ( i = 0 ; i <  a_width - 1'b1 ; i = i + 1'b1 )
    begin
      if ( sum[b_width] )// 1 = -ve, 0 = +ve
        begin
          temp_b = b;
        end
      else
        begin
            temp_b = ~b + 1'b1;
        end
        sum = sum << 1'b1;
        sum[0] = dividend[a_width - 1];
        dividend = dividend << 1'b1;
        sum = sum + temp_b;
      dividend[0] = ~sum[b_width];
    end
  //If remainder is -ve add divisor
  rem_adjust = sum[b_width] ? sum + b : sum;
  rem = rem_adjust[b_width - 1: 0];
  div = {dividend, rem} ;
end
endfunction

assign quotient_2s = ~quot + 1'b1;
assign temp=(a[a_width-1]^b[b_width-1])?{1'b1,quotient_2s}:{1'b0,quot};


//Output assignment
always @( a or b or mod )
  if ( rem_mode == 1 )
    begin
      if (b == 0)
        begin
          if(tc_mode)
            remainder = $signed(a);
          else
            remainder = a;
        end
      else if(tc_mode==1&&b=={b_width{1'b1}}&&a=={1'b1,{a_width-1{1'b0}}})
        remainder = 0;
      else if ((tc_mode == 1) && ( mod != 0 ) && ( a[a_width-1] == 1))
        //The sign of the result is the sign of A input or B input based on rem_mode
        remainder = ~mod + 1'b1;
      else
        remainder = mod;
    end
  else
    begin
      if ( tc_mode )
        begin
          if (b == 0)
            remainder = $signed(a[b_width-1:0]);
          else if((b=={b_width{1'b1}})&&(a=={1'b1,{a_width-1{1'b0}}}))
            remainder = 0;
          else
            case ({a[a_width-1],b[b_width-1]})
              2'b00: remainder = mod;
              2'b01: if ( mod != 0)
                remainder = b + mod;
              else
                remainder = mod;

              2'b10: if ( mod != 0)
                remainder = b - mod;
              else
                remainder = mod;

              2'b11: if ( mod != 0)
                remainder = ~mod + 1'b1;
              else
                remainder = mod;
            endcase
        end
      else
        begin
          if (b == 0)
            remainder = a[b_width - 1:0];
          else
            remainder = mod;
        end
    end

//Output assignment
always @( a or b or temp or quot )
  if ( b )
  begin
    case ( tc_mode )
      1'b1 :
      if ((b=={b_width{1'b1}})&&(a=={1'b1,{a_width-1{1'b0}}}))
        quotient = a;  //-A(max)/-1 = +A(max)
      else quotient = temp;

      1'b0 :quotient = quot;
    endcase
  end
  else
  begin
    /* In the SIGNED case, if A is +ve, the max. +ve value is given as the Quotient.
                         if A is -ve, the max. -ve value is given as the Quotient.
       In the UNSIGNED case, a binary ALL 1s is given as the Quotient
      Max and Min values
      For a signed BYTE ( MSB:sign, 7-bits:magnitude )
        Smallest +ve:0000 0000
        largest +ve :0111 1111 = 127
        largest -ve :1111 1111 = -1
        smallest -ve:1000 0000 = -128
      */
    case ( tc_mode )
      1'b1:quotient=a[a_width-1]?{1'b1,{(a_width-1){1'b0}}}:{1'b0,{(a_width-1){1'b1}}};
      1'b0:quotient={a_width{1'b1}};
    endcase
  end

endmodule
