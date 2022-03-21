
////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point MAC (Multiply and Add, a * b + c)
//
//              DW_fp_mac calculates the floating-point multiplication and
//              addition (ab + c),
//              while supporting six rounding modes, including four IEEE
//              standard rounding modes.
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance 0 or 1 (default 0)
//              arch_type       0 or 1 (default 0)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              c               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              rounding mode
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              Floating-point Number result that corresponds
//                              to a*b+c*d
//              status          byte
//                              info about FP results
//
//
// * rtl model is based on DW_fp_dp2.  
//   MAC operation is acquired by DW_fp_dp2(A, B, C, fp(1))
//
// MODIFIED:
//         10/4/06 - includes rounding for denormal values
//         11/15/06 - Several QoR improvements. Biggest gain obtained when 
//                    internal precision was reduced for ieee_compliance = 0
//         11/16/06 - Modified the calculation of exponent values and used
//                    bidirectional shifter to normalize/denormalize    
//         11/22/06 - Fix the detection of internal infinities based on 
//                    rounding modes.
//          5/1/07  - Fix manipulation of sign of zeros
//          7/2/07  - Increased internal precision by one bit when ieee_compliance
//                    is zero. Failing for small precision values.
//          7/2/07  - Fixed size of variable receiving output of LZD module.
//          4/7/08  - AFT : included a new parameter (arch_type) to control
//                    the use of alternative architecture with IFP blocks
//          1/15/09 - AFT : fix bug in the generation of a mask for stk bits
//                    and increases the internal precision in 1 bit. Also, included
//                    logic to avoid tiny=1 when z=MinNorm for some inputs.
//          12/2008 - Fixed problem with test case (10,5,0)
//                    a=9fff b=1bff c=8bff d=2fff rnd=3 z=8400 
//                    simulation model ==> status 20
//                    this code ==> status 28 (problem with tiny bit)
//          12/2008 - Allowed the use of denormals when arch_type = 1
//          05/2011 - The size of variable limited_shdist was extracted from 
//                    sig_width (when ieee_compliance=1) as ceil(log2(3*sig_width+8))+2
//                    This size for some parameter values (such as 5,8,1) would be
//                    smaller than needed to avoid upper bit truncation, and loss of
//                    the sign bit in some cases. We have fixed the size of the shifting
//                    distance for normalization to use more bits and avoid the truncation
//                    Optimizations at the shifter generator level will take care of 
//                    unnecessary MS bits.
//
//-------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 


module DW_fp_mac (

                   a,
                   b,
                   c,
                   rnd,
                   z,
                   status

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute _current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

parameter sig_width    = 23;     // RANGE 2 to 253 bits
parameter exp_width    = 8;      // RANGE 3 to 31 bits
parameter ieee_compliance = 0;   // RANGE 0 or 1
parameter arch_type=0;           // RANGE 0 or 1           
parameter adj_prec = 0;


function [4-1:0] Il011I11l;

  input [2:0] O11O0lOOl;
  input [0:0] l11l11I00;
  input [0:0] l11lI0OOO,OOl1Ol1OO,O1OIlOO01;


  begin
  Il011I11l[0] = 0;
  Il011I11l[1] = OOl1Ol1OO|O1OIlOO01;
  Il011I11l[2] = 0;
  Il011I11l[3] = 0;
  if (1)
  case (O11O0lOOl)
    3'b000:
    begin
      Il011I11l[0] = OOl1Ol1OO&(l11lI0OOO|O1OIlOO01);
      Il011I11l[2] = 1;
      Il011I11l[3] = 0;
    end
    3'b001:
    begin
      Il011I11l[0] = 0;
      Il011I11l[2] = 0;
      Il011I11l[3] = 0;
    end
    3'b010:
    begin
      Il011I11l[0] = ~l11l11I00 & (OOl1Ol1OO|O1OIlOO01);
      Il011I11l[2] = ~l11l11I00;
      Il011I11l[3] = ~l11l11I00;
    end
    3'b011:
    begin
      Il011I11l[0] = l11l11I00 & (OOl1Ol1OO|O1OIlOO01);
      Il011I11l[2] = l11l11I00;
      Il011I11l[3] = l11l11I00;
    end
    3'b100:
    begin
      Il011I11l[0] = OOl1Ol1OO;
      Il011I11l[2] = 1;
      Il011I11l[3] = 0;
    end
    3'b101:
    begin
      Il011I11l[0] = OOl1Ol1OO|O1OIlOO01;
      Il011I11l[2] = 1;
      Il011I11l[3] = 1;
    end
    default:
      ;
  endcase
  end

endfunction


input  [(exp_width + sig_width):0] a;
input  [(exp_width + sig_width):0] b;
input  [(exp_width + sig_width):0] c;
input  [2:0] rnd;
output [8    -1:0] status;
output [(exp_width + sig_width):0] z;


wire [sig_width+exp_width : 0] OOO01O11;
wire [7 : 0] IOO0100O;

wire [sig_width+2+exp_width+6:0] OO10OOIl;
wire [sig_width+2+exp_width+6:0] OOO0110I;
wire [sig_width+2+exp_width+6:0] OOO1l1Ol; 
wire [sig_width+2+exp_width+6:0] I11O0I1O;
wire [(sig_width+2+6)+exp_width+1+6:0] ll1OO0l0, l1lII1I0;
wire [(sig_width+2+6)+1+exp_width+1+1+6:0] I1O11O1O;
wire [(exp_width + sig_width):0] d;
assign d = {2'b00, {(exp_width - 1){1'b1}}, {(sig_width){1'b0}}};


    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U1 ( .a(a), .z(OO10OOIl) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U2 ( .a(b), .z(OOO0110I) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U3 ( .a(c), .z(OOO1l1Ol) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U4 ( .a(d), .z(I11O0I1O) );
    DW_ifp_mult #(sig_width+2, exp_width, (sig_width+2+6), exp_width+1)
	  U5 ( .a(OO10OOIl), .b(OOO0110I), .z(ll1OO0l0) );
    DW_ifp_mult #(sig_width+2, exp_width, (sig_width+2+6), exp_width+1)
	  U6 ( .a(OOO1l1Ol), .b(I11O0I1O), .z(l1lII1I0) );
    DW_ifp_addsub #((sig_width+2+6), exp_width+1, (sig_width+2+6)+1, exp_width+1+1, ieee_compliance)
	  U7 ( .a(ll1OO0l0), .b(l1lII1I0), .op(1'b0), .rnd(rnd),
               .z(I1O11O1O) );
    DW_ifp_fp_conv #((sig_width+2+6)+1, exp_width+1+1, sig_width, exp_width, ieee_compliance)
          U8 ( .a(I1O11O1O), .rnd(rnd), .z(OOO01O11), .status(IOO0100O) );


`define  DW_l01OOl10 (((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>256)?((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>4096)?((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>16384)?((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>32768)?16:15):((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>8192)?14:13)):((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>1024)?((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>2048)?12:11):((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>512)?10:9))):((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>16)?((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>64)?((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>128)?8:7):((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>32)?6:5)):((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>4)?((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>8)?4:3):((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3>2)?2:1))))+1)

wire [8    -1:0] l1IOO01O;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)+1:0] IIOIOO0O, OOO0O0O1;
wire [exp_width-1:0] OIO01101;
wire l1011IO1,lO0llI1O,O1OIlOO01,l1llO010,I1O1001O;
wire [exp_width-1:0] O1100I01,ll0O010O,l1O0I0O0,I11OI1I1; 
wire [exp_width-1:0] lII1OO1O,lOOIl0I1,O00O110l,OOOl111I; 
wire [sig_width-1:0] O1OlO001,OOI0O1Ol,O0l1Il01,I00OIlOl;
wire [sig_width:0] lOIlOOOl,OO11OlOl,Il0OlO0O,O110OO0O;
wire OIO1l101,O11O11l1,Ol110lO1,O1OO0lO0;
wire [(2*sig_width+2)-1:0] lI00OI01, OlOO00I1;
wire [exp_width:0] I0O11101, Il01OO0I;
wire l1011OlO, l01lOllI;
wire [exp_width-1:0] OlO0OOOO;
wire [exp_width-1:0] l1OOl0l1;
wire [exp_width+1:0] I110111l;
wire [exp_width:0] OO0I010O,l1I0IOOO,lOO100O1;
wire signed [exp_width+1:0] IlO11001;
wire [(2*sig_width+2)-1:0] IO1110I0,IOOI0O1O;
wire Oll1IOO0,lO00O0IO;
wire [(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec)-1:0] l10101O0;
wire [(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec)-2:0] O0O11OOO; 
wire [(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec)-2:0] OO1l1101, lOO0OI0O;
wire [(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec)-2:0] lO0O0100;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0] O010O0OO, O000OI11;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0] I1I0000O;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0] I10OI0I0, OO11I1lO;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-1):0] OOO00OO0;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0] O1Il1lO0;
wire l00OOO0l;
wire OO1l000I;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0] lO11O1O0;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0] I01110I1;
wire [(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0] l11OOIOO;
wire [4-1:0] I1Ol1O00;
wire [(exp_width + sig_width + 1)-1:0] O100O0OO;
wire [(exp_width + sig_width + 1)-1:0] I1l00O0l;
wire [(exp_width + sig_width + 1)-1:0] I0l00lll;
wire [(exp_width + sig_width + 1)-1:0] OOI1OlO0;
wire [(exp_width + sig_width + 1)-1:0] OIO0Il0O;
wire [(exp_width + sig_width + 1)-1:0] llO1OOO0, OlOl0000;
wire IO01I1IO, lOO01I10;
wire Il0O1010, OOO100l1, O1l1010I, O1IlO01I;
wire l1OO0O1I, I1Il1O00, Il01llIO, O0Ol011I;
wire I10OlO11, IO0O11OO, llOI11l1, OO01OlOI;
wire IOllOO01, OlOOI01I, II10Ol10, I0l00l1l;
wire [(exp_width + sig_width):0] O10O0OOI, OlI0OO10, O1l01l01;
wire [8    -1:0] O00O1l1O, IlOO0OO0, OOO0OOl0;
wire [`DW_l01OOl10-1:0] OOOI10lI;
wire signed [exp_width+1:0] O0OO0lI1;
wire O10OOOlI;
wire l0I1I00O;
wire lOIII1Il, OI101I00, O0O01OO0;
wire l101I1Ol;
wire l111l1O1, IIII10O1;

  assign l1OOl0l1 = {exp_width{1'b1}};
  assign OlO0OOOO = {{exp_width-1{1'b0}},1'b1};
  assign I1l00O0l = {1'b0,{exp_width{1'b1}},{sig_width{1'b0}}};
  assign O100O0OO[(exp_width + sig_width + 1)-1:1] = {1'b0,{exp_width{1'b1}},{sig_width-1{1'b0}}};
  assign O100O0OO[0] = (ieee_compliance)?1'b1:1'b0;
  assign OIO0Il0O = {1'b1,{sig_width+exp_width{1'b0}}};
  assign llO1OOO0 = {1'b0,{exp_width-1{1'b1}},1'b0,{sig_width{1'b1}}};
  assign OlOl0000 = {1'b1,{exp_width-1{1'b1}},1'b0,{sig_width{1'b1}}};
  assign I0l00lll = {1'b0,l1OOl0l1,{sig_width{1'b0}}};
  assign OOI1OlO0 = {1'b1,l1OOl0l1,{sig_width{1'b0}}};

  assign O1100I01 = a[$unsigned((exp_width + sig_width) - 1):sig_width];
  assign ll0O010O = b[$unsigned((exp_width + sig_width) - 1):sig_width];
  assign l1O0I0O0 = c[$unsigned((exp_width + sig_width) - 1):sig_width];
  assign I11OI1I1 = d[$unsigned((exp_width + sig_width) - 1):sig_width];
  assign O1OlO001 = a[$unsigned(sig_width - 1):0];
  assign OOI0O1Ol = b[$unsigned(sig_width - 1):0];
  assign O0l1Il01 = c[$unsigned(sig_width - 1):0];
  assign I00OIlOl = d[$unsigned(sig_width - 1):0];
  assign OIO1l101 = a[(exp_width + sig_width)];
  assign O11O11l1 = b[(exp_width + sig_width)];
  assign Ol110lO1 = c[(exp_width + sig_width)];
  assign O1OO0lO0 = d[(exp_width + sig_width)];
  assign lO0llI1O = (OIO1l101 ^ O11O11l1) ^ (Ol110lO1 ^ O1OO0lO0);

  assign Il0O1010 = ((O1100I01 == 0) & (O1OlO001 != 0) & (ieee_compliance == 1)); 
  assign OOO100l1 = ((ll0O010O == 0) & (OOI0O1Ol != 0) & (ieee_compliance == 1)); 
  assign O1l1010I = ((l1O0I0O0 == 0) & (O0l1Il01 != 0) & (ieee_compliance == 1)); 
  assign O1IlO01I = ((I11OI1I1 == 0) & (I00OIlOl != 0) & (ieee_compliance == 1)); 
  assign lOIlOOOl = (O1100I01 == 0 & ~Il0O1010)?{sig_width+1{1'b0}}:{~Il0O1010,O1OlO001};
  assign lII1OO1O = (Il0O1010)?{{exp_width-1{1'b0}},1'b1}:O1100I01;
  assign OO11OlOl = (ll0O010O == 0 & ~OOO100l1)?{sig_width+1{1'b0}}:{~OOO100l1,OOI0O1Ol};
  assign lOOIl0I1 = (OOO100l1)?{{exp_width-1{1'b0}},1'b1}:ll0O010O;
  assign Il0OlO0O = (l1O0I0O0 == 0 & ~O1l1010I)?{sig_width+1{1'b0}}:{~O1l1010I,O0l1Il01};
  assign O00O110l = (O1l1010I)?{{exp_width-1{1'b0}},1'b1}:l1O0I0O0;
  assign O110OO0O = (I11OI1I1 == 0 & ~O1IlO01I)?{sig_width+1{1'b0}}:{~O1IlO01I,I00OIlOl};
  assign OOOl111I = (O1IlO01I)?{{exp_width-1{1'b0}},1'b1}:I11OI1I1;


  assign l1OO0O1I = ((O1100I01 == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) & (O1OlO001 != 0) & (ieee_compliance == 1));
  assign I1Il1O00 = ((ll0O010O == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) & (OOI0O1Ol != 0) & (ieee_compliance == 1));
  assign Il01llIO = ((l1O0I0O0 == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) & (O0l1Il01 != 0) & (ieee_compliance == 1));
  assign O0Ol011I = ((I11OI1I1 == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) & (I00OIlOl != 0) & (ieee_compliance == 1));
  assign O00O1l1O[2] = (l1OO0O1I | I1Il1O00 | Il01llIO | O0Ol011I);
  assign O00O1l1O[1] = 1'b0;
  assign O00O1l1O[0] = 1'b0;
  assign O00O1l1O[3] = 1'b0;
  assign O00O1l1O[4] = 1'b0;
  assign O00O1l1O[5] = 1'b0;
  assign O00O1l1O[6] = 1'b0;
  assign O00O1l1O[7] = 1'b0;
  assign O10O0OOI = (O00O1l1O[2])?O100O0OO:{exp_width+sig_width+1{1'b0}};
  assign I10OlO11 = ((O1100I01 == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) & ((O1OlO001 == 0) | (ieee_compliance == 0)));
  assign IO0O11OO = ((ll0O010O == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) & ((OOI0O1Ol == 0) | (ieee_compliance == 0)));
  assign llOI11l1 = ((l1O0I0O0 == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) & ((O0l1Il01 == 0) | (ieee_compliance == 0)));
  assign OO01OlOI = ((I11OI1I1 == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) & ((I00OIlOl == 0) | (ieee_compliance == 0)));
  assign IOllOO01 = ((O1100I01 == 0) & ((O1OlO001 == 0) | (ieee_compliance == 0)));
  assign OlOOI01I = ((ll0O010O == 0) & ((OOI0O1Ol == 0) | (ieee_compliance == 0)));
  assign II10Ol10 = ((l1O0I0O0 == 0) & ((O0l1Il01 == 0) | (ieee_compliance == 0)));
  assign I0l00l1l = ((I11OI1I1 == 0) & ((I00OIlOl == 0) | (ieee_compliance == 0)));
  assign IlOO0OO0[2] = (I10OlO11 & OlOOI01I) | (IO0O11OO & IOllOO01) |
                                        (llOI11l1 & I0l00l1l) | (OO01OlOI & II10Ol10) |
                                        (I10OlO11|IO0O11OO|IO01I1IO) & lO0llI1O & (llOI11l1|OO01OlOI|lOO01I10);
  assign IlOO0OO0[1] = 
               (I10OlO11 | IO0O11OO | llOI11l1 | OO01OlOI | IO01I1IO | lOO01I10) &
               (~IlOO0OO0[2] | (ieee_compliance == 0));
  assign IlOO0OO0[0] = 1'b0;
  assign IlOO0OO0[3] = 1'b0;
  assign IlOO0OO0[4] = ~(I10OlO11 | IO0O11OO | llOI11l1 | OO01OlOI) & 
                                      IlOO0OO0[1] &
                                      ~IlOO0OO0[2];
  assign IlOO0OO0[5] = IlOO0OO0[4] ;
  assign IlOO0OO0[6] = 1'b0;
  assign IlOO0OO0[7] = 1'b0;
  assign OI101I00 = I10OlO11 | IO0O11OO | IO01I1IO;
  assign O0O01OO0 = llOI11l1 | OO01OlOI | lOO01I10;
  assign lOIII1Il = (l1011OlO&OI101I00 | l01lOllI&O0O01OO0);
  assign OlI0OO10 = (IlOO0OO0[2])?O100O0OO:
                    (IlOO0OO0[1]?
                     ((lOIII1Il)?OOI1OlO0:I0l00lll) : {sig_width+exp_width+1{1'b0}});


  assign lI00OI01 = (lOIlOOOl * OO11OlOl);
  assign OlOO00I1 = (Il0OlO0O * O110OO0O);

  assign I0O11101 = (lII1OO1O == 0 || lOOIl0I1 == 0)?{exp_width+1{1'b0}}:
                                           {1'b0,lII1OO1O} + {1'b0,lOOIl0I1};
  assign Il01OO0I = (O00O110l == 0 || OOOl111I == 0)?{exp_width+1{1'b0}}:
                                           {1'b0,O00O110l} + {1'b0,OOOl111I};
  assign l111l1O1 = (IOllOO01 | OlOOI01I);
  assign IIII10O1 = (II10Ol10 | I0l00l1l);
  assign l1011OlO = (ieee_compliance == 1)?
			((l111l1O1 & IIII10O1 & (OIO1l101 ^ O11O11l1 ^ Ol110lO1 ^ O1OO0lO0))?
                                      ((rnd==3)?1'b1:1'b0):(OIO1l101 ^ O11O11l1)) : 
                        ((OIO1l101 ^ O11O11l1) & ~(IOllOO01 | OlOOI01I));
  assign l01lOllI = (ieee_compliance == 1)?
                        ((l111l1O1 & IIII10O1 & (OIO1l101 ^ O11O11l1 ^ Ol110lO1 ^ O1OO0lO0))?
                                      ((rnd==3)?1'b1:1'b0):(Ol110lO1 ^ O1OO0lO0)) :
                        ((Ol110lO1 ^ O1OO0lO0) & ~(II10Ol10 | I0l00l1l));

  assign IO01I1IO = 1'b0;
  assign lOO01I10 = 1'b0;
  
  assign l1011IO1 = (I0O11101 < Il01OO0I);
  assign OO0I010O = (l1011IO1)? Il01OO0I:I0O11101;
  assign IO1110I0 = (l1011IO1)?OlOO00I1:lI00OI01;
  assign Oll1IOO0 = (l1011IO1)?l01lOllI:l1011OlO;
  assign l1I0IOOO = (l1011IO1)?I0O11101:Il01OO0I;
  assign IOOI0O1O = (l1011IO1)?lI00OI01:OlOO00I1;
  assign lO00O0IO = (l1011IO1)?l1011OlO:l01lOllI;

  assign lOO100O1 = OO0I010O - l1I0IOOO;
  assign O0O11OOO = {IOOI0O1O,{((sig_width-1)*ieee_compliance+5+adj_prec)-1{1'b0}}} >> lOO100O1;
  assign OO1l1101 = ~$unsigned(0);
  assign lOO0OI0O = ~(OO1l1101 << lOO100O1);
  assign lO0O0100 = lOO0OI0O & {IOOI0O1O,{((sig_width-1)*ieee_compliance+5+adj_prec)-1{1'b0}}};
  wire O0llO001;
  wire OI101Ol1;
  assign O0llO001 = |lO0O0100;
  assign l10101O0  = {O0O11OOO,O0llO001};
  
  assign I10OI0I0 = {1'b0,IO1110I0,{((sig_width-1)*ieee_compliance+5+adj_prec){1'b0}}};
  assign OO11I1lO = {1'b0,l10101O0};
  assign OOO00OO0 = (lO0llI1O == 0)?
                     I10OI0I0 + OO11I1lO:
                     I10OI0I0 - OO11I1lO;
 
  assign l00OOO0l = OOO00OO0[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-1)];
  assign OO1l000I = l00OOO0l ^ Oll1IOO0;
  assign O1Il1lO0 = (OOO00OO0[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-1)])?~OOO00OO0[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0]+1:
                                                  OOO00OO0[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):0];

  assign lO11O1O0 = O1Il1lO0 >> 2;
  assign IlO11001 = $signed(OO0I010O + {{exp_width+1-2{1'b0}},2'b10}) - $unsigned({exp_width{1'b1}}>>1);

  DW_lzd #(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-3) U9 (.a (lO11O1O0[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-2:0]), .enc(OOOI10lI), .dec());

  assign l101I1Ol = &OOOI10lI & ~|O1Il1lO0[1:0];
  assign O0OO0lI1 = (IlO11001 > $signed(OOOI10lI))?
                           $signed({1'b0,OOOI10lI}):
                           (ieee_compliance == 0 && IlO11001 < $signed({{exp_width-1{1'b0}},1'b1}))?
                             $signed({exp_width+2{1'b0}}):
                             $signed(IlO11001 - {{exp_width+2-1{1'b0}},1'b1});
  wire O01Ol0Ol;
  assign O01Ol0Ol = (ieee_compliance == 1);
  DW01_ash #(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-1, exp_width+2) U10 (
                      .A(lO11O1O0),
                      .DATA_TC(1'b0),
                      .SH(O0OO0lI1),
                      .SH_TC(O01Ol0Ol),
                      .B(I01110I1) );
  
  assign I110111l = ((ieee_compliance == 1 | IlO11001 >= 0) & 
                    ~l101I1Ol)?
                   $unsigned(IlO11001 - O0OO0lI1):{exp_width+2{1'b0}};

  assign O010O0OO = ~$unsigned(0);
  assign O000OI11 = (ieee_compliance == 1 && O0OO0lI1 < 0)?
                   ~(O010O0OO << ~O0OO0lI1):~O010O0OO;
  assign I1I0000O = ((O000OI11 << 1) | 1'b1) & lO11O1O0;
  assign OI101Ol1 = (ieee_compliance == 1)?|I1I0000O:1'b0;
  assign O10OOOlI = ( I01110I1[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-2] == 0 );

  assign l11OOIOO = I01110I1;

  assign l1llO010 = l11OOIOO[((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-(2)-sig_width)];
  assign I1O1001O = l11OOIOO[(((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-(2)-sig_width) - 1)];
  assign O1OIlOO01 = (|l11OOIOO[(((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-(2)-sig_width) - 1)-1:0]) | (|O1Il1lO0[1:0]) | 
                (OI101Ol1 & O10OOOlI);
  assign I1Ol1O00 = Il011I11l(rnd, OO1l000I, l1llO010, I1O1001O, O1OIlOO01);
  assign IIOIOO0O = I1Ol1O00[0] ? l11OOIOO + (1<<((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-(2)-sig_width)): 
                                        l11OOIOO;
  assign l0I1I00O = &l11OOIOO[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-2:((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-(2)-sig_width)] & 
                               I1Ol1O00[0];
  assign OOO0O0O1 = (l0I1I00O)?IIOIOO0O >> 1:IIOIOO0O;
  assign OIO01101 = l0I1I00O + I110111l[exp_width-1:0];
  wire OOOI0lI1;
  assign OOOI0lI1 = (OOO0O0O1[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2):(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-2] == 0) | 
                              (ieee_compliance == 0 & I110111l < 1);

  wire O111lI10;
  assign O111lI10 = OOOI0lI1 & 
                         ~((l111l1O1 & IIII10O1) | (l101I1Ol));

  assign OOO0OOl0[5] = (ieee_compliance == 0 & OOOI0lI1 & ~l101I1Ol) | (I1Ol1O00[1] & O111lI10)  | OOO0OOl0[4];
  assign OOO0OOl0[0] = (~((rnd == 2 & ~OO1l000I) | 
                                       (rnd == 3 & OO1l000I) | 
                                       (rnd == 5)) &
                                      O111lI10 & 
                                      (ieee_compliance == 0)) | 
                                     (OOO0O0O1[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-2:((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-(2)-sig_width)] == 0); 
  assign OOO0OOl0[2] = 1'b0;
  assign OOO0OOl0[1] = (OOO0OOl0[4] &  
                                         I1Ol1O00[2] == 1);
  assign OOO0OOl0[4] = (I110111l >= $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) ||
                                     ((l0I1I00O == 1'b1) && 
                                      (I110111l == $unsigned($unsigned({exp_width{1'b1}}>>1) << 1)));
  assign OOO0OOl0[6] = 1'b0;
  assign OOO0OOl0[7] = 1'b0;
  wire  IIlI1I00;
  assign IIlI1I00 = (ieee_compliance == 0)?
                     (l101I1Ol?((rnd==3)?1'b1:1'b0):OO1l000I):
                     (((l111l1O1 & IIII10O1 & (OIO1l101 ^ O11O11l1 ^ Ol110lO1 ^ O1OO0lO0))|
                       (l101I1Ol & ~(l111l1O1 | IIII10O1)))?
                                      ((rnd==3)?1'b1:1'b0):OO1l000I);
  assign O1l01l01 = (O111lI10 & 
                    ~OOO0OOl0[0] & 
                    (ieee_compliance == 0))?
                   {OO1l000I,{exp_width-1{1'b0}},{1'b1},{sig_width{1'b0}}}:
                   (OOO0OOl0[0]?
                     {IIlI1I00,{exp_width{1'b0}}, {sig_width{1'b0}}}:
                     (OOO0OOl0[1]?
                        (OO1l000I?OOI1OlO0:I0l00lll):
                        (OOO0OOl0[4]?
                          (OO1l000I?OlOl0000:llO1OOO0):
                          {OO1l000I,{exp_width{1'b0}},OOO0O0O1[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-3:((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-(2)-sig_width)]}
                        )
                     )
                   );
  assign OOO0OOl0[3] = O111lI10 & ~|(O1l01l01[$unsigned((exp_width + sig_width) - 1):sig_width]);

  assign l1IOO01O[5] = I1Ol1O00[1];
  assign l1IOO01O[4] = 1'b0;
  assign l1IOO01O[1] = 1'b0;
  assign l1IOO01O[0] = 1'b0;
  assign l1IOO01O[2] = 1'b0;
  assign l1IOO01O[3] = 1'b0;
  assign l1IOO01O[6] = 1'b0;
  assign l1IOO01O[7] = 1'b0;

  assign z = (arch_type == 1)?OOO01O11:
	     (O00O1l1O != 0)?O10O0OOI:
             (IlOO0OO0 != 0)?OlI0OO10:
             (OOO0OOl0 != 0)?O1l01l01:
             {OO1l000I,OIO01101[exp_width-1:0],OOO0O0O1[(((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-3:((((2)+(2*sig_width+2)+((sig_width-1)*ieee_compliance+5+adj_prec))-2)-(2)-sig_width)]};
  assign status = (arch_type == 1)?IOO0100O:
                  (O00O1l1O != 0)?O00O1l1O:
                  (IlOO0OO0 != 0)?IlOO0OO0:
                  (OOO0OOl0 != 0)?OOO0OOl0:
                  l1IOO01O;

`undef DW_l01OOl10

endmodule
