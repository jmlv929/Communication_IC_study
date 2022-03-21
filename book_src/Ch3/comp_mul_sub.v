
`timescale 1ns / 1ps 
 
module comp_mul_sub(A_IN,  
                    B_IN,  
                    CEM_IN,  
                    CLK_IN,  
                    PCIN_IN,  
                    P_OUT); 
 
    input [15:0] A_IN; 
    input [13:0] B_IN; 
    input CEM_IN; 
    input CLK_IN; 
    input [47:0] PCIN_IN; 
   output [47:0] P_OUT; 
    
   wire GND_OPMODE; 
   wire [47:0] GND1; 
   wire [1:0] GND2; 
   wire [17:0] GND3; 
   wire VCC_OPMODE; 
    
   assign GND_OPMODE = 0; 
   assign GND1 = 48'b000000000000000000000000000000000000000000000000; 
   assign GND2 = 2'b00; 
   assign GND3 = 18'b000000000000000000; 
   assign VCC_OPMODE = 1; 
   DSP48 DSP48_INST (.A({A_IN[15:15], A_IN[15:15], A_IN[15:0]}),  
                     .B({B_IN[13:13], B_IN[13:13], B_IN[13:13], B_IN[13:13],  
         B_IN[13:0]}),  
                     .BCIN(GND3[17:0]),  
                     .C(GND1[47:0]),  
                     .CARRYIN(GND_OPMODE),  
                     .CARRYINSEL(GND2[1:0]),  
                     .CEA(VCC_OPMODE),  
                     .CEB(VCC_OPMODE),  
                     .CEC(VCC_OPMODE),  
                     .CECARRYIN(GND_OPMODE),  
                     .CECINSUB(VCC_OPMODE),  
                     .CECTRL(VCC_OPMODE),  
                     .CEM(CEM_IN),  
                     .CEP(VCC_OPMODE),  
                     .CLK(CLK_IN),  
                     .OPMODE({GND_OPMODE, GND_OPMODE, VCC_OPMODE, GND_OPMODE,  
         VCC_OPMODE, GND_OPMODE, VCC_OPMODE}),  
                     .PCIN(PCIN_IN[47:0]),  
                     .RSTA(GND_OPMODE),  
                     .RSTB(GND_OPMODE),  
                     .RSTC(GND_OPMODE),  
                     .RSTCARRYIN(GND_OPMODE),  
                     .RSTCTRL(GND_OPMODE),  
                     .RSTM(GND_OPMODE),  
                     .RSTP(GND_OPMODE),  
                     .SUBTRACT(VCC_OPMODE),  
                     .BCOUT(),  
                     .P(P_OUT[47:0]),  
                     .PCOUT()); 
   defparam DSP48_INST.AREG = 0; 
   defparam DSP48_INST.BREG = 0; 
   defparam DSP48_INST.CREG = 0; 
   defparam DSP48_INST.PREG = 0; 
   defparam DSP48_INST.MREG = 1; 
   defparam DSP48_INST.OPMODEREG = 0; 
   defparam DSP48_INST.SUBTRACTREG = 0; 
   defparam DSP48_INST.CARRYINSELREG = 0; 
   defparam DSP48_INST.CARRYINREG = 0; 
   defparam DSP48_INST.B_INPUT = "DIRECT"; 
   defparam DSP48_INST.LEGACY_MODE = "MULT18X18S"; 
endmodule 