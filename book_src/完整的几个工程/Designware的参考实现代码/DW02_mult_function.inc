
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------------
//
// ABSTRACT: Function Descriptions for Verilog
//
//           Various Multiplier function descriptions
//           Used for synthesis inference of operators,
//           and for behavioral Verilog simulation.
//
//           The following functions are declared:
//
//           DWF_mult_tc(a,b)  
//           DWF_mult_uns(a,b)
//           DWF_mult_pipe_tc(a,b,clk)
//           DWF_mult_pipe_uns(a,b,clk)
//           DWF_mult_2_s_tc(a,b,clk)
//           DWF_mult_2_s_uns(a,b,clk)
//           DWF_mult_3_s_tc(a,b,clk)
//           DWF_mult_3_s_uns(a,b,clk)
//           DWF_mult_4_s_tc(a,b,clk)
//           DWF_mult_4_s_uns(a,b,clk)
//           DWF_mult_5_s_tc(a,b,clk)
//           DWF_mult_5_s_uns(a,b,clk)
//           DWF_mult_6_s_tc(a,b,clk)
//           DWF_mult_6_s_uns(a,b,clk)
//
// MODIFIED : - 
//	10/14/1998	Jay Zhu	STAR 59348
//
//------------------------------------------------------------------------------

// mult_tc(a,b) and mult_uns(a,b) are the base signed and unsigned multiplies
// used in all the other multiply functions


function [A_width+B_width-1 : 0] DWF_mult_tc;
// Function to perform a signed (two's complement) multiplication 

// synopsys map_to_operator MULT_TC_OP 
// synopsys return_port_name Z

input [A_width-1:0] A; 
input [B_width-1:0] B; 

reg sign;

begin
  // synopsys translate_off
  sign = A[A_width-1] ^ B[B_width-1];   // generate sign bit of output

  if (A[A_width-1] == 1'b1) A = ~A + 1'b1;   // convert A to unsigned
  if (B[B_width-1] == 1'b1) B = ~B + 1'b1;   // convert B to unsigned

  DWF_mult_tc = A * B;   // perform unsigned multiply

  if (sign == 1'b1) DWF_mult_tc = ~DWF_mult_tc + 1'b1;   // if result is -ve, return  
                                                 // 2's complement 
  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_uns;
// Function to perform an unsigned multiplication 

// synopsys map_to_operator MULT_UNS_OP 
// synopsys return_port_name Z

input [A_width-1:0] A; 
input [B_width-1:0] B; 

begin
  // synopsys translate_off

  DWF_mult_uns = A * B;   // perform unsigned multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_pipe_tc;
// Function to perform a signed (two's complement) pipelined multiply
// Use with Behavioral Compiler to automatically select number of pipe stages

// synopsys map_to_operator mult_n_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_pipe_tc = DWF_mult_tc(A,B);   // perform signed multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_pipe_uns;
// Function to perform an unsigned pipelined multiply
// Use with Behavioral Compiler to automatically select number of pipe stages

// synopsys map_to_operator mult_n_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_pipe_uns = A * B;   // perform unsigned multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_2_s_tc;
// Function to perform a signed (two's complement) pipelined multiply
// Use with Behavioral Compiler to select a 2-stage pipeline

// synopsys map_to_operator mult_2_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_2_s_tc = DWF_mult_tc(A,B);   // perform signed multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_2_s_uns;
// Function to perform an unsigned pipelined multiply
// Use with Behavioral Compiler to select a 2-stage pipeline

// synopsys map_to_operator mult_2_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_2_s_uns = A * B;   // perform unsigned multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_3_s_tc;
// Function to perform a signed (two's complement) pipelined multiply
// Use with Behavioral Compiler to select a 3-stage pipeline

// synopsys map_to_operator mult_3_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_3_s_tc = DWF_mult_tc(A,B);   // perform signed multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_3_s_uns;
// Function to perform an unsigned pipelined multiply
// Use with Behavioral Compiler to select a 3-stage pipeline

// synopsys map_to_operator mult_3_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_3_s_uns = A * B;   // perform unsigned multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_4_s_tc;
// Function to perform a signed (two's complement) pipelined multiply
// Use with Behavioral Compiler to select a 4-stage pipeline

// synopsys map_to_operator mult_4_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_4_s_tc = DWF_mult_tc(A,B);   // perform signed multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_4_s_uns;
// Function to perform an unsigned pipelined multiply
// Use with Behavioral Compiler to select a 4-stage pipeline

// synopsys map_to_operator mult_4_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_4_s_uns = A * B;   // perform unsigned multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_5_s_tc;
// Function to perform a signed (two's complement) pipelined multiply
// Use with Behavioral Compiler to select a 5-stage pipeline

// synopsys map_to_operator mult_5_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_5_s_tc = DWF_mult_tc(A,B);   // perform signed multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_5_s_uns;
// Function to perform an unsigned pipelined multiply
// Use with Behavioral Compiler to select a 5-stage pipeline

// synopsys map_to_operator mult_5_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_5_s_uns = A * B;   // perform unsigned multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_6_s_tc;
// Function to perform a signed (two's complement) pipelined multiply
// Use with Behavioral Compiler to select a 6-stage pipeline

// synopsys map_to_operator mult_6_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_6_s_tc = DWF_mult_tc(A,B);   // perform signed multiply

  // synopsys translate_on 
end

endfunction


function [A_width+B_width-1 : 0] DWF_mult_6_s_uns;
// Function to perform an unsigned pipelined multiply
// Use with Behavioral Compiler to select a 6-stage pipeline

// synopsys map_to_operator mult_6_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A; 
input [B_width-1:0] B; 
input CLK;

begin
  // synopsys translate_off

  DWF_mult_6_s_uns = A * B;   // perform unsigned multiply

  // synopsys translate_on 
end

endfunction


//  unified old inference names

function [A_width+B_width-1 : 0] mult_tc;
 
// synopsys map_to_operator MULT_TC_OP 
// synopsys return_port_name Z

input [A_width-1:0] A;
input [B_width-1:0] B;
 
begin
  mult_tc = DWF_mult_tc(A,B);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_uns;
 
// synopsys map_to_operator MULT_UNS_OP 
// synopsys return_port_name Z

input [A_width-1:0] A;
input [B_width-1:0] B;
 
begin
  mult_uns = DWF_mult_uns(A,B);  
end
 
endfunction

function [A_width+B_width-1 : 0] mult_pipe_tc;
 
// synopsys map_to_operator mult_n_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_pipe_tc = DWF_mult_pipe_tc(A,B,CLK);  
end
 
endfunction

function [A_width+B_width-1 : 0] mult_pipe_uns;
 
// synopsys map_to_operator mult_n_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_pipe_uns = DWF_mult_pipe_uns(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_2_s_tc;
 
// synopsys map_to_operator mult_2_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_2_s_tc = DWF_mult_2_s_tc(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_2_s_uns;
 
// synopsys map_to_operator mult_2_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_2_s_uns = DWF_mult_2_s_uns(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_3_s_tc;
 
// synopsys map_to_operator mult_3_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_3_s_tc = DWF_mult_3_s_tc(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_3_s_uns;
 
// synopsys map_to_operator mult_3_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_3_s_uns = DWF_mult_3_s_uns(A,B,CLK);   // perform unsigned multiply
end
 
endfunction

function [A_width+B_width-1 : 0] mult_4_s_tc;
 
// synopsys map_to_operator mult_4_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_4_s_tc = DWF_mult_4_s_tc(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_4_s_uns;
 
// synopsys map_to_operator mult_4_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_4_s_uns = DWF_mult_4_s_uns(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_5_s_tc;
 
// synopsys map_to_operator mult_5_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_5_s_tc = DWF_mult_5_s_tc(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_5_s_uns;
 
// synopsys map_to_operator mult_5_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_5_s_uns = DWF_mult_5_s_uns(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_6_s_tc;
 
// synopsys map_to_operator mult_6_stage_TC_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_6_s_tc = DWF_mult_6_s_tc(A,B,CLK);   
end
 
endfunction

function [A_width+B_width-1 : 0] mult_6_s_uns;
 
// synopsys map_to_operator mult_6_stage_UNS_OP
// synopsys return_port_name Z
 
input [A_width-1:0] A;
input [B_width-1:0] B;
input CLK;
 
begin
  mult_6_s_uns = DWF_mult_6_s_uns(A,B,CLK);   
end
 
endfunction
