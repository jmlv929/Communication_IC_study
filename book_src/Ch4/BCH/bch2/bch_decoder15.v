`timescale 1ns / 1ps
module bch_decoder15(clk,r,c);
    input [14:0] r;
	 input clk;
	 output [14:0] c;
	 reg [3:0]s1,s2,s3,s4,s5,s6;
    reg [3:0] mymem1 [14:0];
    reg [3:0] mymem2 [14:0];
    reg [3:0] mymem3 [14:0];
	 reg [3:0] mymem4 [14:0];
	 reg [3:0] mymem5 [14:0];
	 reg [3:0] mymeme [14:0];	 
	 reg [3:0] ee [14:0];
	 reg [3:0] mymems [5:0];
	 reg [3:0] mymems1 [2:0];
	 reg [3:0] mymems2 [2:0];
	 reg [3:0] mymems3 [2:0];
	 reg [3:0] mymemk1 [2:0];
	 reg [3:0] mymemk2 [2:0];	
	 reg [3:0] mymemk3 [2:0];
    reg [14:0] e,c;	 
	 reg [3:0]i,k,k2,k3,delta1_downk1,delta1_upk2,delta2_upk3;
    reg [3:0] c1 [14:0];
    reg [3:0] svalue,delta1_down,delta1_up,delta2_down,delta2_up,delta1,delta2,delta11,delta22;	 
	  always @(posedge clk)      
				begin//the 1 row of H
					mymem1[0] = 4'b0001; mymem1[1] = 4'b0010;
	            mymem1[2] = 4'b0100; mymem1[3] = 4'b1000;
					mymem1[4] = 4'b0011; mymem1[5] = 4'b0110;
					mymem1[6] = 4'b1100; mymem1[7] = 4'b1011;
					mymem1[8] = 4'b0101; mymem1[9] = 4'b1010;
					mymem1[10] = 4'b0111;mymem1[11] = 4'b1110;
					mymem1[12] = 4'b1111;mymem1[13] = 4'b1101;
					mymem1[14] = 4'b1001;
		
				  for(i=0;i<15;i=i+1)//the 2 row of H
                 begin 
					    mymem2[i]=mymem1[(i*3)%15];
                 end	
	           for(i=0;i<15;i=i+1)//the 3 row of H
                 begin 
					    mymem3[i]=mymem1[(i*5)%15];
                 end						  
			   end
      always @(posedge clk)//store r as a memory
		 begin 
		  for(i=0;i<15;i=i+1)
			begin
			   if(r[i]==1)
				   c1[i]=4'b1111;
				else
				   c1[i]=4'b0000;
			end
       end
			
   	always @(posedge clk)//work out s1,s3,s5
	    begin
		  s1<=(c1[0]&mymem1[0])^(c1[1]&mymem1[1])^(c1[2]&mymem1[2])^(c1[3]&mymem1[3])^(c1[4]&mymem1[4])^(c1[5]&mymem1[5])^(c1[6]&mymem1[6])^(c1[7]&mymem1[7])^(c1[8]&mymem1[8])^(c1[9]&mymem1[9])^(c1[10]&mymem1[10])^(c1[11]&mymem1[11])^(c1[12]&mymem1[12])^(c1[13]&mymem1[13])^(c1[14]&mymem1[14]);		
		  s3<=(c1[0]&mymem2[0])^(c1[1]&mymem2[1])^(c1[2]&mymem2[2])^(c1[3]&mymem2[3])^(c1[4]&mymem2[4])^(c1[5]&mymem2[5])^(c1[6]&mymem2[6])^(c1[7]&mymem2[7])^(c1[8]&mymem2[8])^(c1[9]&mymem2[9])^(c1[10]&mymem2[10])^(c1[11]&mymem2[11])^(c1[12]&mymem2[12])^(c1[13]&mymem2[13])^(c1[14]&mymem2[14]);		
		  s5<=(c1[0]&mymem3[0])^(c1[1]&mymem3[1])^(c1[2]&mymem3[2])^(c1[3]&mymem3[3])^(c1[4]&mymem3[4])^(c1[5]&mymem3[5])^(c1[6]&mymem3[6])^(c1[7]&mymem3[7])^(c1[8]&mymem3[8])^(c1[9]&mymem3[9])^(c1[10]&mymem3[10])^(c1[11]&mymem3[11])^(c1[12]&mymem3[12])^(c1[13]&mymem3[13])^(c1[14]&mymem3[14]);		
		 end
   	
     always @(posedge clk)//work out s2
	    begin
		   case (s1)
			  mymem1[0]: k<=0;
			  mymem1[1]: k<=1;
			  mymem1[2]: k<=2;
			  mymem1[3]: k<=3;
			  mymem1[4]: k<=4;
			  mymem1[5]: k<=5;
			  mymem1[6]: k<=6;
			  mymem1[7]: k<=7;
			  mymem1[8]: k<=8;
			  mymem1[9]: k<=9;
			  mymem1[10]: k<=10;
			  mymem1[11]: k<=11;
			  mymem1[12]: k<=12;
			  mymem1[13]: k<=13;
			  mymem1[14]: k<=14;
			  default: k<=0;
		   endcase
          s2=mymem1[(2*k)%15];
	  end
	  
    always @(posedge clk)//work out s4
	    begin
		   case (s2)
			  mymem1[0]: k2<=0;
			  mymem1[1]: k2<=1;
			  mymem1[2]: k2<=2;
			  mymem1[3]: k2<=3;
			  mymem1[4]: k2<=4;
			  mymem1[5]: k2<=5;
			  mymem1[6]: k2<=6;
			  mymem1[7]: k2<=7;
			  mymem1[8]: k2<=8;
			  mymem1[9]: k2<=9;
			  mymem1[10]: k2<=10;
			  mymem1[11]: k2<=11;
			  mymem1[12]: k2<=12;
			  mymem1[13]: k2<=13;
			  mymem1[14]: k2<=14;
			  default: k2<=0;
		   endcase
          s4=mymem1[(2*k2)%15];
	  end
	  
     always @(posedge clk)//work out s6
	    begin
		   case (s3)
			  mymem1[0]: k3<=0;
			  mymem1[1]: k3<=1;
			  mymem1[2]: k3<=2;
			  mymem1[3]: k3<=3;
			  mymem1[4]: k3<=4;
			  mymem1[5]: k3<=5;
			  mymem1[6]: k3<=6;
			  mymem1[7]: k3<=7;
			  mymem1[8]: k3<=8;
			  mymem1[9]: k3<=9;
			  mymem1[10]: k3<=10;
			  mymem1[11]: k3<=11;
			  mymem1[12]: k3<=12;
			  mymem1[13]: k3<=13;
			  mymem1[14]: k3<=14;
			  default: k3<=0;
		   endcase
          s6=mymem1[(2*k3)%15];
	  end

     always @(posedge clk)//store s1...s6
	    begin
			   mymems[0]=s1; mymems[1]=s2; mymems[2]=s3;
				mymems[3]=s4; mymems[4]=s5; mymems[5]=s6;
		   for(i=0;i<3;i=i+1)
			  begin
			     mymems1[i]=mymems[i];mymems2[i]=mymems[i+1];mymems3[i]=mymems[i+2];
			  end
		end
//////////////////////////work out error polynomial//////////////////////////////////		
		always @(posedge clk) 
		  begin
		     for(i=0;i<3;i=i+1)
		      case (mymems1[i])
			     mymem1[0]: mymemk1[i]<=0;
			     mymem1[1]: mymemk1[i]<=1;
			     mymem1[2]: mymemk1[i]<=2;
			     mymem1[3]: mymemk1[i]<=3;
			     mymem1[4]: mymemk1[i]<=4;
			     mymem1[5]: mymemk1[i]<=5;
			     mymem1[6]: mymemk1[i]<=6;
			     mymem1[7]: mymemk1[i]<=7;
			     mymem1[8]: mymemk1[i]<=8;
			     mymem1[9]: mymemk1[i]<=9;
			     mymem1[10]: mymemk1[i]<=10;
			     mymem1[11]: mymemk1[i]<=11;
			     mymem1[12]: mymemk1[i]<=12;
			     mymem1[13]: mymemk1[i]<=13;
			     mymem1[14]: mymemk1[i]<=14;
			  default: mymemk1[i]<=0;		
			  endcase
		  end
		  
		always @(posedge clk) 
		  begin
		     for(i=0;i<3;i=i+1)
		      case (mymems2[i])
			     mymem1[0]: mymemk2[i]<=0;
			     mymem1[1]: mymemk2[i]<=1;
			     mymem1[2]: mymemk2[i]<=2;
			     mymem1[3]: mymemk2[i]<=3;
			     mymem1[4]: mymemk2[i]<=4;
			     mymem1[5]: mymemk2[i]<=5;
			     mymem1[6]: mymemk2[i]<=6;
			     mymem1[7]: mymemk2[i]<=7;
			     mymem1[8]: mymemk2[i]<=8;
			     mymem1[9]: mymemk2[i]<=9;
			     mymem1[10]: mymemk2[i]<=10;
			     mymem1[11]: mymemk2[i]<=11;
			     mymem1[12]: mymemk2[i]<=12;
			     mymem1[13]: mymemk2[i]<=13;
			     mymem1[14]: mymemk2[i]<=14;
			  default: mymemk2[i]<=0;		
			  endcase
		  end
		  
		always @(posedge clk) 
		  begin
		     for(i=0;i<3;i=i+1)
		      case (mymems3[i])
			     mymem1[0]: mymemk3[i]<=0;
			     mymem1[1]: mymemk3[i]<=1;
			     mymem1[2]: mymemk3[i]<=2;
			     mymem1[3]: mymemk3[i]<=3;
			     mymem1[4]: mymemk3[i]<=4;
			     mymem1[5]: mymemk3[i]<=5;
			     mymem1[6]: mymemk3[i]<=6;
			     mymem1[7]: mymemk3[i]<=7;
			     mymem1[8]: mymemk3[i]<=8;
			     mymem1[9]: mymemk3[i]<=9;
			     mymem1[10]: mymemk3[i]<=10;
			     mymem1[11]: mymemk3[i]<=11;
			     mymem1[12]: mymemk3[i]<=12;
			     mymem1[13]: mymemk3[i]<=13;
			     mymem1[14]: mymemk3[i]<=14;
			  default: mymemk3[i]<=0;		
			  endcase
		  end
		 
		 always @(posedge clk) 
		   begin//work out S 
			    svalue<=mymem1[(mymemk1[2]+mymemk2[1]+mymemk3[0])%15] ^ mymem1[(mymemk1[1]+mymemk2[0]+mymemk3[2])%15] ^ mymem1[(mymemk1[0]+mymemk2[2]+mymemk3[1])%15] ^ mymem1[(mymemk1[0]+mymemk2[1]+mymemk3[2])%15] ^ mymem1[(mymemk1[2]+mymemk2[0]+mymemk3[1])%15] ^ mymem1[(mymemk1[1]+mymemk2[2]+mymemk3[0])%15];
		
			end
		
		always @(posedge clk) 			
         begin				 
				 if(svalue==0)
			     begin
				     delta1_down <= mymem1[(mymemk1[1]+mymemk1[1])%15] ^ mymem1[(mymemk1[0]+mymemk2[1])%15];
					  delta1_up   <= mymem1[(mymemk2[1]+mymemk2[0])%15] ^ mymem1[(mymemk1[0]+mymemk3[1])%15];
				     delta2_down <= mymem1[(mymemk1[1]+mymemk2[0])%15] ^ mymem1[(mymemk1[0]+mymemk2[1])%15];
					  delta2_up   <= mymem1[(mymemk2[0]+mymemk3[1])%15] ^ mymem1[(mymemk2[1]+mymemk2[1])%15];
				  end
			  else
			     begin  delta1_down = 0;delta1_up = 0;delta2_down = 0;delta2_up = 0; end
			end
		
		always @(posedge clk) 
		  begin
		      case (delta1_down)
			     mymem1[0]: delta1_downk1<=0;
			     mymem1[1]: delta1_downk1<=1;
			     mymem1[2]: delta1_downk1<=2;
			     mymem1[3]: delta1_downk1<=3;
			     mymem1[4]: delta1_downk1<=4;
			     mymem1[5]: delta1_downk1<=5;
			     mymem1[6]: delta1_downk1<=6;
			     mymem1[7]: delta1_downk1<=7;
			     mymem1[8]: delta1_downk1<=8;
			     mymem1[9]: delta1_downk1<=9;
			     mymem1[10]: delta1_downk1<=10;
			     mymem1[11]: delta1_downk1<=11;
			     mymem1[12]: delta1_downk1<=12;
			     mymem1[13]: delta1_downk1<=13;
			     mymem1[14]: delta1_downk1<=14;
			     default: delta1_downk1<=0;		
			  endcase
		  end

		always @(posedge clk) 
		  begin
		      case (delta1_up)
			     mymem1[0]: delta1_upk2<=0;
			     mymem1[1]: delta1_upk2<=1;
			     mymem1[2]: delta1_upk2<=2;
			     mymem1[3]: delta1_upk2<=3;
			     mymem1[4]: delta1_upk2<=4;
			     mymem1[5]: delta1_upk2<=5;
			     mymem1[6]: delta1_upk2<=6;
			     mymem1[7]: delta1_upk2<=7;
			     mymem1[8]: delta1_upk2<=8;
			     mymem1[9]: delta1_upk2<=9;
			     mymem1[10]: delta1_upk2<=10;
			     mymem1[11]: delta1_upk2<=11;
			     mymem1[12]: delta1_upk2<=12;
			     mymem1[13]: delta1_upk2<=13;
			     mymem1[14]: delta1_upk2<=14;
			     default: delta1_upk2<=0;		
			  endcase
		  end
		  
		always @(posedge clk) 
		  begin
		      case (delta2_up)
			     mymem1[0]: delta2_upk3<=0;
			     mymem1[1]: delta2_upk3<=1;
			     mymem1[2]: delta2_upk3<=2;
			     mymem1[3]: delta2_upk3<=3;
			     mymem1[4]: delta2_upk3<=4;
			     mymem1[5]: delta2_upk3<=5;
			     mymem1[6]: delta2_upk3<=6;
			     mymem1[7]: delta2_upk3<=7;
			     mymem1[8]: delta2_upk3<=8;
			     mymem1[9]: delta2_upk3<=9;
			     mymem1[10]: delta2_upk3<=10;
			     mymem1[11]: delta2_upk3<=11;
			     mymem1[12]: delta2_upk3<=12;
			     mymem1[13]: delta2_upk3<=13;
			     mymem1[14]: delta2_upk3<=14;
			     default: delta2_upk3<=0;		
			  endcase
		  end
		  
		always @(posedge clk) 
		  begin
		     delta11<=(delta1_upk2-delta1_downk1+15)%15;
		     delta1=mymem1[delta11];
			  delta22<=(delta2_upk3-delta1_downk1+15)%15;
			  delta2=mymem1[delta22];
        end				  
///////////////////////////////////work out error polynomial////////////////////////////////  

///////////////////////////////////Chien's search///////////////////////////////////////////
		always @(posedge clk) 
		  begin
		     for(i=0;i<15;i=i+1)
			     mymem4[i]=mymem1[(i+1+delta11)%15];			  
		  end
		  
		always @(posedge clk) 
		  begin
		     for(i=0;i<15;i=i+1)
			     mymem5[i]=mymem1[((i+1)*2+delta22)%15];	
		     for(i=0;i<15;i=i+1)
			     mymeme[i]=mymem4[i]^mymem5[i]^(4'b0001);
           for(i=0;i<15;i=i+1)	
              ee[i]=mymeme[14-i];
           				  
		  end
////////////////////////////////////////////////////////////////////////////////////////////		  

///////////////////////////////////correct the error code///////////////////////////////////

		always @(posedge clk) 
		  begin
		    for(i=0;i<15;i=i+1)
		     begin 
             if(ee[i]== 4'b0000)
				    e[i]<=1'b1;
             else
				    e[i]<=1'b0;
          end			  
		  end
		  
		always @(posedge clk) 
           c<=e^r; 
	
endmodule