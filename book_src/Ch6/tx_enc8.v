 module tx_enc8 ( // input
 input CLK_40,
 input RST_X,
 input VALID,
 input SYN_RST,
 input [7:0] DATA_IN,
 output reg [15:0] DATA_OUT);
 
 reg  [5:0] r_enc0;
 wire [5:0] r_enc1,r_enc2,r_enc3,r_enc4,r_enc5,r_enc6,r_enc7,r_enc8;
 wire [15:0]code;
 
 assign r_enc1 = {DATA_IN[0], r_enc0[5:1]};
 assign r_enc2 = {DATA_IN[1], r_enc1[5:1]};
 assign r_enc3 = {DATA_IN[2], r_enc2[5:1]};
 assign r_enc4 = {DATA_IN[3], r_enc3[5:1]};
 assign r_enc5 = {DATA_IN[4], r_enc4[5:1]};
 assign r_enc6 = {DATA_IN[5], r_enc5[5:1]};
 assign r_enc7 = {DATA_IN[6], r_enc6[5:1]};
 assign r_enc8 = {DATA_IN[7], r_enc7[5:1]};
 
 assign code[ 0]= DATA_IN[0] ^ r_enc0[4] ^ r_enc0[3] ^ r_enc0[0] ^ r_enc0[1];
 assign code[ 2]= DATA_IN[1] ^ r_enc1[4] ^ r_enc1[3] ^ r_enc1[0] ^ r_enc1[1];
 assign code[ 4]= DATA_IN[2] ^ r_enc2[4] ^ r_enc2[3] ^ r_enc2[0] ^ r_enc2[1];
 assign code[ 6]= DATA_IN[3] ^ r_enc3[4] ^ r_enc3[3] ^ r_enc3[0] ^ r_enc3[1];
 assign code[ 8]= DATA_IN[4] ^ r_enc4[4] ^ r_enc4[3] ^ r_enc4[0] ^ r_enc4[1];
 assign code[10]= DATA_IN[5] ^ r_enc5[4] ^ r_enc5[3] ^ r_enc5[0] ^ r_enc5[1];
 assign code[12]= DATA_IN[6] ^ r_enc6[4] ^ r_enc6[3] ^ r_enc6[0] ^ r_enc6[1];
 assign code[14]= DATA_IN[7] ^ r_enc7[4] ^ r_enc7[3] ^ r_enc7[0] ^ r_enc7[1];
 
 assign code[ 1]= DATA_IN[0] ^ r_enc0[4] ^ r_enc0[3] ^ r_enc0[0] ^ r_enc0[5];
 assign code[ 3]= DATA_IN[1] ^ r_enc1[4] ^ r_enc1[3] ^ r_enc1[0] ^ r_enc1[5];
 assign code[ 5]= DATA_IN[2] ^ r_enc2[4] ^ r_enc2[3] ^ r_enc2[0] ^ r_enc2[5];
 assign code[ 7]= DATA_IN[3] ^ r_enc3[4] ^ r_enc3[3] ^ r_enc3[0] ^ r_enc3[5];
 assign code[ 9]= DATA_IN[4] ^ r_enc4[4] ^ r_enc4[3] ^ r_enc4[0] ^ r_enc4[5];
 assign code[11]= DATA_IN[5] ^ r_enc5[4] ^ r_enc5[3] ^ r_enc5[0] ^ r_enc5[5];
 assign code[13]= DATA_IN[6] ^ r_enc6[4] ^ r_enc6[3] ^ r_enc6[0] ^ r_enc6[5];
 assign code[15]= DATA_IN[7] ^ r_enc7[4] ^ r_enc7[3] ^ r_enc7[0] ^ r_enc7[5];
 
 always @(posedge CLK_40 or negedge RST_X)
   if(!RST_X)begin
     r_enc0   <= 6'd0;
     DATA_OUT <= 16'd0;
   end
   else if(SYN_RST==1'b1)begin
     r_enc0   <= 6'd0;
     DATA_OUT <= 16'd0;
   end
   else if(VALID==1'b1)begin
     r_enc0   <= r_enc8;
     DATA_OUT <= code;
   end

 endmodule
