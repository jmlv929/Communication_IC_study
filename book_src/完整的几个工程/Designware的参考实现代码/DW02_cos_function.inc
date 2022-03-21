


//------------------------------------------------------------------------------
//
// ABSTRACT: Simulation Cos function
//           Operand a can be either a signed (two's complement) or
//           unsigned number.
//
//------------------------------------------------------------------------------
//
//  MODIFIED:
//
//              Jay Zhu 10/14/1998
//              STAR 59348
//
//		RJK	7/12/99
//		Coerrected missing index calculation for the case of
//		cos_width = 8 (STAR #75349)
//
//		Rong Fang 7/14/99
//		Added parameter legal range checking
//
//              Aamir Farooqui 6/21/02
//              Corrected parameter checking, X_Processing, and vcs warning
//
//		RJK	7/7/03
//		Reverted A input sizing parameter back to the original name
//		(angle_width) for backward compatibility (STAR 171158)
//
//------------------------------------------------------------------------------

function [cos_width-1:0] DWF_cos;
// synopsys map_to_operator COS_TC_OP
// synopsys return_port_name WAVE

  input	[angle_width-1:0]		A;
//-----------------------------------------------------------------------------
// synopsys translate_off

  parameter	a_width_less3 = (angle_width < 3)? 0 : angle_width-3;
  parameter	a_width_less8 = (angle_width < 8)? 0 : angle_width-8;
  parameter	qw1_c1_p_low_index = (cos_width >= 8 && cos_width <= 16)? 25-cos_width : 0;
  parameter	qw2_c1_p_low_index = (cos_width > 16)? 41-cos_width : 0;
  parameter	qw2_c2_p_low_index = (cos_width > 16)? 35-cos_width : 0;
  parameter	qw3_c1_p_low_index = (cos_width > 24)? 60-cos_width : 0;
  parameter	qw3_c2_p_low_index = (cos_width > 24)? 55-cos_width : 0;
  parameter	qw3_c3_p_low_index = (cos_width > 24)? 48-cos_width : 0;

  reg	[angle_width-1:0]	temp1;
  reg	[angle_width-1:0]	temp2;
  reg			zero,change_sign;
  reg			junk;
  reg	[cos_width-1:0] rounded_value,value;

  reg	[5:0]	loc_addr;
  reg	[25:0]	mod_addr;
  reg	[34:0]	C0;
  reg	[34:0]	qw2_c1_product;
  reg	[41:0]	qw3_low_addr_squared;
  reg	[44:0]	qw3_low_addr_cubed;
  reg	[60:0]	qw3_c1_product;
  reg	[42:0]	qw3_c2_product;
  reg	[34:0]	qw_cos_pos,qw_cos_neg,qw_cos_value;
  reg		error_flag;

  integer		C1_3,C2_3,C3_3,C1_2,C2_2,C1_1;
  integer		c1_3_tmp;
  integer		qw1_c1_product, qw2_low_addr_squared, qw2_c2_product;
  integer		qw3_c3_product;

// synopsys translate_on
   begin
// synopsys translate_off
    if ((^(A ^ A) !== 1'b0))
    begin
      DWF_cos = {cos_width{1'bx}} ;
    end
    else
    begin
    if(angle_width > 2) begin
      temp1 = A;
      change_sign = ^temp1[angle_width-1:angle_width-2];
      zero = (temp1[angle_width-2] && (temp1[a_width_less3:0] == 0));
      if(temp1[angle_width-2])
        temp2[a_width_less3:0] = ~(temp1[a_width_less3:0] - 1'b1);
      else
        temp2[a_width_less3:0] = temp1[a_width_less3:0];

      temp2[angle_width-1:angle_width-2] = 2'b00;
      loc_addr = (angle_width > 7)? temp2[a_width_less3:a_width_less8]: {5'b0,temp2} << (8-angle_width);
      mod_addr = (angle_width > 7)? {26'b0,temp2} << (34-angle_width) : 26'b0;

      case(loc_addr)
	6'd0: begin C0={25'd8388608,10'd0};
			 C1_3=-27; C2_3=2587415; C3_3=260;
			 C1_2=0; C2_2=2526; C1_1=8; end
	6'd1: begin C0={25'd8386081,10'd520};
			 C1_3=5173969; C2_3=2586635; C3_3=779;
			C1_2=5053; C2_2=2525; C1_1=28; end
	6'd2: begin C0={25'd8378503,10'd568};
			 C1_3=10344848; C2_3=2584298; C3_3=1298;
			C1_2=10103; C2_2=2522; C1_1=48; end
	6'd3: begin C0={25'd8365878,10'd720};
			 C1_3=15509496; C2_3=2580403; C3_3=1816;
			C1_2=15147; C2_2=2517; C1_1=67; end
	6'd4: begin C0={25'd8348214,10'd573};
			 C1_3=20664801; C2_3=2574955; C3_3=2333;
			C1_2=20182; C2_2=2511; C1_1=87; end
	6'd5: begin C0={25'd8325521,10'd782};
			 C1_3=25807659; C2_3=2567956; C3_3=2849;
			C1_2=25205; C2_2=2503; C1_1=107; end
	6'd6: begin C0={25'd8297813,10'd1009};
			 C1_3=30934970; C2_3=2559410; C3_3=3363;
			C1_2=30212; C2_2=2494; C1_1=126; end
	6'd7: begin C0={25'd8265107,10'd935};
			 C1_3=36043649; C2_3=2549321; C3_3=3874;
			C1_2=35201; C2_2=2483; C1_1=146; end
	6'd8: begin C0={25'd8227423,10'd255};
			 C1_3=41130615; C2_3=2537698; C3_3=4384;
			C1_2=40169; C2_2=2471; C1_1=165; end
	6'd9: begin C0={25'd8184782,10'd710};
			 C1_3=46192806; C2_3=2524546; C3_3=4891;
			C1_2=45113; C2_2=2458; C1_1=184; end
	6'd10: begin C0={25'd8137211,10'd953};
			 C1_3=51227173; C2_3=2509873; C3_3=5395;
			C1_2=50030; C2_2=2442; C1_1=203; end
	6'd11: begin C0={25'd8084739,10'd631};
			 C1_3=56230682; C2_3=2493687; C3_3=5895;
			C1_2=54916; C2_2=2426; C1_1=222; end
	6'd12: begin C0={25'd8027397,10'd364};
			 C1_3=61200320; C2_3=2476000; C3_3=6392;
			C1_2=59769; C2_2=2408; C1_1=241; end
	6'd13: begin C0={25'd7965219,10'd709};
			 C1_3=66133092; C2_3=2456823; C3_3=6886;
			C1_2=64587; C2_2=2388; C1_1=260; end
	6'd14: begin C0={25'd7898244,10'd79};
			 C1_3=71026030; C2_3=2436164; C3_3=7375;
			C1_2=69366; C2_2=2367; C1_1=279; end
	6'd15: begin C0={25'd7826510,10'd877};
			 C1_3=75876183; C2_3=2414039; C3_3=7860;
			C1_2=74102; C2_2=2345; C1_1=297; end
	6'd16: begin C0={25'd7750063,10'd243};
			 C1_3=80680631; C2_3=2390459; C3_3=8340;
			C1_2=78795; C2_2=2321; C1_1=315; end
	6'd17: begin C0={25'd7668947,10'd277};
			 C1_3=85436481; C2_3=2365438; C3_3=8814;
			C1_2=83439; C2_2=2296; C1_1=333; end
	6'd18: begin C0={25'd7583211,10'd836};
			 C1_3=90140867; C2_3=2338994; C3_3=9284;
			C1_2=88034; C2_2=2269; C1_1=351; end
	6'd19: begin C0={25'd7492908,10'd531};
			 C1_3=94790955; C2_3=2311140; C3_3=9748;
			C1_2=92575; C2_2=2241; C1_1=369; end
	6'd20: begin C0={25'd7398091,10'd792};
			 C1_3=99383944; C2_3=2281895; C3_3=10206;
			C1_2=97061; C2_2=2212; C1_1=386; end
	6'd21: begin C0={25'd7298818,10'd711};
			 C1_3=103917069; C2_3=2251274; C3_3=10658;
			C1_2=101487; C2_2=2182; C1_1=404; end
	6'd22: begin C0={25'd7195149,10'd82};
			 C1_3=108387597; C2_3=2219299; C3_3=11104;
			C1_2=105853; C2_2=2150; C1_1=421; end
	6'd23: begin C0={25'd7087145,10'd385};
			 C1_3=112792837; C2_3=2185986; C3_3=11543;
			C1_2=110156; C2_2=2116; C1_1=437; end
	6'd24: begin C0={25'd6974872,10'd657};
			 C1_3=117130136; C2_3=2151356; C3_3=11975;
			C1_2=114392; C2_2=2082; C1_1=454; end
	6'd25: begin C0={25'd6858398,10'd516};
			 C1_3=121396879; C2_3=2115429; C3_3=12399;
			C1_2=118559; C2_2=2046; C1_1=470; end
	6'd26: begin C0={25'd6737793,10'd127};
			 C1_3=125590497; C2_3=2078230; C3_3=12817;
			C1_2=122654; C2_2=2009; C1_1=486; end
	6'd27: begin C0={25'd6613129,10'd153};
			 C1_3=129708464; C2_3=2039778; C3_3=13226;
			C1_2=126676; C2_2=1971; C1_1=501; end
	6'd28: begin C0={25'd6484481,10'd689};
			 C1_3=133748299; C2_3=2000098; C3_3=13628;
			C1_2=130621; C2_2=1932; C1_1=517; end
	6'd29: begin C0={25'd6351928,10'd192};
			 C1_3=137707570; C2_3=1959212; C3_3=14021;
			C1_2=134488; C2_2=1891; C1_1=532; end
	6'd30: begin C0={25'd6215548,10'd551};
			 C1_3=141583892; C2_3=1917146; C3_3=14406;
			C1_2=138274; C2_2=1849; C1_1=546; end
	6'd31: begin C0={25'd6075424,10'd895};
			 C1_3=145374927; C2_3=1873926; C3_3=14782;
			C1_2=141976; C2_2=1806; C1_1=561; end
	6'd32: begin C0={25'd5931641,10'd616};
			 C1_3=149078394; C2_3=1829578; C3_3=15150;
			C1_2=145593; C2_2=1763; C1_1=575; end
	6'd33: begin C0={25'd5784285,10'd338};
			 C1_3=152692063; C2_3=1784126; C3_3=15508;
			 C1_2=149122; C2_2=1718; C1_1=588; end
	6'd34: begin C0={25'd5633444,10'd841};
			 C1_3=156213755; C2_3=1737601; C3_3=15857;
			 C1_2=152561; C2_2=1672; C1_1=601; end
	6'd35: begin C0={25'd5479210,10'd958};
			 C1_3=159641351; C2_3=1690027; C3_3=16196;
			 C1_2=155909; C2_2=1625; C1_1=614; end
	6'd36: begin C0={25'd5321676,10'd593};
			 C1_3=162972783; C2_3=1641438; C3_3=16526;
			 C1_2=159162; C2_2=1577; C1_1=627; end
	6'd37: begin C0={25'd5160936,10'd658};
			 C1_3=166206048; C2_3=1591857; C3_3=16845;
			 C1_2=162320; C2_2=1528; C1_1=639; end
	6'd38: begin C0={25'd4997087,10'd974};
			 C1_3=169339195; C2_3=1541320; C3_3=17155;
			 C1_2=165380; C2_2=1478; C1_1=651; end
	6'd39: begin C0={25'd4830229,10'd206};
			 C1_3=172370340; C2_3=1489853; C3_3=17454;
			 C1_2=168340; C2_2=1427; C1_1=662; end
	6'd40: begin C0={25'd4660460,10'd923};
			 C1_3=175297654; C2_3=1437490; C3_3=17743;
			 C1_2=171199; C2_2=1376; C1_1=673; end
	6'd41: begin C0={25'd4487885,10'd322};
			 C1_3=178119377; C2_3=1384259; C3_3=18020;
			 C1_2=173955; C2_2=1323; C1_1=684; end
	6'd42: begin C0={25'd4312606,10'd402};
			 C1_3=180833806; C2_3=1330196; C3_3=18288;
			 C1_2=176606; C2_2=1270; C1_1=694; end
	6'd43: begin C0={25'd4134729,10'd736};
			 C1_3=183439309; C2_3=1275331; C3_3=18544;
			 C1_2=179150; C2_2=1216; C1_1=704; end
	6'd44: begin C0={25'd3954362,10'd448};
			 C1_3=185934314; C2_3=1219697; C3_3=18788;
			 C1_2=181587; C2_2=1161; C1_1=713; end
	6'd45: begin C0={25'd3771613,10'd202};
			 C1_3=188317319; C2_3=1163329; C3_3=19022;
			 C1_2=183914; C2_2=1106; C1_1=722; end
	6'd46: begin C0={25'd3586592,10'd79};
			 C1_3=190586889; C2_3=1106261; C3_3=19244;
			 C1_2=186131; C2_2=1050; C1_1=731; end
	6'd47: begin C0={25'd3399410,10'd541};
			 C1_3=192741657; C2_3=1048526; C3_3=19455;
			 C1_2=188235; C2_2=993; C1_1=739; end
	6'd48: begin C0={25'd3210181,10'd309};
			 C1_3=194780324; C2_3=990159; C3_3=19653;
			 C1_2=190226; C2_2=936; C1_1=746; end
	6'd49: begin C0={25'd3019018,10'd392};
			 C1_3=196701663; C2_3=931196; C3_3=19840;
			 C1_2=192102; C2_2=878; C1_1=753; end
	6'd50: begin C0={25'd2826036,10'd941};
			 C1_3=198504516; C2_3=871672; C3_3=20015;
			 C1_2=193864; C2_2=819; C1_1=760; end
	6'd51: begin C0={25'd2631353,10'd161};
			 C1_3=200187797; C2_3=811623; C3_3=20178;
			 C1_2=195508; C2_2=760; C1_1=766; end
	6'd52: begin C0={25'd2435084,10'd375};
			 C1_3=201750493; C2_3=751085; C3_3=20329;
			 C1_2=197034; C2_2=701; C1_1=772; end
	6'd53: begin C0={25'd2237348,10'd790};
			 C1_3=203191662; C2_3=690095; C3_3=20468;
			 C1_2=198441; C2_2=641; C1_1=777; end
	6'd54: begin C0={25'd2038265,10'd493};
			 C1_3=204510436; C2_3=628689; C3_3=20594;
			 C1_2=199729; C2_2=581; C1_1=782; end
	6'd55: begin C0={25'd1837954,10'd426};
			 C1_3=205706019; C2_3=566905; C3_3=20708;
			 C1_2=200896; C2_2=521; C1_1=786; end
	6'd56: begin C0={25'd1636536,10'd242};
			 C1_3=206777694; C2_3=504778; C3_3=20809;
			 C1_2=201943; C2_2=460; C1_1=790; end
	6'd57: begin C0={25'd1434132,10'd274};
			 C1_3=207724814; C2_3=442348; C3_3=20898;
			 C1_2=202868; C2_2=399; C1_1=794; end
	6'd58: begin C0={25'd1230864,10'd442};
			 C1_3=208546808; C2_3=379651; C3_3=20974;
			 C1_2=203671; C2_2=337; C1_1=797; end
	6'd59: begin C0={25'd1026855,10'd173};
			 C1_3=209243181; C2_3=316726; C3_3=21038;
			 C1_2=204351; C2_2=276; C1_1=799; end
	6'd60: begin C0={25'd822227,10'd376};
			 C1_3=209813514; C2_3=253610; C3_3=21089;
			 C1_2=204908; C2_2=214; C1_1=801; end
	6'd61: begin C0={25'd617104,10'd294};
			 C1_3=210257463; C2_3=190341; C3_3=21127;
			 C1_2=205342; C2_2=152; C1_1=803; end
	6'd62: begin C0={25'd411609,10'd497};
			 C1_3=210574761; C2_3=126956; C3_3=21152;
			 C1_2=205652; C2_2=90; C1_1=804; end
	6'd63: begin C0={25'd205866,10'd764};
			 C1_3=210765216; C2_3=63497; C3_3=21165;
			 C1_2=205838; C2_2=28; C1_1=804; end
      endcase

      if((angle_width <= 8) || (cos_width <= 7))
        qw_cos_pos = C0[34:34-cos_width];
      else if(cos_width < 17) begin
        qw1_c1_product = C1_1 * mod_addr[25:17];
        qw_cos_pos     = C0[34:34-cos_width] - qw1_c1_product[18:qw1_c1_p_low_index];
      end
      else if(cos_width < 25) begin
        qw2_c1_product       = C1_2 * mod_addr[25:9];
        qw2_low_addr_squared = mod_addr[25:15] *  mod_addr[25:15];
        qw2_c2_product       = C2_2 * qw2_low_addr_squared[21:11];
        qw_cos_pos           = C0[34:34-cos_width] 
                               - qw2_c1_product[34:qw2_c1_p_low_index]
                               - qw2_c2_product[22:qw2_c2_p_low_index];
      end
      else if(cos_width > 24) begin
        if(C1_3[31]) begin
          c1_3_tmp = ~C1_3 + 1;
          qw3_c1_product = c1_3_tmp * mod_addr[25:0];
          qw3_c1_product = ~(qw3_c1_product -1);
        end
        else
          qw3_c1_product = C1_3 * mod_addr[25:0];
          qw3_low_addr_squared = mod_addr[25:5] *  mod_addr[25:5];
          qw3_c2_product = C2_3 * qw3_low_addr_squared[41:21];
          qw3_low_addr_cubed = qw3_low_addr_squared[41:12] * mod_addr[25:11];
          qw3_c3_product = C3_3 * qw3_low_addr_cubed[44:31];
          qw_cos_pos =      C0[34:34-cos_width]
          - qw3_c1_product[60:qw3_c1_p_low_index]
          - qw3_c2_product[42:qw3_c2_p_low_index]
          + qw3_c3_product[28:qw3_c3_p_low_index];
        end
	qw_cos_neg = ~qw_cos_pos;
	qw_cos_value = change_sign? qw_cos_neg : qw_cos_pos;
	{rounded_value,junk} = qw_cos_value + 1'b1;
	value = (zero)? 0 : rounded_value;
      end
      else if(angle_width == 2) begin
	value = 0;
	case(A)
	  2'b00: value[cos_width-1:cos_width-2] = 2'b01;
	  2'b01: value[cos_width-1:cos_width-2] = 2'b00;
	  2'b10: value[cos_width-1:cos_width-2] = 2'b11;
	  2'b11: value[cos_width-1:cos_width-2] = 2'b00;
	endcase
      end
    DWF_cos = value;
  end
//-----------------------------------------------------------------------------
// synopsys translate_on
end


endfunction


//  unified old inference name
function [cos_width-1:0] cos;

// synopsys map_to_operator COS_TC_OP
// synopsys return_port_name WAVE

input   [angle_width-1:0]       A;

begin
    cos = DWF_cos(A);
end
endfunction
