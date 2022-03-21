// vx_version verilog
// vx_version
/* 
******************************************************

MODULE_NAME =  dec8b10b 
COMPANY =      Altera Corporation, Altera Ottawa Technology Center
WEB =          www.altera.com      www.altera.com/otc
EMAIL =        telecom@altera.com

FUNCTIONAL_DESCRIPTION :
8b 10b decoder.
END_FUNCTIONAL_DESCRIPTION

SUB_MODULES = <call> 

LEGAL :
Copyright 2000 Altera Corporation.  All rights reserved. 
END_LEGAL

******************************************************
*/
// altera message_level Level2
module  dec_b10tob8_dec8b10b (
clk,
reset_n,
idle_del,
ena,
datain,
rdforce,
rdin,
valid,
dataout,
kout,
kerr,
rdcascade,
rdout,
rderr);

// Ports and local variables. 
// '_F' indicates an auxiliary variable for flip-flops
// '_S' indicates an auxiliary variable for combinational signals
// '_W' indicates a VX2-created wire
input clk;
input reset_n;
input idle_del;
input ena;
input[9:0] datain;
input rdforce;
input rdin;
output valid;
output[7:0] dataout;
output kout;
output kerr;
output rdcascade;
output rdout;
output rderr;
wire  clk ;
wire  reset_n ;
wire  idle_del  ; // 10b encoded data
wire  ena  ;
wire  [9:0] datain  ; // [9:0] jhgf_iedcba,
wire  rdforce  ;
wire  rdin  ; // 8b decoded data
reg  valid, _Fvalid  ;
wire  [7:0] dataout  ; // [7:0] HGF_EDCBA,
reg  kout, _Fkout  ;
reg  kerr  ; // output flop [1:0]   disparity

reg _Fkerr;
reg  rdcascade, _Srdcascade  ;
reg  rdout, _Frdout  ;
reg  rderr, _Frderr  ;
reg  [2:0] data3b, _Fdata3b  ;
reg  [4:0] data5b, _Fdata5b  ;
wire  rd_internal  ;
reg  is_111000, _Fis_111000  ;
reg  is_000111, _Fis_000111  ;
reg  is_1100, _Fis_1100  ;
reg  is_0011, _Fis_0011  ;
reg  rd6_neg  ; // More zeros than one

reg _Frd6_neg;
reg  rd6_pos  ; // More ones than zeros

reg _Frd6_pos;
reg  rd4_neg  ; // More zeros than one

reg _Frd4_neg;
reg  rd4_pos  ; // More ones than zeros

reg _Frd4_pos;
reg  [1:0] sum_cba, _Ssum_cba  ;
reg  [1:0] sum_ied, _Ssum_ied  ;
reg  [2:0] sum_jhgf, _Ssum_jhgf  ;
reg  K28minus, _SK28minus  ;
reg  is_idle, _Sis_idle  ;
reg  [2:0] data3b_pre1, _Fdata3b_pre1  ;
reg  [4:0] data5b_pre1, _Fdata5b_pre1  ;
reg  valid_pre1, _Fvalid_pre1  ;
reg  kout_pre1, _Fkout_pre1  ;
reg  kerr_pre1, _Fkerr_pre1  ;
reg  enable_d1, _Fenable_d1  ;
wire  [7:0] dataout_pre1  ;
// **************************************************************
// structural_code 
assign rd_internal = rdforce ? rdin:rdout;

assign dataout_pre1 = {data3b_pre1, data5b_pre1};

assign dataout = {data3b, data5b};


always @( * )  begin
// initialize flip-flop and combinational regs
    _Fvalid = valid;
    _Fkout = kout;
    _Fkerr = kerr;
    _Srdcascade = 0;
    _Frdout = rdout;
    _Frderr = rderr;
    _Fdata3b = data3b;
    _Fdata5b = data5b;
    _Fis_111000 = is_111000;
    _Fis_000111 = is_000111;
    _Fis_1100 = is_1100;
    _Fis_0011 = is_0011;
    _Frd6_neg = rd6_neg;
    _Frd6_pos = rd6_pos;
    _Frd4_neg = rd4_neg;
    _Frd4_pos = rd4_pos;
    _Ssum_cba = 0;
    _Ssum_ied = 0;
    _Ssum_jhgf = 0;
    _SK28minus = 0;
    _Sis_idle = 0;
    _Fdata3b_pre1 = data3b_pre1;
    _Fdata5b_pre1 = data5b_pre1;
    _Fvalid_pre1 = valid_pre1;
    _Fkout_pre1 = kout_pre1;
    _Fkerr_pre1 = kerr_pre1;
    _Fenable_d1 = enable_d1;

// mainline code
    begin // *** put code block here *** 
        begin 
            _Fdata3b = data3b_pre1;
            _Fdata5b = data5b_pre1;
            _Fvalid = valid_pre1;
            _Fkout = kout_pre1;
            _Fkerr = kerr_pre1;
            _Fenable_d1 = ena;
            _SK28minus = (datain[5:2] == 4'b0000);// K28.x-
            //      ones <- (datain[9] + datain[8] + datain[7] + datain[6] + datain[5] + 
            //               datain[4] + datain[3] + datain[2] + datain[1] + datain[0]);  
            _Ssum_cba = datain[2] + datain[1] + datain[0];// 2 LEs
            _Ssum_ied = datain[5] + datain[4] + datain[3];// 2 LEs
            _Ssum_jhgf = datain[9] + datain[8] + datain[7] + datain[6];
            _Fis_111000 = ((sum_ied == 2'd3) && (sum_cba == 2'd0));// 1 LE
            _Fis_000111 = ((sum_ied == 2'd0) && (sum_cba == 2'd3));// 1 LE
            _Frd6_pos = (((sum_ied == 2'd3) && (sum_cba != 2'd0)) || ((sum_ied == 2'd2) && ((sum_cba
            == 2'd2) || (sum_cba == 2'd3))) || ((sum_ied == 2'd1) && (sum_cba
            == 2'd3)));// 1 LE
            _Frd6_neg = (((sum_ied == 2'd0) && (sum_cba != 2'd3)) || ((sum_ied == 2'd1) && ((sum_cba
            == 2'd0) || (sum_cba == 2'd1))) || ((sum_ied == 2'd2) && (sum_cba
            == 2'd0)));// 1 LE
            _Fis_1100 = (datain[9:6] == 4'b1100);// 1 LE
            _Fis_0011 = (datain[9:6] == 4'b0011);// 1 LE
            _Frd4_pos = (sum_jhgf > 3'd2);// 1 LE
            _Frd4_neg = (sum_jhgf < 3'd2);// 1 LE
            _Srdcascade = rd_internal;// default value
            if (rd6_pos | is_111000) begin 
                _Srdcascade = 1'b1;
            end 
            if (rd6_neg | is_000111) begin 
                _Srdcascade = 1'b0;
            end 
            if (rd4_pos | is_1100) begin 
                _Srdcascade = 1'b1;
            end 
            if (rd4_neg | is_0011) begin 
                _Srdcascade = 1'b0;
            end // Default values
            _Fvalid_pre1 = 1'b0;// When ena is not asserted.
            if (enable_d1) begin 
                _Frderr = ((rd_internal & (rd6_pos | is_000111)) || ((~ rd_internal) & (rd6_neg |
                is_111000)) || ((rd6_pos | is_111000 | ((~ rd6_neg) &
                rd_internal)) & (rd4_pos | is_0011)) || ((rd6_neg |
                is_000111 | ((~ rd6_pos) & (~ rd_internal))) & (rd4_neg
                | is_1100)));
                _Frdout = rdcascade;
            end // if ( enable_d1 )
            if (ena) begin //                          jhgf_iedcba                    jhgf_iedcba

                _Sis_idle = ((datain == 10'b1010_000011) || (datain == 10'b0101_111100));
                if (idle_del && is_idle) begin 
                    _Fvalid_pre1 = 1'b0;
                end 
                else
                begin 
                    _Fvalid_pre1 = 1'b1;
                end 
                case ({datain[6], datain[7], datain[8], datain[9]})
                    4'b0000:
                        _Fdata3b_pre1 = 3'bxxx;// not used
                    4'b0001:
                        _Fdata3b_pre1 = 3'b111;// Dx.7
                    4'b0010:
                        _Fdata3b_pre1 = 3'b100;
                    4'b0011:
                        _Fdata3b_pre1 = 3'b011;
                    4'b0100:
                        _Fdata3b_pre1 = 3'b000;// Dx.0
                    4'b0101:
                        _Fdata3b_pre1 = {3 {K28minus}} ^ 3'b010;
                    4'b0110:
                        _Fdata3b_pre1 = {3 {K28minus}} ^ 3'b110;
                    4'b0111:
                        _Fdata3b_pre1 = 3'b111;// Special D{17|18|20}.7 Kx.7
                    4'b1000:
                        _Fdata3b_pre1 = 3'b111;// Special D{11|13|14}.7 Kx.7
                    4'b1001:
                        _Fdata3b_pre1 = {3 {K28minus}} ^ 3'b001;
                    4'b1010:
                        _Fdata3b_pre1 = {3 {K28minus}} ^ 3'b101;
                    4'b1011:
                        _Fdata3b_pre1 = 3'b000;// Dx.0
                    4'b1100:
                        _Fdata3b_pre1 = 3'b011;
                    4'b1101:
                        _Fdata3b_pre1 = 3'b100;
                    4'b1110:
                        _Fdata3b_pre1 = 3'b111;// Dx.7
                    4'b1111:
                        _Fdata3b_pre1 = 3'bxxx;// not used
                endcase
                case ({datain[0], datain[1], datain[2], datain[3], datain[4], datain[5]})
                    6'b000000:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    6'b000001:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    6'b000010:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    6'b000011:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    6'b000100:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    5:
                        _Fdata5b_pre1 = 'b10111;
                    6:
                        _Fdata5b_pre1 = 'b01000;
                    7:
                        _Fdata5b_pre1 = 'b00111;
                    6'b001000:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    9:
                        _Fdata5b_pre1 = 'b11011;
                    10:
                        _Fdata5b_pre1 = 'b00100;
                    11:
                        _Fdata5b_pre1 = 'b10100;
                    12:
                        _Fdata5b_pre1 = 'b11000;
                    13:
                        _Fdata5b_pre1 = 'b01100;
                    14:
                        _Fdata5b_pre1 = 'b11100;
                    6'b001111:
                        _Fdata5b_pre1 = 'b11100;// K28
                    6'b010000:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    17:
                        _Fdata5b_pre1 = 'b11101;
                    18:
                        _Fdata5b_pre1 = 'b00010;
                    19:
                        _Fdata5b_pre1 = 'b10010;
                    20:
                        _Fdata5b_pre1 = 'b11111;
                    21:
                        _Fdata5b_pre1 = 'b01010;
                    22:
                        _Fdata5b_pre1 = 'b11010;
                    23:
                        _Fdata5b_pre1 = 'b01111;
                    24:
                        _Fdata5b_pre1 = 'b00000;// D0
                    25:
                        _Fdata5b_pre1 = 'b00110;
                    26:
                        _Fdata5b_pre1 = 'b10110;
                    27:
                        _Fdata5b_pre1 = 'b10000;
                    28:
                        _Fdata5b_pre1 = 'b01110;
                    29:
                        _Fdata5b_pre1 = 'b00001;
                    30:
                        _Fdata5b_pre1 = 'b11110;
                    6'b011111:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    6'b100000:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    33:
                        _Fdata5b_pre1 = 'b11110;
                    34:
                        _Fdata5b_pre1 = 'b00001;
                    35:
                        _Fdata5b_pre1 = 'b10001;
                    36:
                        _Fdata5b_pre1 = 'b10000;
                    37:
                        _Fdata5b_pre1 = 'b01001;
                    38:
                        _Fdata5b_pre1 = 'b11001;
                    39:
                        _Fdata5b_pre1 = 'b00000;// D0
                    40:
                        _Fdata5b_pre1 = 'b01111;
                    41:
                        _Fdata5b_pre1 = 'b00101;
                    42:
                        _Fdata5b_pre1 = 'b10101;
                    43:
                        _Fdata5b_pre1 = 'b11111;
                    44:
                        _Fdata5b_pre1 = 'b01101;
                    45:
                        _Fdata5b_pre1 = 'b00010;
                    46:
                        _Fdata5b_pre1 = 'b11101;
                    6'b101111:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    6'b110000:
                        _Fdata5b_pre1 = 'b11100;// K28
                    49:
                        _Fdata5b_pre1 = 'b00011;
                    50:
                        _Fdata5b_pre1 = 'b10011;
                    51:
                        _Fdata5b_pre1 = 'b11000;
                    52:
                        _Fdata5b_pre1 = 'b01011;
                    53:
                        _Fdata5b_pre1 = 'b00100;
                    54:
                        _Fdata5b_pre1 = 'b11011;
                    6'b110111:
                        _Fdata5b_pre1 = 'bxxxxx;// not defined
                    56:
                        _Fdata5b_pre1 = 'b00111;
                    57:
                        _Fdata5b_pre1 = 'b01000;
                    58:
                        _Fdata5b_pre1 = 5'b10111;//D23 ,  K23
                    6'b111011:
                        _Fdata5b_pre1 = 5'bxxxxx;// not defined
                    6'b111100:
                        _Fdata5b_pre1 = 5'bxxxxx;// not defined
                    6'b111101:
                        _Fdata5b_pre1 = 5'bxxxxx;// not defined
                    6'b111110:
                        _Fdata5b_pre1 = 5'bxxxxx;// not defined
                    6'b111111:
                        _Fdata5b_pre1 = 5'bxxxxx;// not defined
                endcase
//                 iedc        
                if
                ((datain[5:2] == 4'b1111) || (datain[5:2] == 4'b0000) || ({datain[9:6],
                datain[4]} == 6'b0001__1) || ({datain[9:6], datain[4]}
                == 6'b1110__0) // Kx.7- jhgf_iedcba == 1110_x0xxxx
) begin 
                    _Fkout_pre1 = 1'b1;
                end 
                else
                begin 
                    _Fkout_pre1 = 1'b0;
                end 
                case (datain)
                    10'b0000000000:
                        _Fkerr_pre1 = 1;
                    10'b0000000001:
                        _Fkerr_pre1 = 1;
                    10'b0000000010:
                        _Fkerr_pre1 = 1;
                    10'b0000000011:
                        _Fkerr_pre1 = 1;
                    10'b0000000100:
                        _Fkerr_pre1 = 1;
                    10'b0000000101:
                        _Fkerr_pre1 = 1;
                    10'b0000000110:
                        _Fkerr_pre1 = 1;
                    10'b0000000111:
                        _Fkerr_pre1 = 1;
                    10'b0000001000:
                        _Fkerr_pre1 = 1;
                    10'b0000001001:
                        _Fkerr_pre1 = 1;
                    10'b0000001010:
                        _Fkerr_pre1 = 1;
                    10'b0000001011:
                        _Fkerr_pre1 = 1;
                    10'b0000001100:
                        _Fkerr_pre1 = 1;
                    10'b0000001101:
                        _Fkerr_pre1 = 1;
                    10'b0000001110:
                        _Fkerr_pre1 = 1;
                    10'b0000001111:
                        _Fkerr_pre1 = 1;
                    10'b0000010000:
                        _Fkerr_pre1 = 1;
                    10'b0000010001:
                        _Fkerr_pre1 = 1;
                    10'b0000010010:
                        _Fkerr_pre1 = 1;
                    10'b0000010011:
                        _Fkerr_pre1 = 1;
                    10'b0000010100:
                        _Fkerr_pre1 = 1;
                    10'b0000010101:
                        _Fkerr_pre1 = 1;
                    10'b0000010110:
                        _Fkerr_pre1 = 1;
                    10'b0000010111:
                        _Fkerr_pre1 = 1;
                    10'b0000011000:
                        _Fkerr_pre1 = 1;
                    10'b0000011001:
                        _Fkerr_pre1 = 1;
                    10'b0000011010:
                        _Fkerr_pre1 = 1;
                    10'b0000011011:
                        _Fkerr_pre1 = 1;
                    10'b0000011100:
                        _Fkerr_pre1 = 1;
                    10'b0000011101:
                        _Fkerr_pre1 = 1;
                    10'b0000011110:
                        _Fkerr_pre1 = 1;
                    10'b0000011111:
                        _Fkerr_pre1 = 1;
                    10'b0000100000:
                        _Fkerr_pre1 = 1;
                    10'b0000100001:
                        _Fkerr_pre1 = 1;
                    10'b0000100010:
                        _Fkerr_pre1 = 1;
                    10'b0000100011:
                        _Fkerr_pre1 = 1;
                    10'b0000100100:
                        _Fkerr_pre1 = 1;
                    10'b0000100101:
                        _Fkerr_pre1 = 1;
                    10'b0000100110:
                        _Fkerr_pre1 = 1;
                    10'b0000100111:
                        _Fkerr_pre1 = 1;
                    10'b0000101000:
                        _Fkerr_pre1 = 1;
                    10'b0000101001:
                        _Fkerr_pre1 = 1;
                    10'b0000101010:
                        _Fkerr_pre1 = 1;
                    10'b0000101011:
                        _Fkerr_pre1 = 1;
                    10'b0000101100:
                        _Fkerr_pre1 = 1;
                    10'b0000101101:
                        _Fkerr_pre1 = 1;
                    10'b0000101110:
                        _Fkerr_pre1 = 1;
                    10'b0000101111:
                        _Fkerr_pre1 = 1;
                    10'b0000110000:
                        _Fkerr_pre1 = 1;
                    10'b0000110001:
                        _Fkerr_pre1 = 1;
                    10'b0000110010:
                        _Fkerr_pre1 = 1;
                    10'b0000110011:
                        _Fkerr_pre1 = 1;
                    10'b0000110100:
                        _Fkerr_pre1 = 1;
                    10'b0000110101:
                        _Fkerr_pre1 = 1;
                    10'b0000110110:
                        _Fkerr_pre1 = 1;
                    10'b0000110111:
                        _Fkerr_pre1 = 1;
                    10'b0000111000:
                        _Fkerr_pre1 = 1;
                    10'b0000111001:
                        _Fkerr_pre1 = 1;
                    10'b0000111010:
                        _Fkerr_pre1 = 1;
                    10'b0000111011:
                        _Fkerr_pre1 = 1;
                    10'b0000111100:
                        _Fkerr_pre1 = 1;
                    10'b0000111101:
                        _Fkerr_pre1 = 1;
                    10'b0000111110:
                        _Fkerr_pre1 = 1;
                    10'b0000111111:
                        _Fkerr_pre1 = 1;
                    10'b0001000000:
                        _Fkerr_pre1 = 1;
                    10'b0001000001:
                        _Fkerr_pre1 = 1;
                    10'b0001000010:
                        _Fkerr_pre1 = 1;
                    10'b0001000011:
                        _Fkerr_pre1 = 1;
                    10'b0001000100:
                        _Fkerr_pre1 = 1;
                    10'b0001000101:
                        _Fkerr_pre1 = 1;
                    10'b0001000110:
                        _Fkerr_pre1 = 1;
                    10'b0001000111:
                        _Fkerr_pre1 = 1;
                    10'b0001001000:
                        _Fkerr_pre1 = 1;
                    10'b0001001001:
                        _Fkerr_pre1 = 1;
                    10'b0001001010:
                        _Fkerr_pre1 = 1;
                    10'b0001001100:
                        _Fkerr_pre1 = 1;
                    10'b0001001111:
                        _Fkerr_pre1 = 1;
                    10'b0001010000:
                        _Fkerr_pre1 = 1;
                    10'b0001010001:
                        _Fkerr_pre1 = 1;
                    10'b0001010010:
                        _Fkerr_pre1 = 1;
                    10'b0001010011:
                        _Fkerr_pre1 = 1;
                    10'b0001010100:
                        _Fkerr_pre1 = 1;
                    10'b0001010101:
                        _Fkerr_pre1 = 1;
                    10'b0001010110:
                        _Fkerr_pre1 = 1;
                    10'b0001011000:
                        _Fkerr_pre1 = 1;
                    10'b0001011001:
                        _Fkerr_pre1 = 1;
                    10'b0001011010:
                        _Fkerr_pre1 = 1;
                    10'b0001011100:
                        _Fkerr_pre1 = 1;
                    10'b0001011111:
                        _Fkerr_pre1 = 1;
                    10'b0001100000:
                        _Fkerr_pre1 = 1;
                    10'b0001100001:
                        _Fkerr_pre1 = 1;
                    10'b0001100010:
                        _Fkerr_pre1 = 1;
                    10'b0001100011:
                        _Fkerr_pre1 = 1;
                    10'b0001100100:
                        _Fkerr_pre1 = 1;
                    10'b0001100101:
                        _Fkerr_pre1 = 1;
                    10'b0001100110:
                        _Fkerr_pre1 = 1;
                    10'b0001100111:
                        _Fkerr_pre1 = 1;
                    10'b0001101000:
                        _Fkerr_pre1 = 1;
                    10'b0001101001:
                        _Fkerr_pre1 = 1;
                    10'b0001101010:
                        _Fkerr_pre1 = 1;
                    10'b0001101011:
                        _Fkerr_pre1 = 1;
                    10'b0001101100:
                        _Fkerr_pre1 = 1;
                    10'b0001101101:
                        _Fkerr_pre1 = 1;
                    10'b0001101110:
                        _Fkerr_pre1 = 1;
                    10'b0001101111:
                        _Fkerr_pre1 = 1;
                    10'b0001110000:
                        _Fkerr_pre1 = 1;
                    10'b0001110001:
                        _Fkerr_pre1 = 1;
                    10'b0001110010:
                        _Fkerr_pre1 = 1;
                    10'b0001110011:
                        _Fkerr_pre1 = 1;
                    10'b0001110100:
                        _Fkerr_pre1 = 1;
                    10'b0001110101:
                        _Fkerr_pre1 = 1;
                    10'b0001110110:
                        _Fkerr_pre1 = 1;
                    10'b0001110111:
                        _Fkerr_pre1 = 1;
                    10'b0001111000:
                        _Fkerr_pre1 = 1;
                    10'b0001111001:
                        _Fkerr_pre1 = 1;
                    10'b0001111010:
                        _Fkerr_pre1 = 1;
                    10'b0001111011:
                        _Fkerr_pre1 = 1;
                    10'b0001111101:
                        _Fkerr_pre1 = 1;
                    10'b0001111110:
                        _Fkerr_pre1 = 1;
                    10'b0001111111:
                        _Fkerr_pre1 = 1;
                    10'b0010000000:
                        _Fkerr_pre1 = 1;
                    10'b0010000001:
                        _Fkerr_pre1 = 1;
                    10'b0010000010:
                        _Fkerr_pre1 = 1;
                    10'b0010000011:
                        _Fkerr_pre1 = 1;
                    10'b0010000100:
                        _Fkerr_pre1 = 1;
                    10'b0010000101:
                        _Fkerr_pre1 = 1;
                    10'b0010000110:
                        _Fkerr_pre1 = 1;
                    10'b0010000111:
                        _Fkerr_pre1 = 1;
                    10'b0010001000:
                        _Fkerr_pre1 = 1;
                    10'b0010001001:
                        _Fkerr_pre1 = 1;
                    10'b0010001010:
                        _Fkerr_pre1 = 1;
                    10'b0010001100:
                        _Fkerr_pre1 = 1;
                    10'b0010001111:
                        _Fkerr_pre1 = 1;
                    10'b0010010000:
                        _Fkerr_pre1 = 1;
                    10'b0010010001:
                        _Fkerr_pre1 = 1;
                    10'b0010010010:
                        _Fkerr_pre1 = 1;
                    10'b0010010100:
                        _Fkerr_pre1 = 1;
                    10'b0010011000:
                        _Fkerr_pre1 = 1;
                    10'b0010011111:
                        _Fkerr_pre1 = 1;
                    10'b0010100000:
                        _Fkerr_pre1 = 1;
                    10'b0010100001:
                        _Fkerr_pre1 = 1;
                    10'b0010100010:
                        _Fkerr_pre1 = 1;
                    10'b0010100100:
                        _Fkerr_pre1 = 1;
                    10'b0010101000:
                        _Fkerr_pre1 = 1;
                    10'b0010101111:
                        _Fkerr_pre1 = 1;
                    10'b0010110000:
                        _Fkerr_pre1 = 1;
                    10'b0010110111:
                        _Fkerr_pre1 = 1;
                    10'b0010111011:
                        _Fkerr_pre1 = 1;
                    10'b0010111101:
                        _Fkerr_pre1 = 1;
                    10'b0010111110:
                        _Fkerr_pre1 = 1;
                    10'b0010111111:
                        _Fkerr_pre1 = 1;
                    10'b0011000000:
                        _Fkerr_pre1 = 1;
                    10'b0011000001:
                        _Fkerr_pre1 = 1;
                    10'b0011000010:
                        _Fkerr_pre1 = 1;
                    10'b0011000100:
                        _Fkerr_pre1 = 1;
                    10'b0011001000:
                        _Fkerr_pre1 = 1;
                    10'b0011001111:
                        _Fkerr_pre1 = 1;
                    10'b0011010000:
                        _Fkerr_pre1 = 1;
                    10'b0011010111:
                        _Fkerr_pre1 = 1;
                    10'b0011011011:
                        _Fkerr_pre1 = 1;
                    10'b0011011101:
                        _Fkerr_pre1 = 1;
                    10'b0011011110:
                        _Fkerr_pre1 = 1;
                    10'b0011011111:
                        _Fkerr_pre1 = 1;
                    10'b0011100000:
                        _Fkerr_pre1 = 1;
                    10'b0011100111:
                        _Fkerr_pre1 = 1;
                    10'b0011101011:
                        _Fkerr_pre1 = 1;
                    10'b0011101101:
                        _Fkerr_pre1 = 1;
                    10'b0011101110:
                        _Fkerr_pre1 = 1;
                    10'b0011101111:
                        _Fkerr_pre1 = 1;
                    10'b0011110000:
                        _Fkerr_pre1 = 1;
                    10'b0011110011:
                        _Fkerr_pre1 = 1;
                    10'b0011110101:
                        _Fkerr_pre1 = 1;
                    10'b0011110110:
                        _Fkerr_pre1 = 1;
                    10'b0011110111:
                        _Fkerr_pre1 = 1;
                    10'b0011111000:
                        _Fkerr_pre1 = 1;
                    10'b0011111001:
                        _Fkerr_pre1 = 1;
                    10'b0011111010:
                        _Fkerr_pre1 = 1;
                    10'b0011111011:
                        _Fkerr_pre1 = 1;
                    10'b0011111100:
                        _Fkerr_pre1 = 1;
                    10'b0011111101:
                        _Fkerr_pre1 = 1;
                    10'b0011111110:
                        _Fkerr_pre1 = 1;
                    10'b0011111111:
                        _Fkerr_pre1 = 1;
                    10'b0100000000:
                        _Fkerr_pre1 = 1;
                    10'b0100000001:
                        _Fkerr_pre1 = 1;
                    10'b0100000010:
                        _Fkerr_pre1 = 1;
                    10'b0100000011:
                        _Fkerr_pre1 = 1;
                    10'b0100000100:
                        _Fkerr_pre1 = 1;
                    10'b0100000101:
                        _Fkerr_pre1 = 1;
                    10'b0100000110:
                        _Fkerr_pre1 = 1;
                    10'b0100000111:
                        _Fkerr_pre1 = 1;
                    10'b0100001000:
                        _Fkerr_pre1 = 1;
                    10'b0100001001:
                        _Fkerr_pre1 = 1;
                    10'b0100001010:
                        _Fkerr_pre1 = 1;
                    10'b0100001100:
                        _Fkerr_pre1 = 1;
                    10'b0100001111:
                        _Fkerr_pre1 = 1;
                    10'b0100010000:
                        _Fkerr_pre1 = 1;
                    10'b0100010001:
                        _Fkerr_pre1 = 1;
                    10'b0100010010:
                        _Fkerr_pre1 = 1;
                    10'b0100010100:
                        _Fkerr_pre1 = 1;
                    10'b0100011000:
                        _Fkerr_pre1 = 1;
                    10'b0100011111:
                        _Fkerr_pre1 = 1;
                    10'b0100100000:
                        _Fkerr_pre1 = 1;
                    10'b0100100001:
                        _Fkerr_pre1 = 1;
                    10'b0100100010:
                        _Fkerr_pre1 = 1;
                    10'b0100100100:
                        _Fkerr_pre1 = 1;
                    10'b0100101000:
                        _Fkerr_pre1 = 1;
                    10'b0100101111:
                        _Fkerr_pre1 = 1;
                    10'b0100110000:
                        _Fkerr_pre1 = 1;
                    10'b0100110111:
                        _Fkerr_pre1 = 1;
                    10'b0100111011:
                        _Fkerr_pre1 = 1;
                    10'b0100111101:
                        _Fkerr_pre1 = 1;
                    10'b0100111110:
                        _Fkerr_pre1 = 1;
                    10'b0100111111:
                        _Fkerr_pre1 = 1;
                    10'b0101000000:
                        _Fkerr_pre1 = 1;
                    10'b0101000001:
                        _Fkerr_pre1 = 1;
                    10'b0101000010:
                        _Fkerr_pre1 = 1;
                    10'b0101000100:
                        _Fkerr_pre1 = 1;
                    10'b0101001000:
                        _Fkerr_pre1 = 1;
                    10'b0101001111:
                        _Fkerr_pre1 = 1;
                    10'b0101010000:
                        _Fkerr_pre1 = 1;
                    10'b0101011111:
                        _Fkerr_pre1 = 1;
                    10'b0101100000:
                        _Fkerr_pre1 = 1;
                    10'b0101101111:
                        _Fkerr_pre1 = 1;
                    10'b0101110000:
                        _Fkerr_pre1 = 1;
                    10'b0101110111:
                        _Fkerr_pre1 = 1;
                    10'b0101111011:
                        _Fkerr_pre1 = 1;
                    10'b0101111101:
                        _Fkerr_pre1 = 1;
                    10'b0101111110:
                        _Fkerr_pre1 = 1;
                    10'b0101111111:
                        _Fkerr_pre1 = 1;
                    10'b0110000000:
                        _Fkerr_pre1 = 1;
                    10'b0110000001:
                        _Fkerr_pre1 = 1;
                    10'b0110000010:
                        _Fkerr_pre1 = 1;
                    10'b0110000100:
                        _Fkerr_pre1 = 1;
                    10'b0110001000:
                        _Fkerr_pre1 = 1;
                    10'b0110001111:
                        _Fkerr_pre1 = 1;
                    10'b0110010000:
                        _Fkerr_pre1 = 1;
                    10'b0110011111:
                        _Fkerr_pre1 = 1;
                    10'b0110100000:
                        _Fkerr_pre1 = 1;
                    10'b0110101111:
                        _Fkerr_pre1 = 1;
                    10'b0110110000:
                        _Fkerr_pre1 = 1;
                    10'b0110110111:
                        _Fkerr_pre1 = 1;
                    10'b0110111011:
                        _Fkerr_pre1 = 1;
                    10'b0110111101:
                        _Fkerr_pre1 = 1;
                    10'b0110111110:
                        _Fkerr_pre1 = 1;
                    10'b0110111111:
                        _Fkerr_pre1 = 1;
                    10'b0111000000:
                        _Fkerr_pre1 = 1;
                    10'b0111000001:
                        _Fkerr_pre1 = 1;
                    10'b0111000010:
                        _Fkerr_pre1 = 1;
                    10'b0111000011:
                        _Fkerr_pre1 = 1;
                    10'b0111000100:
                        _Fkerr_pre1 = 1;
                    10'b0111001000:
                        _Fkerr_pre1 = 1;
                    10'b0111001111:
                        _Fkerr_pre1 = 1;
                    10'b0111010000:
                        _Fkerr_pre1 = 1;
                    10'b0111010111:
                        _Fkerr_pre1 = 1;
                    10'b0111011011:
                        _Fkerr_pre1 = 1;
                    10'b0111011101:
                        _Fkerr_pre1 = 1;
                    10'b0111011110:
                        _Fkerr_pre1 = 1;
                    10'b0111011111:
                        _Fkerr_pre1 = 1;
                    10'b0111100000:
                        _Fkerr_pre1 = 1;
                    10'b0111100111:
                        _Fkerr_pre1 = 1;
                    10'b0111101011:
                        _Fkerr_pre1 = 1;
                    10'b0111101101:
                        _Fkerr_pre1 = 1;
                    10'b0111101110:
                        _Fkerr_pre1 = 1;
                    10'b0111101111:
                        _Fkerr_pre1 = 1;
                    10'b0111110000:
                        _Fkerr_pre1 = 1;
                    10'b0111110001:
                        _Fkerr_pre1 = 1;
                    10'b0111110010:
                        _Fkerr_pre1 = 1;
                    10'b0111110011:
                        _Fkerr_pre1 = 1;
                    10'b0111110100:
                        _Fkerr_pre1 = 1;
                    10'b0111110101:
                        _Fkerr_pre1 = 1;
                    10'b0111110110:
                        _Fkerr_pre1 = 1;
                    10'b0111110111:
                        _Fkerr_pre1 = 1;
                    10'b0111111000:
                        _Fkerr_pre1 = 1;
                    10'b0111111001:
                        _Fkerr_pre1 = 1;
                    10'b0111111010:
                        _Fkerr_pre1 = 1;
                    10'b0111111011:
                        _Fkerr_pre1 = 1;
                    10'b0111111100:
                        _Fkerr_pre1 = 1;
                    10'b0111111101:
                        _Fkerr_pre1 = 1;
                    10'b0111111110:
                        _Fkerr_pre1 = 1;
                    10'b0111111111:
                        _Fkerr_pre1 = 1;
                    10'b1000000000:
                        _Fkerr_pre1 = 1;
                    10'b1000000001:
                        _Fkerr_pre1 = 1;
                    10'b1000000010:
                        _Fkerr_pre1 = 1;
                    10'b1000000011:
                        _Fkerr_pre1 = 1;
                    10'b1000000100:
                        _Fkerr_pre1 = 1;
                    10'b1000000101:
                        _Fkerr_pre1 = 1;
                    10'b1000000110:
                        _Fkerr_pre1 = 1;
                    10'b1000000111:
                        _Fkerr_pre1 = 1;
                    10'b1000001000:
                        _Fkerr_pre1 = 1;
                    10'b1000001001:
                        _Fkerr_pre1 = 1;
                    10'b1000001010:
                        _Fkerr_pre1 = 1;
                    10'b1000001011:
                        _Fkerr_pre1 = 1;
                    10'b1000001100:
                        _Fkerr_pre1 = 1;
                    10'b1000001101:
                        _Fkerr_pre1 = 1;
                    10'b1000001110:
                        _Fkerr_pre1 = 1;
                    10'b1000001111:
                        _Fkerr_pre1 = 1;
                    10'b1000010000:
                        _Fkerr_pre1 = 1;
                    10'b1000010001:
                        _Fkerr_pre1 = 1;
                    10'b1000010010:
                        _Fkerr_pre1 = 1;
                    10'b1000010100:
                        _Fkerr_pre1 = 1;
                    10'b1000011000:
                        _Fkerr_pre1 = 1;
                    10'b1000011111:
                        _Fkerr_pre1 = 1;
                    10'b1000100000:
                        _Fkerr_pre1 = 1;
                    10'b1000100001:
                        _Fkerr_pre1 = 1;
                    10'b1000100010:
                        _Fkerr_pre1 = 1;
                    10'b1000100100:
                        _Fkerr_pre1 = 1;
                    10'b1000101000:
                        _Fkerr_pre1 = 1;
                    10'b1000101111:
                        _Fkerr_pre1 = 1;
                    10'b1000110000:
                        _Fkerr_pre1 = 1;
                    10'b1000110111:
                        _Fkerr_pre1 = 1;
                    10'b1000111011:
                        _Fkerr_pre1 = 1;
                    10'b1000111100:
                        _Fkerr_pre1 = 1;
                    10'b1000111101:
                        _Fkerr_pre1 = 1;
                    10'b1000111110:
                        _Fkerr_pre1 = 1;
                    10'b1000111111:
                        _Fkerr_pre1 = 1;
                    10'b1001000000:
                        _Fkerr_pre1 = 1;
                    10'b1001000001:
                        _Fkerr_pre1 = 1;
                    10'b1001000010:
                        _Fkerr_pre1 = 1;
                    10'b1001000100:
                        _Fkerr_pre1 = 1;
                    10'b1001001000:
                        _Fkerr_pre1 = 1;
                    10'b1001001111:
                        _Fkerr_pre1 = 1;
                    10'b1001010000:
                        _Fkerr_pre1 = 1;
                    10'b1001011111:
                        _Fkerr_pre1 = 1;
                    10'b1001100000:
                        _Fkerr_pre1 = 1;
                    10'b1001101111:
                        _Fkerr_pre1 = 1;
                    10'b1001110000:
                        _Fkerr_pre1 = 1;
                    10'b1001110111:
                        _Fkerr_pre1 = 1;
                    10'b1001111011:
                        _Fkerr_pre1 = 1;
                    10'b1001111101:
                        _Fkerr_pre1 = 1;
                    10'b1001111110:
                        _Fkerr_pre1 = 1;
                    10'b1001111111:
                        _Fkerr_pre1 = 1;
                    10'b1010000000:
                        _Fkerr_pre1 = 1;
                    10'b1010000001:
                        _Fkerr_pre1 = 1;
                    10'b1010000010:
                        _Fkerr_pre1 = 1;
                    10'b1010000100:
                        _Fkerr_pre1 = 1;
                    10'b1010001000:
                        _Fkerr_pre1 = 1;
                    10'b1010001111:
                        _Fkerr_pre1 = 1;
                    10'b1010010000:
                        _Fkerr_pre1 = 1;
                    10'b1010011111:
                        _Fkerr_pre1 = 1;
                    10'b1010100000:
                        _Fkerr_pre1 = 1;
                    10'b1010101111:
                        _Fkerr_pre1 = 1;
                    10'b1010110000:
                        _Fkerr_pre1 = 1;
                    10'b1010110111:
                        _Fkerr_pre1 = 1;
                    10'b1010111011:
                        _Fkerr_pre1 = 1;
                    10'b1010111101:
                        _Fkerr_pre1 = 1;
                    10'b1010111110:
                        _Fkerr_pre1 = 1;
                    10'b1010111111:
                        _Fkerr_pre1 = 1;
                    10'b1011000000:
                        _Fkerr_pre1 = 1;
                    10'b1011000001:
                        _Fkerr_pre1 = 1;
                    10'b1011000010:
                        _Fkerr_pre1 = 1;
                    10'b1011000100:
                        _Fkerr_pre1 = 1;
                    10'b1011001000:
                        _Fkerr_pre1 = 1;
                    10'b1011001111:
                        _Fkerr_pre1 = 1;
                    10'b1011010000:
                        _Fkerr_pre1 = 1;
                    10'b1011010111:
                        _Fkerr_pre1 = 1;
                    10'b1011011011:
                        _Fkerr_pre1 = 1;
                    10'b1011011101:
                        _Fkerr_pre1 = 1;
                    10'b1011011110:
                        _Fkerr_pre1 = 1;
                    10'b1011011111:
                        _Fkerr_pre1 = 1;
                    10'b1011100000:
                        _Fkerr_pre1 = 1;
                    10'b1011100111:
                        _Fkerr_pre1 = 1;
                    10'b1011101011:
                        _Fkerr_pre1 = 1;
                    10'b1011101101:
                        _Fkerr_pre1 = 1;
                    10'b1011101110:
                        _Fkerr_pre1 = 1;
                    10'b1011101111:
                        _Fkerr_pre1 = 1;
                    10'b1011110000:
                        _Fkerr_pre1 = 1;
                    10'b1011110011:
                        _Fkerr_pre1 = 1;
                    10'b1011110101:
                        _Fkerr_pre1 = 1;
                    10'b1011110110:
                        _Fkerr_pre1 = 1;
                    10'b1011110111:
                        _Fkerr_pre1 = 1;
                    10'b1011111000:
                        _Fkerr_pre1 = 1;
                    10'b1011111001:
                        _Fkerr_pre1 = 1;
                    10'b1011111010:
                        _Fkerr_pre1 = 1;
                    10'b1011111011:
                        _Fkerr_pre1 = 1;
                    10'b1011111100:
                        _Fkerr_pre1 = 1;
                    10'b1011111101:
                        _Fkerr_pre1 = 1;
                    10'b1011111110:
                        _Fkerr_pre1 = 1;
                    10'b1011111111:
                        _Fkerr_pre1 = 1;
                    10'b1100000000:
                        _Fkerr_pre1 = 1;
                    10'b1100000001:
                        _Fkerr_pre1 = 1;
                    10'b1100000010:
                        _Fkerr_pre1 = 1;
                    10'b1100000011:
                        _Fkerr_pre1 = 1;
                    10'b1100000100:
                        _Fkerr_pre1 = 1;
                    10'b1100000101:
                        _Fkerr_pre1 = 1;
                    10'b1100000110:
                        _Fkerr_pre1 = 1;
                    10'b1100000111:
                        _Fkerr_pre1 = 1;
                    10'b1100001000:
                        _Fkerr_pre1 = 1;
                    10'b1100001001:
                        _Fkerr_pre1 = 1;
                    10'b1100001010:
                        _Fkerr_pre1 = 1;
                    10'b1100001100:
                        _Fkerr_pre1 = 1;
                    10'b1100001111:
                        _Fkerr_pre1 = 1;
                    10'b1100010000:
                        _Fkerr_pre1 = 1;
                    10'b1100010001:
                        _Fkerr_pre1 = 1;
                    10'b1100010010:
                        _Fkerr_pre1 = 1;
                    10'b1100010100:
                        _Fkerr_pre1 = 1;
                    10'b1100011000:
                        _Fkerr_pre1 = 1;
                    10'b1100011111:
                        _Fkerr_pre1 = 1;
                    10'b1100100000:
                        _Fkerr_pre1 = 1;
                    10'b1100100001:
                        _Fkerr_pre1 = 1;
                    10'b1100100010:
                        _Fkerr_pre1 = 1;
                    10'b1100100100:
                        _Fkerr_pre1 = 1;
                    10'b1100101000:
                        _Fkerr_pre1 = 1;
                    10'b1100101111:
                        _Fkerr_pre1 = 1;
                    10'b1100110000:
                        _Fkerr_pre1 = 1;
                    10'b1100110111:
                        _Fkerr_pre1 = 1;
                    10'b1100111011:
                        _Fkerr_pre1 = 1;
                    10'b1100111101:
                        _Fkerr_pre1 = 1;
                    10'b1100111110:
                        _Fkerr_pre1 = 1;
                    10'b1100111111:
                        _Fkerr_pre1 = 1;
                    10'b1101000000:
                        _Fkerr_pre1 = 1;
                    10'b1101000001:
                        _Fkerr_pre1 = 1;
                    10'b1101000010:
                        _Fkerr_pre1 = 1;
                    10'b1101000100:
                        _Fkerr_pre1 = 1;
                    10'b1101001000:
                        _Fkerr_pre1 = 1;
                    10'b1101001111:
                        _Fkerr_pre1 = 1;
                    10'b1101010000:
                        _Fkerr_pre1 = 1;
                    10'b1101010111:
                        _Fkerr_pre1 = 1;
                    10'b1101011011:
                        _Fkerr_pre1 = 1;
                    10'b1101011101:
                        _Fkerr_pre1 = 1;
                    10'b1101011110:
                        _Fkerr_pre1 = 1;
                    10'b1101011111:
                        _Fkerr_pre1 = 1;
                    10'b1101100000:
                        _Fkerr_pre1 = 1;
                    10'b1101100111:
                        _Fkerr_pre1 = 1;
                    10'b1101101011:
                        _Fkerr_pre1 = 1;
                    10'b1101101101:
                        _Fkerr_pre1 = 1;
                    10'b1101101110:
                        _Fkerr_pre1 = 1;
                    10'b1101101111:
                        _Fkerr_pre1 = 1;
                    10'b1101110000:
                        _Fkerr_pre1 = 1;
                    10'b1101110011:
                        _Fkerr_pre1 = 1;
                    10'b1101110101:
                        _Fkerr_pre1 = 1;
                    10'b1101110110:
                        _Fkerr_pre1 = 1;
                    10'b1101110111:
                        _Fkerr_pre1 = 1;
                    10'b1101111000:
                        _Fkerr_pre1 = 1;
                    10'b1101111001:
                        _Fkerr_pre1 = 1;
                    10'b1101111010:
                        _Fkerr_pre1 = 1;
                    10'b1101111011:
                        _Fkerr_pre1 = 1;
                    10'b1101111100:
                        _Fkerr_pre1 = 1;
                    10'b1101111101:
                        _Fkerr_pre1 = 1;
                    10'b1101111110:
                        _Fkerr_pre1 = 1;
                    10'b1101111111:
                        _Fkerr_pre1 = 1;
                    10'b1110000000:
                        _Fkerr_pre1 = 1;
                    10'b1110000001:
                        _Fkerr_pre1 = 1;
                    10'b1110000010:
                        _Fkerr_pre1 = 1;
                    10'b1110000100:
                        _Fkerr_pre1 = 1;
                    10'b1110000101:
                        _Fkerr_pre1 = 1;
                    10'b1110000110:
                        _Fkerr_pre1 = 1;
                    10'b1110000111:
                        _Fkerr_pre1 = 1;
                    10'b1110001000:
                        _Fkerr_pre1 = 1;
                    10'b1110001001:
                        _Fkerr_pre1 = 1;
                    10'b1110001010:
                        _Fkerr_pre1 = 1;
                    10'b1110001011:
                        _Fkerr_pre1 = 1;
                    10'b1110001100:
                        _Fkerr_pre1 = 1;
                    10'b1110001101:
                        _Fkerr_pre1 = 1;
                    10'b1110001110:
                        _Fkerr_pre1 = 1;
                    10'b1110001111:
                        _Fkerr_pre1 = 1;
                    10'b1110010000:
                        _Fkerr_pre1 = 1;
                    10'b1110010001:
                        _Fkerr_pre1 = 1;
                    10'b1110010010:
                        _Fkerr_pre1 = 1;
                    10'b1110010011:
                        _Fkerr_pre1 = 1;
                    10'b1110010100:
                        _Fkerr_pre1 = 1;
                    10'b1110010101:
                        _Fkerr_pre1 = 1;
                    10'b1110010110:
                        _Fkerr_pre1 = 1;
                    10'b1110010111:
                        _Fkerr_pre1 = 1;
                    10'b1110011000:
                        _Fkerr_pre1 = 1;
                    10'b1110011001:
                        _Fkerr_pre1 = 1;
                    10'b1110011010:
                        _Fkerr_pre1 = 1;
                    10'b1110011011:
                        _Fkerr_pre1 = 1;
                    10'b1110011100:
                        _Fkerr_pre1 = 1;
                    10'b1110011101:
                        _Fkerr_pre1 = 1;
                    10'b1110011110:
                        _Fkerr_pre1 = 1;
                    10'b1110011111:
                        _Fkerr_pre1 = 1;
                    10'b1110100000:
                        _Fkerr_pre1 = 1;
                    10'b1110100011:
                        _Fkerr_pre1 = 1;
                    10'b1110100101:
                        _Fkerr_pre1 = 1;
                    10'b1110100110:
                        _Fkerr_pre1 = 1;
                    10'b1110100111:
                        _Fkerr_pre1 = 1;
                    10'b1110101001:
                        _Fkerr_pre1 = 1;
                    10'b1110101010:
                        _Fkerr_pre1 = 1;
                    10'b1110101011:
                        _Fkerr_pre1 = 1;
                    10'b1110101100:
                        _Fkerr_pre1 = 1;
                    10'b1110101101:
                        _Fkerr_pre1 = 1;
                    10'b1110101110:
                        _Fkerr_pre1 = 1;
                    10'b1110101111:
                        _Fkerr_pre1 = 1;
                    10'b1110110000:
                        _Fkerr_pre1 = 1;
                    10'b1110110011:
                        _Fkerr_pre1 = 1;
                    10'b1110110101:
                        _Fkerr_pre1 = 1;
                    10'b1110110110:
                        _Fkerr_pre1 = 1;
                    10'b1110110111:
                        _Fkerr_pre1 = 1;
                    10'b1110111000:
                        _Fkerr_pre1 = 1;
                    10'b1110111001:
                        _Fkerr_pre1 = 1;
                    10'b1110111010:
                        _Fkerr_pre1 = 1;
                    10'b1110111011:
                        _Fkerr_pre1 = 1;
                    10'b1110111100:
                        _Fkerr_pre1 = 1;
                    10'b1110111101:
                        _Fkerr_pre1 = 1;
                    10'b1110111110:
                        _Fkerr_pre1 = 1;
                    10'b1110111111:
                        _Fkerr_pre1 = 1;
                    10'b1111000000:
                        _Fkerr_pre1 = 1;
                    10'b1111000001:
                        _Fkerr_pre1 = 1;
                    10'b1111000010:
                        _Fkerr_pre1 = 1;
                    10'b1111000011:
                        _Fkerr_pre1 = 1;
                    10'b1111000100:
                        _Fkerr_pre1 = 1;
                    10'b1111000101:
                        _Fkerr_pre1 = 1;
                    10'b1111000110:
                        _Fkerr_pre1 = 1;
                    10'b1111000111:
                        _Fkerr_pre1 = 1;
                    10'b1111001000:
                        _Fkerr_pre1 = 1;
                    10'b1111001001:
                        _Fkerr_pre1 = 1;
                    10'b1111001010:
                        _Fkerr_pre1 = 1;
                    10'b1111001011:
                        _Fkerr_pre1 = 1;
                    10'b1111001100:
                        _Fkerr_pre1 = 1;
                    10'b1111001101:
                        _Fkerr_pre1 = 1;
                    10'b1111001110:
                        _Fkerr_pre1 = 1;
                    10'b1111001111:
                        _Fkerr_pre1 = 1;
                    10'b1111010000:
                        _Fkerr_pre1 = 1;
                    10'b1111010001:
                        _Fkerr_pre1 = 1;
                    10'b1111010010:
                        _Fkerr_pre1 = 1;
                    10'b1111010011:
                        _Fkerr_pre1 = 1;
                    10'b1111010100:
                        _Fkerr_pre1 = 1;
                    10'b1111010101:
                        _Fkerr_pre1 = 1;
                    10'b1111010110:
                        _Fkerr_pre1 = 1;
                    10'b1111010111:
                        _Fkerr_pre1 = 1;
                    10'b1111011000:
                        _Fkerr_pre1 = 1;
                    10'b1111011001:
                        _Fkerr_pre1 = 1;
                    10'b1111011010:
                        _Fkerr_pre1 = 1;
                    10'b1111011011:
                        _Fkerr_pre1 = 1;
                    10'b1111011100:
                        _Fkerr_pre1 = 1;
                    10'b1111011101:
                        _Fkerr_pre1 = 1;
                    10'b1111011110:
                        _Fkerr_pre1 = 1;
                    10'b1111011111:
                        _Fkerr_pre1 = 1;
                    10'b1111100000:
                        _Fkerr_pre1 = 1;
                    10'b1111100001:
                        _Fkerr_pre1 = 1;
                    10'b1111100010:
                        _Fkerr_pre1 = 1;
                    10'b1111100011:
                        _Fkerr_pre1 = 1;
                    10'b1111100100:
                        _Fkerr_pre1 = 1;
                    10'b1111100101:
                        _Fkerr_pre1 = 1;
                    10'b1111100110:
                        _Fkerr_pre1 = 1;
                    10'b1111100111:
                        _Fkerr_pre1 = 1;
                    10'b1111101000:
                        _Fkerr_pre1 = 1;
                    10'b1111101001:
                        _Fkerr_pre1 = 1;
                    10'b1111101010:
                        _Fkerr_pre1 = 1;
                    10'b1111101011:
                        _Fkerr_pre1 = 1;
                    10'b1111101100:
                        _Fkerr_pre1 = 1;
                    10'b1111101101:
                        _Fkerr_pre1 = 1;
                    10'b1111101110:
                        _Fkerr_pre1 = 1;
                    10'b1111101111:
                        _Fkerr_pre1 = 1;
                    10'b1111110000:
                        _Fkerr_pre1 = 1;
                    10'b1111110001:
                        _Fkerr_pre1 = 1;
                    10'b1111110010:
                        _Fkerr_pre1 = 1;
                    10'b1111110011:
                        _Fkerr_pre1 = 1;
                    10'b1111110100:
                        _Fkerr_pre1 = 1;
                    10'b1111110101:
                        _Fkerr_pre1 = 1;
                    10'b1111110110:
                        _Fkerr_pre1 = 1;
                    10'b1111110111:
                        _Fkerr_pre1 = 1;
                    10'b1111111000:
                        _Fkerr_pre1 = 1;
                    10'b1111111001:
                        _Fkerr_pre1 = 1;
                    10'b1111111010:
                        _Fkerr_pre1 = 1;
                    10'b1111111011:
                        _Fkerr_pre1 = 1;
                    10'b1111111100:
                        _Fkerr_pre1 = 1;
                    10'b1111111101:
                        _Fkerr_pre1 = 1;
                    10'b1111111110:
                        _Fkerr_pre1 = 1;
                    10'b1111111111:
                        _Fkerr_pre1 = 1;
                    default:
                        _Fkerr_pre1 = 1'b0;
                endcase
// case( datain )
            end // if ( ena )
            // *** end of code block *** 
        end 
    end // sequential_blocks


// update regs for combinational signals
// The non-blocking assignment causes the always block to 
// re-stimulate if the signal has changed
    rdcascade <= _Srdcascade;
    sum_cba <= _Ssum_cba;
    sum_ied <= _Ssum_ied;
    sum_jhgf <= _Ssum_jhgf;
    K28minus <= _SK28minus;
    is_idle <= _Sis_idle;
end
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        valid<=0;
        kout<=0;
        kerr<=0;
        rdout<=0;
        rderr<=0;
        data3b<=0;
        data5b<=0;
        is_111000<=0;
        is_000111<=0;
        is_1100<=0;
        is_0011<=0;
        rd6_neg<=0;
        rd6_pos<=0;
        rd4_neg<=0;
        rd4_pos<=0;
        data3b_pre1<=0;
        data5b_pre1<=0;
        valid_pre1<=0;
        kout_pre1<=0;
        kerr_pre1<=0;
        enable_d1<=0;
    end else begin
        valid<=_Fvalid;
        kout<=_Fkout;
        kerr<=_Fkerr;
        rdout<=_Frdout;
        rderr<=_Frderr;
        data3b<=_Fdata3b;
        data5b<=_Fdata5b;
        is_111000<=_Fis_111000;
        is_000111<=_Fis_000111;
        is_1100<=_Fis_1100;
        is_0011<=_Fis_0011;
        rd6_neg<=_Frd6_neg;
        rd6_pos<=_Frd6_pos;
        rd4_neg<=_Frd4_neg;
        rd4_pos<=_Frd4_pos;
        data3b_pre1<=_Fdata3b_pre1;
        data5b_pre1<=_Fdata5b_pre1;
        valid_pre1<=_Fvalid_pre1;
        kout_pre1<=_Fkout_pre1;
        kerr_pre1<=_Fkerr_pre1;
        enable_d1<=_Fenable_d1;
    end
end
endmodule
