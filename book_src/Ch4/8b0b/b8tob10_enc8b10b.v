// vx_version verilog
/*
******************************************************

MODULE_NAME =  enc8b10b
COMPANY =      Altera Corporation, Altera Ottawa Technology Center
WEB =          www.altera.com      www.altera.com/otc
EMAIL =        otc_technical@altera.com

FUNCTIONAL_DESCRIPTION :
Dual  8b/10b encoder, encodes two 8-bit words of data into two 10-bit encoded words.
END_FUNCTIONAL_DESCRIPTION

LEGAL :
Copyright 2003 Altera Corporation.  All rights reserved.
END_LEGAL

******************************************************
*/
module  b8tob10_enc8b10b (
clk,
reset_n,
idle_ins,
kin,
ena,
datain,
kerr,
dataout,
valid,
rdin,
rdforce,
rdout,
rdcascade);

// Ports and local variables. 
// '_F' indicates an auxiliary variable for flip-flops
// '_S' indicates an auxiliary variable for combinational signals
// '_W' indicates a VX2-created wire
input clk;
input reset_n;
input idle_ins;
input kin;
input ena;
input[7:0] datain;
output kerr;
output[9:0] dataout;
output valid;
input rdin;
input rdforce;
output rdout;
output rdcascade;
// flop is port_type  
// gates is lut_implement
// Added for pipelining
wire  clk ;
wire  reset_n ;
wire  idle_ins  ;
wire  kin  ; // Out Of Band (Special K)
wire  ena  ; // input 8 bit data
wire  [7:0] datain  ;
reg  kerr  ; // output 10 bit encoded data

reg _Fkerr;
reg  [9:0] dataout, _Fdataout  ;
reg  valid, _Fvalid  ;
wire  rdin  ;
wire  rdforce  ;
reg  rdout, _Frdout  ;
reg  rdcascade, _Srdcascade  ;
reg  [7:0] datain_d1, _Fdatain_d1  ;
reg  kin_d1, _Fkin_d1  ;
reg  kin_d2, _Fkin_d2  ;
reg  valid_pre1, _Fvalid_pre1  ;
reg  valid_pre2, _Fvalid_pre2  ;
wire  rd  ;
wire  [15:0] dlut_dat  ;
reg  [9:0] klut_dat, _Fklut_dat  ;
reg  kchar, _Skchar  ;
reg  [1:0] invert, _Sinvert  ;
reg  neutral, _Sneutral  ;
reg  [9:0] dat10b, _Sdat10b  ;
reg  [9:0] dat10b_pos, _Sdat10b_pos  ;
reg  speciald  ;
// **************************************************************
// structural_code
/*CALL*/
reg _Sspeciald;
 b8tob10_encoding_lut  encoding_lut(.reset_n(reset_n), .clk(clk),
.rdaddress_a(datain_d1), .q_a(dlut_dat));

assign rd = rdforce ? rdin:rdout;// **************************************************************
// procedural_code
// combinational_block



always @( * )  begin
// initialize flip-flop and combinational regs
    _Fkerr = kerr;
    _Fdataout = dataout;
    _Fvalid = valid;
    _Frdout = rdout;
    _Srdcascade = 0;
    _Fdatain_d1 = datain_d1;
    _Fkin_d1 = kin_d1;
    _Fkin_d2 = kin_d2;
    _Fvalid_pre1 = valid_pre1;
    _Fvalid_pre2 = valid_pre2;
    _Fklut_dat = klut_dat;
    _Skchar = 0;
    _Sinvert = 0;
    _Sneutral = 0;
    _Sdat10b = 0;
    _Sdat10b_pos = 0;
    _Sspeciald = 0;

// mainline code
    begin // *** put code block here ***
    // --------------------- Channel ----------------------------
    // Added for pipelining
        begin 
            _Fdatain_d1 = ena ? datain:8'b101_11100;
            _Fkin_d1 = (kin | ~ ena);
            _Fkin_d2 = kin_d1;
            _Fvalid_pre2 = ena | idle_ins;
            _Fvalid_pre1 = valid_pre2;
            _Fvalid = valid_pre1;
            case (datain_d1)
                8'b000_11100:
                    _Fklut_dat = 10'b0010_111100;// K28.0
                8'b001_11100:
                    _Fklut_dat = 10'b1001_111100;// K28.1
                8'b010_11100:
                    _Fklut_dat = 10'b1010_111100;// K28.2
                8'b011_11100:
                    _Fklut_dat = 10'b1100_111100;// K28.3
                8'b100_11100:
                    _Fklut_dat = 10'b0100_111100;// K28.4
                8'b101_11100:
                    _Fklut_dat = 10'b0101_111100;// K28.5
                8'b110_11100:
                    _Fklut_dat = 10'b0110_111100;// K28.6
                8'b111_11100:
                    _Fklut_dat = 10'b0001_111100;// K28.7
                8'b111_10111:
                    _Fklut_dat = 10'b0001_010111;// K23.7
                8'b111_11011:
                    _Fklut_dat = 10'b0001_011011;// K27.7 
                8'b111_11101:
                    _Fklut_dat = 10'b0001_011101;// K29.7
                8'b111_11110:
                    _Fklut_dat = 10'b0001_011110;// K30.7
                8'b111_11111:
                    _Fklut_dat = 10'b1000_111100;// 10B_ERR
                default:
                    begin 
                        _Fklut_dat = 10'b0101_111100;// K28.5
                    end 
            endcase
// case(datain_d1)
            _Fkerr = kin_d2 & ~ dlut_dat[15];
            if (kin_d2) begin 
                _Sspeciald = 1'b0;
                _Sinvert = 2'b11;//klut_dat[12:11];
                _Sneutral = dlut_dat[14];
                _Sdat10b = klut_dat[9:0];
            end 
            else
            begin 
                _Sspeciald = dlut_dat[13];
                _Sinvert = dlut_dat[12:11];
                _Sneutral = dlut_dat[10];
                _Sdat10b = dlut_dat[9:0];
            end // Data to use when current rd is positive.
            // Invert certain bits based on lookup code
            case (invert)
                2'b00:
                    _Sdat10b_pos = {dat10b[9], (dat10b[8] ^ speciald), (dat10b[7] ^ speciald), dat10b[6],
                    dat10b[5:0]};
                2'b01:
                    _Sdat10b_pos = {dat10b[9:6], ~ dat10b[5:0]};
                2'b10:
                    _Sdat10b_pos = {~ dat10b[9:6], dat10b[5:0]};
                2'b11:
                    _Sdat10b_pos = {~ dat10b[9:6], ~ dat10b[5:0]};
            endcase
// Choose between positive and negative disparity based on rd
            if (rd) begin // disparity going from positive to (positive or negative)

                _Fdataout = dat10b_pos;
            end 
            else
            begin // disparity going from negative to (negative or positive)

                _Fdataout = dat10b;
            end // Calculate new running disparity
            _Srdcascade = neutral ^ ~ rd;// For use in cascaded encoders
            if (valid_pre1) begin 
                _Frdout = rdcascade;
            end // *** end of code block ***
        end 
    end // sequential_blocks


// update regs for combinational signals
// The non-blocking assignment causes the always block to 
// re-stimulate if the signal has changed
    rdcascade <= _Srdcascade;
    kchar <= _Skchar;
    invert <= _Sinvert;
    neutral <= _Sneutral;
    dat10b <= _Sdat10b;
    dat10b_pos <= _Sdat10b_pos;
    speciald <= _Sspeciald;
end
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        kerr<=0;
        dataout<=0;
        valid<=0;
        rdout<=0;
        datain_d1<=0;
        kin_d1<=0;
        kin_d2<=0;
        valid_pre1<=0;
        valid_pre2<=0;
        klut_dat<=0;
    end else begin
        kerr<=_Fkerr;
        dataout<=_Fdataout;
        valid<=_Fvalid;
        rdout<=_Frdout;
        datain_d1<=_Fdatain_d1;
        kin_d1<=_Fkin_d1;
        kin_d2<=_Fkin_d2;
        valid_pre1<=_Fvalid_pre1;
        valid_pre2<=_Fvalid_pre2;
        klut_dat<=_Fklut_dat;
    end
end
endmodule
