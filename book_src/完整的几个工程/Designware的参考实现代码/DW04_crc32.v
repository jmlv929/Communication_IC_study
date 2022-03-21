
//--------------------------------------------------------------------------------------------------
//
// Title       : DW04_crc32
// Design      : crc32

// Company     :  Inc
//
//-------------------------------------------------------------------------------------------------
//
// Description : DW04_crc32 is a 32-bit Cyclic Redundancy Check (CRC) Polynomial Generator/Checker
// that provides data integrity on data streams of varying length.
//
//-------------------------------------------------------------------------------------------------

module DW04_crc32 (
	d_in,			  //Input data
	start,			  //Starts accumulation in the CRC register
	drain,			  //Drains the CRC register
	byte_time,		  //Indicates that a byte boundary has been reached,
	                  //active high. If the data width is eight bits or more,
					  //then byte_time functions as a second enable.
	enable,			  //Enable pin for all operations, active high
	clk,			  //Clock
	reset_N,		  //Synchronous reset, active low
	d_out,			  //Output data
	accumulating,	  //Indicates that the CRC register is accumulating
	draining,		  //Indicates that the CRC register is draining
	crc_ok,			  //Indicates a correct CRC value
	crc_reg			  //Provides constant monitoring of CRC register
	)/* synthesis syn_builtin_du = "weak" */;

//Parameter declaration
parameter data_width_power = 5;  
parameter mode_select = 3;
//Internal parameter 
parameter data_width = 1 << data_width_power;

//Input/output declaration
input [(1 << data_width_power) - 1 : 0 ]   d_in;
input                                      start;
input                                      drain;
input                                      byte_time;
input                                      enable;
input                                      clk;
input                                      reset_N;

output [(1 << data_width_power) - 1 : 0 ]  d_out; 
output                                     accumulating;
output                                     draining;
output                                     crc_ok;
output [31:0]                              crc_reg;

//Internal register declaration
reg [31:0]                                 crc_reg;		
reg [31:0]                                 new_crc;		
reg [data_width - 1 : 0]                   crc_reg_bit_order;		
reg [1:0]                                  byte_ctr;
reg                                        accumulating;
reg                                        draining;
reg                                        crc_ok;

//Updating the output
assign d_out = draining ? ~crc_reg_bit_order : d_in;

/*****************************
CRC-32 = x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
poly_coef0 = x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1, evaluated at x = 2
poly_coef0 = 2^12 + 2^11 + 2^10 + 2^8 + 2^7 + 2^5 + 2^4 + 2^2 + 2 + 1 =
4096 + 2048 + 1024 + 256 + 128 + 32 + 16 + 4 + 2 + 1
poly_coef0 = 7607 (binary equivalent = 0001110110110111)
poly_coef1 = (x^26 + x^23 + x^22 + x^16 )/2^16 , evaluated at x = 2
poly_coef1 = (2^26 + 2^23 + 2^22 + 2^16 )/2^16 = 2^10 + 2^7 + 2^6 + 1 =	1024 + 128 + 64 + 1
poly_coef1 = 1217 (binary equivalent = 0000010011000001)   
*****************************/
//Data width = 32 bits
function [31:0] new_crc32_d32;
input [31:0]  crc;	 
input [31:0]  din;

reg [31:0] D;
reg [31:0] C;
reg [31:0] NewCRC;

  begin
	//Bit Ordering 
	D = {din[24], din[25], din[26], din[27], din[28], din[29], din[30], din[31], din[16], din[17], din[18], din[19], din[20], din[21], din[22], din[23], din[8], din[9], din[10], din[11], din[12], din[13], din[14], din[15], din[0], din[1], din[2], din[3], din[4], din[5], din[6], din[7]}; 
    C = crc;

    NewCRC[0] = D[31] ^ D[30] ^ D[29] ^ D[28] ^ D[26] ^ D[25] ^ D[24] ^ 
                D[16] ^ D[12] ^ D[10] ^ D[9] ^ D[6] ^ D[0] ^ C[0] ^ 
                C[6] ^ C[9] ^ C[10] ^ C[12] ^ C[16] ^ C[24] ^ C[25] ^ 
                C[26] ^ C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[1] = D[28] ^ D[27] ^ D[24] ^ D[17] ^ D[16] ^ D[13] ^ D[12] ^ 
                D[11] ^ D[9] ^ D[7] ^ D[6] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ 
                C[6] ^ C[7] ^ C[9] ^ C[11] ^ C[12] ^ C[13] ^ C[16] ^ 
                C[17] ^ C[24] ^ C[27] ^ C[28];
    NewCRC[2] = D[31] ^ D[30] ^ D[26] ^ D[24] ^ D[18] ^ D[17] ^ D[16] ^ 
                D[14] ^ D[13] ^ D[9] ^ D[8] ^ D[7] ^ D[6] ^ D[2] ^ 
                D[1] ^ D[0] ^ C[0] ^ C[1] ^ C[2] ^ C[6] ^ C[7] ^ C[8] ^ 
                C[9] ^ C[13] ^ C[14] ^ C[16] ^ C[17] ^ C[18] ^ C[24] ^ 
                C[26] ^ C[30] ^ C[31];
    NewCRC[3] = D[31] ^ D[27] ^ D[25] ^ D[19] ^ D[18] ^ D[17] ^ D[15] ^ 
                D[14] ^ D[10] ^ D[9] ^ D[8] ^ D[7] ^ D[3] ^ D[2] ^ 
                D[1] ^ C[1] ^ C[2] ^ C[3] ^ C[7] ^ C[8] ^ C[9] ^ C[10] ^ 
                C[14] ^ C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[25] ^ C[27] ^ 
                C[31];
    NewCRC[4] = D[31] ^ D[30] ^ D[29] ^ D[25] ^ D[24] ^ D[20] ^ D[19] ^ 
                D[18] ^ D[15] ^ D[12] ^ D[11] ^ D[8] ^ D[6] ^ D[4] ^ 
                D[3] ^ D[2] ^ D[0] ^ C[0] ^ C[2] ^ C[3] ^ C[4] ^ C[6] ^ 
                C[8] ^ C[11] ^ C[12] ^ C[15] ^ C[18] ^ C[19] ^ C[20] ^ 
                C[24] ^ C[25] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[5] = D[29] ^ D[28] ^ D[24] ^ D[21] ^ D[20] ^ D[19] ^ D[13] ^ 
                D[10] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ 
                C[0] ^ C[1] ^ C[3] ^ C[4] ^ C[5] ^ C[6] ^ C[7] ^ C[10] ^ 
                C[13] ^ C[19] ^ C[20] ^ C[21] ^ C[24] ^ C[28] ^ C[29];
    NewCRC[6] = D[30] ^ D[29] ^ D[25] ^ D[22] ^ D[21] ^ D[20] ^ D[14] ^ 
                D[11] ^ D[8] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ 
                C[1] ^ C[2] ^ C[4] ^ C[5] ^ C[6] ^ C[7] ^ C[8] ^ C[11] ^ 
                C[14] ^ C[20] ^ C[21] ^ C[22] ^ C[25] ^ C[29] ^ C[30];
    NewCRC[7] = D[29] ^ D[28] ^ D[25] ^ D[24] ^ D[23] ^ D[22] ^ D[21] ^ 
                D[16] ^ D[15] ^ D[10] ^ D[8] ^ D[7] ^ D[5] ^ D[3] ^ 
                D[2] ^ D[0] ^ C[0] ^ C[2] ^ C[3] ^ C[5] ^ C[7] ^ C[8] ^ 
                C[10] ^ C[15] ^ C[16] ^ C[21] ^ C[22] ^ C[23] ^ C[24] ^ 
                C[25] ^ C[28] ^ C[29];
    NewCRC[8] = D[31] ^ D[28] ^ D[23] ^ D[22] ^ D[17] ^ D[12] ^ D[11] ^ 
                D[10] ^ D[8] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ 
                C[3] ^ C[4] ^ C[8] ^ C[10] ^ C[11] ^ C[12] ^ C[17] ^ 
                C[22] ^ C[23] ^ C[28] ^ C[31];
    NewCRC[9] = D[29] ^ D[24] ^ D[23] ^ D[18] ^ D[13] ^ D[12] ^ D[11] ^ 
                D[9] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[1] ^ C[2] ^ C[4] ^ 
                C[5] ^ C[9] ^ C[11] ^ C[12] ^ C[13] ^ C[18] ^ C[23] ^ 
                C[24] ^ C[29];
    NewCRC[10] = D[31] ^ D[29] ^ D[28] ^ D[26] ^ D[19] ^ D[16] ^ D[14] ^ 
                 D[13] ^ D[9] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[0] ^ C[2] ^ 
                 C[3] ^ C[5] ^ C[9] ^ C[13] ^ C[14] ^ C[16] ^ C[19] ^ 
                 C[26] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[11] = D[31] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ D[24] ^ D[20] ^ 
                 D[17] ^ D[16] ^ D[15] ^ D[14] ^ D[12] ^ D[9] ^ D[4] ^ 
                 D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ C[3] ^ C[4] ^ C[9] ^ 
                 C[12] ^ C[14] ^ C[15] ^ C[16] ^ C[17] ^ C[20] ^ C[24] ^ 
                 C[25] ^ C[26] ^ C[27] ^ C[28] ^ C[31];
    NewCRC[12] = D[31] ^ D[30] ^ D[27] ^ D[24] ^ D[21] ^ D[18] ^ D[17] ^ 
                 D[15] ^ D[13] ^ D[12] ^ D[9] ^ D[6] ^ D[5] ^ D[4] ^ 
                 D[2] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ C[2] ^ C[4] ^ C[5] ^ 
                 C[6] ^ C[9] ^ C[12] ^ C[13] ^ C[15] ^ C[17] ^ C[18] ^ 
                 C[21] ^ C[24] ^ C[27] ^ C[30] ^ C[31];
    NewCRC[13] = D[31] ^ D[28] ^ D[25] ^ D[22] ^ D[19] ^ D[18] ^ D[16] ^ 
                 D[14] ^ D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ D[3] ^ 
                 D[2] ^ D[1] ^ C[1] ^ C[2] ^ C[3] ^ C[5] ^ C[6] ^ C[7] ^ 
                 C[10] ^ C[13] ^ C[14] ^ C[16] ^ C[18] ^ C[19] ^ C[22] ^ 
                 C[25] ^ C[28] ^ C[31];
    NewCRC[14] = D[29] ^ D[26] ^ D[23] ^ D[20] ^ D[19] ^ D[17] ^ D[15] ^ 
                 D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ D[4] ^ D[3] ^ 
                 D[2] ^ C[2] ^ C[3] ^ C[4] ^ C[6] ^ C[7] ^ C[8] ^ C[11] ^ 
                 C[14] ^ C[15] ^ C[17] ^ C[19] ^ C[20] ^ C[23] ^ C[26] ^ 
                 C[29];
    NewCRC[15] = D[30] ^ D[27] ^ D[24] ^ D[21] ^ D[20] ^ D[18] ^ D[16] ^ 
                 D[15] ^ D[12] ^ D[9] ^ D[8] ^ D[7] ^ D[5] ^ D[4] ^ 
                 D[3] ^ C[3] ^ C[4] ^ C[5] ^ C[7] ^ C[8] ^ C[9] ^ C[12] ^ 
                 C[15] ^ C[16] ^ C[18] ^ C[20] ^ C[21] ^ C[24] ^ C[27] ^ 
                 C[30];
    NewCRC[16] = D[30] ^ D[29] ^ D[26] ^ D[24] ^ D[22] ^ D[21] ^ D[19] ^ 
                 D[17] ^ D[13] ^ D[12] ^ D[8] ^ D[5] ^ D[4] ^ D[0] ^ 
                 C[0] ^ C[4] ^ C[5] ^ C[8] ^ C[12] ^ C[13] ^ C[17] ^ 
                 C[19] ^ C[21] ^ C[22] ^ C[24] ^ C[26] ^ C[29] ^ C[30];
    NewCRC[17] = D[31] ^ D[30] ^ D[27] ^ D[25] ^ D[23] ^ D[22] ^ D[20] ^ 
                 D[18] ^ D[14] ^ D[13] ^ D[9] ^ D[6] ^ D[5] ^ D[1] ^ 
                 C[1] ^ C[5] ^ C[6] ^ C[9] ^ C[13] ^ C[14] ^ C[18] ^ 
                 C[20] ^ C[22] ^ C[23] ^ C[25] ^ C[27] ^ C[30] ^ C[31];
    NewCRC[18] = D[31] ^ D[28] ^ D[26] ^ D[24] ^ D[23] ^ D[21] ^ D[19] ^ 
                 D[15] ^ D[14] ^ D[10] ^ D[7] ^ D[6] ^ D[2] ^ C[2] ^ 
                 C[6] ^ C[7] ^ C[10] ^ C[14] ^ C[15] ^ C[19] ^ C[21] ^ 
                 C[23] ^ C[24] ^ C[26] ^ C[28] ^ C[31];
    NewCRC[19] = D[29] ^ D[27] ^ D[25] ^ D[24] ^ D[22] ^ D[20] ^ D[16] ^ 
                 D[15] ^ D[11] ^ D[8] ^ D[7] ^ D[3] ^ C[3] ^ C[7] ^ 
                 C[8] ^ C[11] ^ C[15] ^ C[16] ^ C[20] ^ C[22] ^ C[24] ^ 
                 C[25] ^ C[27] ^ C[29];
    NewCRC[20] = D[30] ^ D[28] ^ D[26] ^ D[25] ^ D[23] ^ D[21] ^ D[17] ^ 
                 D[16] ^ D[12] ^ D[9] ^ D[8] ^ D[4] ^ C[4] ^ C[8] ^ 
                 C[9] ^ C[12] ^ C[16] ^ C[17] ^ C[21] ^ C[23] ^ C[25] ^ 
                 C[26] ^ C[28] ^ C[30];
    NewCRC[21] = D[31] ^ D[29] ^ D[27] ^ D[26] ^ D[24] ^ D[22] ^ D[18] ^ 
                 D[17] ^ D[13] ^ D[10] ^ D[9] ^ D[5] ^ C[5] ^ C[9] ^ 
                 C[10] ^ C[13] ^ C[17] ^ C[18] ^ C[22] ^ C[24] ^ C[26] ^ 
                 C[27] ^ C[29] ^ C[31];
    NewCRC[22] = D[31] ^ D[29] ^ D[27] ^ D[26] ^ D[24] ^ D[23] ^ D[19] ^ 
                 D[18] ^ D[16] ^ D[14] ^ D[12] ^ D[11] ^ D[9] ^ D[0] ^ 
                 C[0] ^ C[9] ^ C[11] ^ C[12] ^ C[14] ^ C[16] ^ C[18] ^ 
                 C[19] ^ C[23] ^ C[24] ^ C[26] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[23] = D[31] ^ D[29] ^ D[27] ^ D[26] ^ D[20] ^ D[19] ^ D[17] ^ 
                 D[16] ^ D[15] ^ D[13] ^ D[9] ^ D[6] ^ D[1] ^ D[0] ^ 
                 C[0] ^ C[1] ^ C[6] ^ C[9] ^ C[13] ^ C[15] ^ C[16] ^ 
                 C[17] ^ C[19] ^ C[20] ^ C[26] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[24] = D[30] ^ D[28] ^ D[27] ^ D[21] ^ D[20] ^ D[18] ^ D[17] ^ 
                 D[16] ^ D[14] ^ D[10] ^ D[7] ^ D[2] ^ D[1] ^ C[1] ^ 
                 C[2] ^ C[7] ^ C[10] ^ C[14] ^ C[16] ^ C[17] ^ C[18] ^ 
                 C[20] ^ C[21] ^ C[27] ^ C[28] ^ C[30];
    NewCRC[25] = D[31] ^ D[29] ^ D[28] ^ D[22] ^ D[21] ^ D[19] ^ D[18] ^ 
                 D[17] ^ D[15] ^ D[11] ^ D[8] ^ D[3] ^ D[2] ^ C[2] ^ 
                 C[3] ^ C[8] ^ C[11] ^ C[15] ^ C[17] ^ C[18] ^ C[19] ^ 
                 C[21] ^ C[22] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[26] = D[31] ^ D[28] ^ D[26] ^ D[25] ^ D[24] ^ D[23] ^ D[22] ^ 
                 D[20] ^ D[19] ^ D[18] ^ D[10] ^ D[6] ^ D[4] ^ D[3] ^ 
                 D[0] ^ C[0] ^ C[3] ^ C[4] ^ C[6] ^ C[10] ^ C[18] ^ 
                 C[19] ^ C[20] ^ C[22] ^ C[23] ^ C[24] ^ C[25] ^ C[26] ^ 
                 C[28] ^ C[31];
    NewCRC[27] = D[29] ^ D[27] ^ D[26] ^ D[25] ^ D[24] ^ D[23] ^ D[21] ^ 
                 D[20] ^ D[19] ^ D[11] ^ D[7] ^ D[5] ^ D[4] ^ D[1] ^ 
                 C[1] ^ C[4] ^ C[5] ^ C[7] ^ C[11] ^ C[19] ^ C[20] ^ 
                 C[21] ^ C[23] ^ C[24] ^ C[25] ^ C[26] ^ C[27] ^ C[29];
    NewCRC[28] = D[30] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ D[24] ^ D[22] ^ 
                 D[21] ^ D[20] ^ D[12] ^ D[8] ^ D[6] ^ D[5] ^ D[2] ^ 
                 C[2] ^ C[5] ^ C[6] ^ C[8] ^ C[12] ^ C[20] ^ C[21] ^ 
                 C[22] ^ C[24] ^ C[25] ^ C[26] ^ C[27] ^ C[28] ^ C[30];
    NewCRC[29] = D[31] ^ D[29] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ D[23] ^ 
                 D[22] ^ D[21] ^ D[13] ^ D[9] ^ D[7] ^ D[6] ^ D[3] ^ 
                 C[3] ^ C[6] ^ C[7] ^ C[9] ^ C[13] ^ C[21] ^ C[22] ^ 
                 C[23] ^ C[25] ^ C[26] ^ C[27] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[30] = D[30] ^ D[29] ^ D[28] ^ D[27] ^ D[26] ^ D[24] ^ D[23] ^ 
                 D[22] ^ D[14] ^ D[10] ^ D[8] ^ D[7] ^ D[4] ^ C[4] ^ 
                 C[7] ^ C[8] ^ C[10] ^ C[14] ^ C[22] ^ C[23] ^ C[24] ^ 
                 C[26] ^ C[27] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[31] = D[31] ^ D[30] ^ D[29] ^ D[28] ^ D[27] ^ D[25] ^ D[24] ^ 
                 D[23] ^ D[15] ^ D[11] ^ D[9] ^ D[8] ^ D[5] ^ C[5] ^ 
                 C[8] ^ C[9] ^ C[11] ^ C[15] ^ C[23] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[28] ^ C[29] ^ C[30] ^ C[31];

    new_crc32_d32 = NewCRC;

  end
		
endfunction

//Data width = 16 bits
function [31:0] new_crc32_d16;
input [31:0]  crc;	 
input [15:0]  din;

reg [15:0] D;
reg [31:0] C;
reg [31:0] NewCRC;

  begin
	//Bit Ordering 
	D = {din[8], din[9], din[10], din[11], din[12], din[13], din[14], din[15], din[0], din[1], din[2], din[3], din[4], din[5], din[6], din[7]}; 
    C = crc;

    NewCRC[0] = D[12] ^ D[10] ^ D[9] ^ D[6] ^ D[0] ^ C[16] ^ C[22] ^ 
                C[25] ^ C[26] ^ C[28];
    NewCRC[1] = D[13] ^ D[12] ^ D[11] ^ D[9] ^ D[7] ^ D[6] ^ D[1] ^ 
                D[0] ^ C[16] ^ C[17] ^ C[22] ^ C[23] ^ C[25] ^ C[27] ^ 
                C[28] ^ C[29];
    NewCRC[2] = D[14] ^ D[13] ^ D[9] ^ D[8] ^ D[7] ^ D[6] ^ D[2] ^ 
                D[1] ^ D[0] ^ C[16] ^ C[17] ^ C[18] ^ C[22] ^ C[23] ^ 
                C[24] ^ C[25] ^ C[29] ^ C[30];
    NewCRC[3] = D[15] ^ D[14] ^ D[10] ^ D[9] ^ D[8] ^ D[7] ^ D[3] ^ 
                D[2] ^ D[1] ^ C[17] ^ C[18] ^ C[19] ^ C[23] ^ C[24] ^ 
                C[25] ^ C[26] ^ C[30] ^ C[31];
    NewCRC[4] = D[15] ^ D[12] ^ D[11] ^ D[8] ^ D[6] ^ D[4] ^ D[3] ^ 
                D[2] ^ D[0] ^ C[16] ^ C[18] ^ C[19] ^ C[20] ^ C[22] ^ 
                C[24] ^ C[27] ^ C[28] ^ C[31];
    NewCRC[5] = D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[3] ^ 
                D[1] ^ D[0] ^ C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[21] ^ 
                C[22] ^ C[23] ^ C[26] ^ C[29];
    NewCRC[6] = D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ 
                D[2] ^ D[1] ^ C[17] ^ C[18] ^ C[20] ^ C[21] ^ C[22] ^ 
                C[23] ^ C[24] ^ C[27] ^ C[30];
    NewCRC[7] = D[15] ^ D[10] ^ D[8] ^ D[7] ^ D[5] ^ D[3] ^ D[2] ^ 
                D[0] ^ C[16] ^ C[18] ^ C[19] ^ C[21] ^ C[23] ^ C[24] ^ 
                C[26] ^ C[31];
    NewCRC[8] = D[12] ^ D[11] ^ D[10] ^ D[8] ^ D[4] ^ D[3] ^ D[1] ^ 
                D[0] ^ C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[28];
    NewCRC[9] = D[13] ^ D[12] ^ D[11] ^ D[9] ^ D[5] ^ D[4] ^ D[2] ^ 
                D[1] ^ C[17] ^ C[18] ^ C[20] ^ C[21] ^ C[25] ^ C[27] ^ 
                C[28] ^ C[29];
    NewCRC[10] = D[14] ^ D[13] ^ D[9] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ 
                 C[16] ^ C[18] ^ C[19] ^ C[21] ^ C[25] ^ C[29] ^ C[30];
    NewCRC[11] = D[15] ^ D[14] ^ D[12] ^ D[9] ^ D[4] ^ D[3] ^ D[1] ^ 
                 D[0] ^ C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[25] ^ C[28] ^ 
                 C[30] ^ C[31];
    NewCRC[12] = D[15] ^ D[13] ^ D[12] ^ D[9] ^ D[6] ^ D[5] ^ D[4] ^ 
                 D[2] ^ D[1] ^ D[0] ^ C[16] ^ C[17] ^ C[18] ^ C[20] ^ 
                 C[21] ^ C[22] ^ C[25] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[13] = D[14] ^ D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ D[3] ^ 
                 D[2] ^ D[1] ^ C[17] ^ C[18] ^ C[19] ^ C[21] ^ C[22] ^ 
                 C[23] ^ C[26] ^ C[29] ^ C[30];
    NewCRC[14] = D[15] ^ D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ D[4] ^ 
                 D[3] ^ D[2] ^ C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[23] ^ 
                 C[24] ^ C[27] ^ C[30] ^ C[31];
    NewCRC[15] = D[15] ^ D[12] ^ D[9] ^ D[8] ^ D[7] ^ D[5] ^ D[4] ^ 
                 D[3] ^ C[19] ^ C[20] ^ C[21] ^ C[23] ^ C[24] ^ C[25] ^ 
                 C[28] ^ C[31];
    NewCRC[16] = D[13] ^ D[12] ^ D[8] ^ D[5] ^ D[4] ^ D[0] ^ C[0] ^ 
                 C[16] ^ C[20] ^ C[21] ^ C[24] ^ C[28] ^ C[29];
    NewCRC[17] = D[14] ^ D[13] ^ D[9] ^ D[6] ^ D[5] ^ D[1] ^ C[1] ^ 
                 C[17] ^ C[21] ^ C[22] ^ C[25] ^ C[29] ^ C[30];
    NewCRC[18] = D[15] ^ D[14] ^ D[10] ^ D[7] ^ D[6] ^ D[2] ^ C[2] ^ 
                 C[18] ^ C[22] ^ C[23] ^ C[26] ^ C[30] ^ C[31];
    NewCRC[19] = D[15] ^ D[11] ^ D[8] ^ D[7] ^ D[3] ^ C[3] ^ C[19] ^ 
                 C[23] ^ C[24] ^ C[27] ^ C[31];
    NewCRC[20] = D[12] ^ D[9] ^ D[8] ^ D[4] ^ C[4] ^ C[20] ^ C[24] ^ 
                 C[25] ^ C[28];
    NewCRC[21] = D[13] ^ D[10] ^ D[9] ^ D[5] ^ C[5] ^ C[21] ^ C[25] ^ 
                 C[26] ^ C[29];
    NewCRC[22] = D[14] ^ D[12] ^ D[11] ^ D[9] ^ D[0] ^ C[6] ^ C[16] ^ 
                 C[25] ^ C[27] ^ C[28] ^ C[30];
    NewCRC[23] = D[15] ^ D[13] ^ D[9] ^ D[6] ^ D[1] ^ D[0] ^ C[7] ^ 
                 C[16] ^ C[17] ^ C[22] ^ C[25] ^ C[29] ^ C[31];
    NewCRC[24] = D[14] ^ D[10] ^ D[7] ^ D[2] ^ D[1] ^ C[8] ^ C[17] ^ 
                 C[18] ^ C[23] ^ C[26] ^ C[30];
    NewCRC[25] = D[15] ^ D[11] ^ D[8] ^ D[3] ^ D[2] ^ C[9] ^ C[18] ^ 
                 C[19] ^ C[24] ^ C[27] ^ C[31];
    NewCRC[26] = D[10] ^ D[6] ^ D[4] ^ D[3] ^ D[0] ^ C[10] ^ C[16] ^ 
                 C[19] ^ C[20] ^ C[22] ^ C[26];
    NewCRC[27] = D[11] ^ D[7] ^ D[5] ^ D[4] ^ D[1] ^ C[11] ^ C[17] ^ 
                 C[20] ^ C[21] ^ C[23] ^ C[27];
    NewCRC[28] = D[12] ^ D[8] ^ D[6] ^ D[5] ^ D[2] ^ C[12] ^ C[18] ^ 
                 C[21] ^ C[22] ^ C[24] ^ C[28];
    NewCRC[29] = D[13] ^ D[9] ^ D[7] ^ D[6] ^ D[3] ^ C[13] ^ C[19] ^ 
                 C[22] ^ C[23] ^ C[25] ^ C[29];
    NewCRC[30] = D[14] ^ D[10] ^ D[8] ^ D[7] ^ D[4] ^ C[14] ^ C[20] ^ 
                 C[23] ^ C[24] ^ C[26] ^ C[30];
    NewCRC[31] = D[15] ^ D[11] ^ D[9] ^ D[8] ^ D[5] ^ C[15] ^ C[21] ^ 
                 C[24] ^ C[25] ^ C[27] ^ C[31];

    new_crc32_d16 = NewCRC;

  end
		
endfunction

//Data width = 8 bits
function [31:0] new_crc32_d8;
input [31:0] crc;	 
input [7:0]  din;

reg [31:0] C;
reg [7:0] D;
reg [31:0] NewCRC;

  begin
	//Bit Ordering 
	D = {din[0], din[1], din[2], din[3], din[4], din[5], din[6], din[7]}; 
    C = crc;

    NewCRC[0] = D[6] ^ D[0] ^ C[24] ^ C[30];
    NewCRC[1] = D[7] ^ D[6] ^ D[1] ^ D[0] ^ C[24] ^ C[25] ^ C[30] ^ C[31];
    NewCRC[2] = D[7] ^ D[6] ^ D[2] ^ D[1] ^ D[0] ^ C[24] ^ C[25] ^ 
                C[26] ^ C[30] ^ C[31];
    NewCRC[3] = D[7] ^ D[3] ^ D[2] ^ D[1] ^ C[25] ^ C[26] ^ C[27] ^ 
                C[31];
    NewCRC[4] = D[6] ^ D[4] ^ D[3] ^ D[2] ^ D[0] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[28] ^ C[30];
    NewCRC[5] = D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[24] ^ 
                C[25] ^ C[27] ^ C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[6] = D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[25] ^ C[26] ^ 
                C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[7] = D[7] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[29] ^ C[31];
    NewCRC[8] = D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[24] ^ C[25] ^ 
                C[27] ^ C[28];
    NewCRC[9] = D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[1] ^ C[25] ^ C[26] ^ 
                C[28] ^ C[29];
    NewCRC[10] = D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[2] ^ C[24] ^ C[26] ^ 
                 C[27] ^ C[29];
    NewCRC[11] = D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[3] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[28];
    NewCRC[12] = D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ D[0] ^ C[4] ^ C[24] ^ 
                 C[25] ^ C[26] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[13] = D[7] ^ D[6] ^ D[5] ^ D[3] ^ D[2] ^ D[1] ^ C[5] ^ C[25] ^ 
                 C[26] ^ C[27] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[14] = D[7] ^ D[6] ^ D[4] ^ D[3] ^ D[2] ^ C[6] ^ C[26] ^ C[27] ^ 
                 C[28] ^ C[30] ^ C[31];
    NewCRC[15] = D[7] ^ D[5] ^ D[4] ^ D[3] ^ C[7] ^ C[27] ^ C[28] ^ 

                 C[29] ^ C[31];
    NewCRC[16] = D[5] ^ D[4] ^ D[0] ^ C[8] ^ C[24] ^ C[28] ^ C[29];
    NewCRC[17] = D[6] ^ D[5] ^ D[1] ^ C[9] ^ C[25] ^ C[29] ^ C[30];
    NewCRC[18] = D[7] ^ D[6] ^ D[2] ^ C[10] ^ C[26] ^ C[30] ^ C[31];
    NewCRC[19] = D[7] ^ D[3] ^ C[11] ^ C[27] ^ C[31];
    NewCRC[20] = D[4] ^ C[12] ^ C[28];
    NewCRC[21] = D[5] ^ C[13] ^ C[29];
    NewCRC[22] = D[0] ^ C[14] ^ C[24];
    NewCRC[23] = D[6] ^ D[1] ^ D[0] ^ C[15] ^ C[24] ^ C[25] ^ C[30];
    NewCRC[24] = D[7] ^ D[2] ^ D[1] ^ C[16] ^ C[25] ^ C[26] ^ C[31];
    NewCRC[25] = D[3] ^ D[2] ^ C[17] ^ C[26] ^ C[27];
    NewCRC[26] = D[6] ^ D[4] ^ D[3] ^ D[0] ^ C[18] ^ C[24] ^ C[27] ^ 
                 C[28] ^ C[30];
    NewCRC[27] = D[7] ^ D[5] ^ D[4] ^ D[1] ^ C[19] ^ C[25] ^ C[28] ^ 
                 C[29] ^ C[31];
    NewCRC[28] = D[6] ^ D[5] ^ D[2] ^ C[20] ^ C[26] ^ C[29] ^ C[30];
    NewCRC[29] = D[7] ^ D[6] ^ D[3] ^ C[21] ^ C[27] ^ C[30] ^ C[31];
    NewCRC[30] = D[7] ^ D[4] ^ C[22] ^ C[28] ^ C[31];
    NewCRC[31] = D[5] ^ C[23] ^ C[29];

    new_crc32_d8 = NewCRC;

  end
		
endfunction


//Data width = 4 bits
function [31:0] new_crc32_d4;
input [31:0] crc;	 
input [3:0]  din;

reg [31:0] C;
reg [3:0] D;
reg [31:0] NewCRC;

  begin
	//Bit Ordering 
	D = {din[0], din[1], din[2], din[3]}; 
    C = crc;

    NewCRC[0] = D[0] ^ C[28];
    NewCRC[1] = D[1] ^ D[0] ^ C[28] ^ C[29];
    NewCRC[2] = D[2] ^ D[1] ^ D[0] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[3] = D[3] ^ D[2] ^ D[1] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[4] = D[3] ^ D[2] ^ D[0] ^ C[0] ^ C[28] ^ C[30] ^ C[31];
    NewCRC[5] = D[3] ^ D[1] ^ D[0] ^ C[1] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[6] = D[2] ^ D[1] ^ C[2] ^ C[29] ^ C[30];
    NewCRC[7] = D[3] ^ D[2] ^ D[0] ^ C[3] ^ C[28] ^ C[30] ^ C[31];
    NewCRC[8] = D[3] ^ D[1] ^ D[0] ^ C[4] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[9] = D[2] ^ D[1] ^ C[5] ^ C[29] ^ C[30];
    NewCRC[10] = D[3] ^ D[2] ^ D[0] ^ C[6] ^ C[28] ^ C[30] ^ C[31];
    NewCRC[11] = D[3] ^ D[1] ^ D[0] ^ C[7] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[12] = D[2] ^ D[1] ^ D[0] ^ C[8] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[13] = D[3] ^ D[2] ^ D[1] ^ C[9] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[14] = D[3] ^ D[2] ^ C[10] ^ C[30] ^ C[31];
    NewCRC[15] = D[3] ^ C[11] ^ C[31];
    NewCRC[16] = D[0] ^ C[12] ^ C[28];
    NewCRC[17] = D[1] ^ C[13] ^ C[29];
    NewCRC[18] = D[2] ^ C[14] ^ C[30];
    NewCRC[19] = D[3] ^ C[15] ^ C[31];
    NewCRC[20] = C[16];
    NewCRC[21] = C[17];
    NewCRC[22] = D[0] ^ C[18] ^ C[28];
    NewCRC[23] = D[1] ^ D[0] ^ C[19] ^ C[28] ^ C[29];
    NewCRC[24] = D[2] ^ D[1] ^ C[20] ^ C[29] ^ C[30];
    NewCRC[25] = D[3] ^ D[2] ^ C[21] ^ C[30] ^ C[31];
    NewCRC[26] = D[3] ^ D[0] ^ C[22] ^ C[28] ^ C[31];
    NewCRC[27] = D[1] ^ C[23] ^ C[29];
    NewCRC[28] = D[2] ^ C[24] ^ C[30];
    NewCRC[29] = D[3] ^ C[25] ^ C[31];
    NewCRC[30] = C[26];
    NewCRC[31] = C[27];

    new_crc32_d4 = NewCRC;

  end
		
endfunction
 
//Data width = 2 bits
function [31:0] new_crc32_d2;
input [31:0] crc;	 
input [1:0]  din;

reg [31:0] C;
reg [1:0] D;
reg [31:0] NewCRC;

  begin
	//Bit Ordering 
	D = {din[0], din[1]}; 
    C = crc;

    NewCRC[0] = D[0] ^ C[30];
    NewCRC[1] = D[1] ^ D[0] ^ C[30] ^ C[31];
    NewCRC[2] = D[1] ^ D[0] ^ C[0] ^ C[30] ^ C[31];
    NewCRC[3] = D[1] ^ C[1] ^ C[31];
    NewCRC[4] = D[0] ^ C[2] ^ C[30];
    NewCRC[5] = D[1] ^ D[0] ^ C[3] ^ C[30] ^ C[31];
    NewCRC[6] = D[1] ^ C[4] ^ C[31];
    NewCRC[7] = D[0] ^ C[5] ^ C[30];
    NewCRC[8] = D[1] ^ D[0] ^ C[6] ^ C[30] ^ C[31];
    NewCRC[9] = D[1] ^ C[7] ^ C[31];
    NewCRC[10] = D[0] ^ C[8] ^ C[30];
    NewCRC[11] = D[1] ^ D[0] ^ C[9] ^ C[30] ^ C[31];
    NewCRC[12] = D[1] ^ D[0] ^ C[10] ^ C[30] ^ C[31];
    NewCRC[13] = D[1] ^ C[11] ^ C[31];
    NewCRC[14] = C[12];
    NewCRC[15] = C[13];
    NewCRC[16] = D[0] ^ C[14] ^ C[30];
    NewCRC[17] = D[1] ^ C[15] ^ C[31];
    NewCRC[18] = C[16];
    NewCRC[19] = C[17];
    NewCRC[20] = C[18];
    NewCRC[21] = C[19];
    NewCRC[22] = D[0] ^ C[20] ^ C[30];
    NewCRC[23] = D[1] ^ D[0] ^ C[21] ^ C[30] ^ C[31];
    NewCRC[24] = D[1] ^ C[22] ^ C[31];
    NewCRC[25] = C[23];
    NewCRC[26] = D[0] ^ C[24] ^ C[30];
    NewCRC[27] = D[1] ^ C[25] ^ C[31];
    NewCRC[28] = C[26];
    NewCRC[29] = C[27];
    NewCRC[30] = C[28];
    NewCRC[31] = C[29];

    new_crc32_d2 = NewCRC;

  end
		
endfunction

//Data width = 1 bit
function [31:0] new_crc32_d1;
input [31:0] crc;	 
input [0:0]  din;

reg [31:0] C;
reg [0:0]  D;
reg [31:0] NewCRC;

  begin
	//Bit Ordering 
	D[0] = din; 
    C = crc;

    NewCRC[0] = D[0] ^ C[31];
    NewCRC[1] = D[0] ^ C[0] ^ C[31];
    NewCRC[2] = D[0] ^ C[1] ^ C[31];
    NewCRC[3] = C[2];
    NewCRC[4] = D[0] ^ C[3] ^ C[31];
    NewCRC[5] = D[0] ^ C[4] ^ C[31];
    NewCRC[6] = C[5];
    NewCRC[7] = D[0] ^ C[6] ^ C[31];
    NewCRC[8] = D[0] ^ C[7] ^ C[31];
    NewCRC[9] = C[8];
    NewCRC[10] = D[0] ^ C[9] ^ C[31];
    NewCRC[11] = D[0] ^ C[10] ^ C[31];
    NewCRC[12] = D[0] ^ C[11] ^ C[31];
    NewCRC[13] = C[12];
    NewCRC[14] = C[13];
    NewCRC[15] = C[14];
    NewCRC[16] = D[0] ^ C[15] ^ C[31];
    NewCRC[17] = C[16];
    NewCRC[18] = C[17];
    NewCRC[19] = C[18];
    NewCRC[20] = C[19];
    NewCRC[21] = C[20];
    NewCRC[22] = D[0] ^ C[21] ^ C[31];
    NewCRC[23] = D[0] ^ C[22] ^ C[31];
    NewCRC[24] = C[23];
    NewCRC[25] = C[24];
    NewCRC[26] = D[0] ^ C[25] ^ C[31];
    NewCRC[27] = C[26];
    NewCRC[28] = C[27];
    NewCRC[29] = C[28];
    NewCRC[30] = C[29];
    NewCRC[31] = C[30];

    new_crc32_d1 = NewCRC;

  end
		
endfunction

//Call the function to get the new CRC.
always @( crc_reg or d_in )
	if ( data_width_power == 5 )
		new_crc = new_crc32_d32(crc_reg, d_in);
	else if ( data_width_power == 4 )
		new_crc = new_crc32_d16(crc_reg, d_in);
	else if ( data_width_power == 3 )
		new_crc = new_crc32_d8(crc_reg, d_in);
	else if ( data_width_power == 2 )
		new_crc = new_crc32_d4(crc_reg, d_in);
	else if ( data_width_power == 1 )
		new_crc = new_crc32_d2(crc_reg, d_in);
	else 
		new_crc = new_crc32_d1(crc_reg, d_in);
	
	
//Registering the CRC32
always @( posedge clk )
	if ( !reset_N )
		crc_reg <= 32'hffff_ffff;
	else
		begin  
			if ( start )
				crc_reg <= 32'hffff_ffff; // For checking purpose this is needed				
			else if ( enable && accumulating && !start )
				crc_reg <= new_crc;
			else if ( enable && draining )
				crc_reg <= crc_reg << data_width;
		end	

//Bit_ordering crc_reg -- see Table 8
always @( crc_reg )
	if ( data_width == 2 )
		crc_reg_bit_order = {crc_reg[30], crc_reg[31]};  
	else if ( data_width == 4 )
		crc_reg_bit_order = {crc_reg[28], crc_reg[29], crc_reg[30], crc_reg[31]}; 
	else if ( data_width == 8 )
		crc_reg_bit_order = {crc_reg[24], crc_reg[25], crc_reg[26], crc_reg[27], crc_reg[28], crc_reg[29], crc_reg[30], crc_reg[31]}; 
	else if ( data_width == 16 )
		crc_reg_bit_order = {crc_reg[24], crc_reg[25], crc_reg[26], crc_reg[27], crc_reg[28], crc_reg[29], crc_reg[30], crc_reg[31], crc_reg[16], crc_reg[17], crc_reg[18], crc_reg[19], crc_reg[20], crc_reg[21], crc_reg[22], crc_reg[23]};  
	else if ( data_width == 32 )
		crc_reg_bit_order = {crc_reg[24], crc_reg[25], crc_reg[26], crc_reg[27], crc_reg[28], crc_reg[29], crc_reg[30], crc_reg[31], crc_reg[16], crc_reg[17], crc_reg[18], crc_reg[19], crc_reg[20], crc_reg[21], crc_reg[22], crc_reg[23], crc_reg[8], crc_reg[9], crc_reg[10], crc_reg[11], crc_reg[12], crc_reg[13], crc_reg[14], crc_reg[15], crc_reg[0], crc_reg[1], crc_reg[2], crc_reg[3], crc_reg[4], crc_reg[5], crc_reg[6], crc_reg[7]}; 
	else 
		crc_reg_bit_order = crc_reg[31];
	
//Generation of accumulating signal
always @( posedge clk )
	if ( !reset_N )
		accumulating <= 1'b0;
	else
		begin
			if ( enable && byte_time && start )	 
				accumulating <= 1'b1;
			else if ( enable && byte_time && drain )
				accumulating <= 1'b0;
		end		
				
//Generation of draining signal
always @( posedge clk )
	if ( !reset_N )
		draining <= 1'b0;
	else
		begin
			if ( enable && byte_time && drain && accumulating )	 
				draining <= 1'b1;
			else if ( enable && byte_time && (( byte_ctr == 2'b11 && ( data_width == 1 || data_width == 2 || data_width == 4 || data_width == 8)) || ( data_width == 16 && byte_ctr[0] ) || data_width == 32))
				draining <= 1'b0;
		end													  
		
//Generation of Byte counter : counting the no. of bytes when draining is asserted
always @( posedge clk )
	if ( !reset_N )
		byte_ctr <= 2'b00;
	else
		begin
			if ( enable && byte_time && drain && accumulating )
				byte_ctr <= 2'b00;
			else if ( byte_time ) 
				byte_ctr <= byte_ctr + 1'b1;				 
		end		

//Checking the CRC
always @( posedge clk )	
	if (  mode_select > 1 )
		begin
			if ( !reset_N )
				crc_ok <= 1'b0;
			else			  
				if ( byte_time && enable )
					crc_ok <= new_crc == 32'hc704_dd7b;
		end	
		
endmodule
