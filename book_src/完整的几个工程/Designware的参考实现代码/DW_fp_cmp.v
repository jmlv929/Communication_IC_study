
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-point Comparator
//           Compares two FP numbers and generates outputs that indicate when 
//           A>B, A<B and A=B. The component also provides outputs for MAX and 
//           MIN values, with corresponding status flags.
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance 0 or 1
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              zctr            1 bit
//                              defines the min/max operation of z0 and z1
//
//              Output ports    Size & Description
//              ===========     ==================
//              aeqb            1 bit
//                              has value 1 when a=b
//              altb            1 bit
//                              has value 1 when a<b
//              agtb            1 bit
//                              has value 1 when a>b
//              unordered       1 bit
//                              one of the inputs is NaN
//              z0              (sig_width + exp_width + 1) bits
//                              Floating-point Number that has max(a,b) when
//                              zctr=1, and min(a,b) otherwise
//              z1              (sig_width + exp_width + 1) bits
//                              Floating-point Number that has max(a,b) when
//                              zctr=0, and min(a,b) otherwise
//              status0         byte
//                              info about FP value in z0
//              status1         byte
//                              info about FP value in z1
//
// MODIFIED: 
//    4/18 - the ieee_compliance parameter is also controlling the use of nans
//           When 0, the component behaves as the MC component (no denormals
//           and no nans).
//
//
//-------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_fp_cmp (

                   a,
                   b,
                   zctr,
                   aeqb,
                   altb,
                   agtb,
                   unordered,
                   z0,
                   z1,
                   status0,
                   status1

    // Embedded dc_shell script
    // _model_constraint_2
);

parameter sig_width=23;             // RANGE 2 to 253 bits
parameter exp_width=8;              // RANGE 3 to 31 bits
parameter ieee_compliance=0;        // RANGE 0 or 1           


input  [sig_width + exp_width:0] a,b;
input  zctr;
output aeqb, altb, agtb, unordered;
output [sig_width + exp_width:0] z0, z1;
output [7:0] status0, status1;

reg [0:0] diff_signs;
reg [exp_width-1:0] Ea,Eb;
reg [sig_width:0] Ma,Mb;
reg [sig_width-1:0] Fa,Fb;
reg [exp_width+sig_width:0] z0_int,z1_int;
reg [8    -1:0] status0_int,status1_int;
reg agtb_int,aeqb_int,altb_int, unordered_int;
reg Sa, Sb;
reg zer_a, inf_a, nan_a; 
reg zer_b, inf_b, nan_b;
reg zer_exp_a, zer_exp_b;
reg zer_mant_a, zer_mant_b;
reg max_exp_a, max_exp_b;
reg maga_eq_magb, maga_gt_magb, maga_lt_magb;
reg Ea_eq_Eb, Ea_gt_Eb, Ea_lt_Eb;
reg Fa_eq_Fb, Fa_gt_Fb, Fa_lt_Fb;
reg sel;
integer i;
 
always @(a or b)
begin
  unordered_int = 1'b0;
  Ea = a[((exp_width + sig_width) - 1):sig_width];
  Eb = b[((exp_width + sig_width) - 1):sig_width];
 
  zer_exp_a = ~(|Ea);
  zer_exp_b = ~(|Eb);
  max_exp_a = &Ea;
  max_exp_b = &Eb;

  if (ieee_compliance == 0)
    begin
      Fa = a[(sig_width - 1):0];
      Fb = b[(sig_width - 1):0];
      zer_a = zer_exp_a;
      Sa = (zer_exp_a == 1)?1'b0:a[(exp_width + sig_width)];
      zer_b = zer_exp_b;
      Sb = (zer_exp_b == 1)?1'b0:b[(exp_width + sig_width)];
      inf_a = (max_exp_a == 1'b1);
      inf_b = (max_exp_b == 1'b1);
      nan_a = 1'b0;
      nan_b = 1'b0;
    end
  else
    begin
      Fa = a[(sig_width - 1):0];
      Fb = b[(sig_width - 1):0];
      zer_mant_a = ~(|Fa);
      zer_mant_b = ~(|Fb);
      zer_a = (zer_exp_a == 1'b1 && zer_mant_a == 1'b1);
      Sa = (zer_a == 1'b1)?1'b0:a[(exp_width + sig_width)];
      zer_b = (zer_exp_b == 1'b1 && zer_mant_b == 1'b1);
      Sb = (zer_b == 1'b1)?1'b0:b[(exp_width + sig_width)];
      nan_a = (max_exp_a == 1'b1 && zer_mant_a == 1'b0);
      nan_b = (max_exp_b == 1'b1 && zer_mant_b == 1'b0);
      inf_a = (max_exp_a == 1'b1 && zer_mant_a == 1'b1);
      inf_b = (max_exp_b == 1'b1 && zer_mant_b == 1'b1);
    end

  diff_signs = Sa ^ Sb;

  unordered_int = 1'b0;
  if (ieee_compliance)
    if (nan_a == 1'b1 || nan_b == 1'b1)
      begin
        unordered_int = 1'b1;
      end

end

always @ (Ea or Eb or Fa or Fb or unordered_int or diff_signs or Sa or inf_a or inf_b or zer_a or zer_b) 
begin
  agtb_int = 1'b0;
  aeqb_int = 1'b0;
  altb_int = 1'b0;

  maga_eq_magb = 1'b0;
  maga_gt_magb = 1'b0;
  maga_lt_magb = 1'b0;
  Ea_eq_Eb = 1'b0;
  Ea_lt_Eb = 1'b0;
  Ea_gt_Eb = 1'b0;
  Fa_eq_Fb = 1'b0;
  Fa_lt_Fb = 1'b0;
  Fa_gt_Fb = 1'b0;

  if (Fa > Fb)
    Fa_gt_Fb = 1;
  else 
    if (Fa == Fb)
      Fa_eq_Fb = 1;
  else
    Fa_lt_Fb = 1;

  if (Ea > Eb)
    Ea_gt_Eb = 1;
  else 
    if (Ea == Eb)
      Ea_eq_Eb = 1;
  else
    Ea_lt_Eb = 1;

  if (ieee_compliance == 0)
    begin
      if (zer_a == 1'b1 || inf_b == 1'b1)
        Fa_gt_Fb = 0;
      if (zer_b == 1'b1 || inf_a == 1'b1)
        Fa_lt_Fb = 0;
      if (Fa_lt_Fb == 0 && Fa_gt_Fb == 0)
        Fa_eq_Fb = 1;
    end

  maga_gt_magb = Ea_gt_Eb | (Ea_eq_Eb & Fa_gt_Fb);
  maga_eq_magb = Ea_eq_Eb & Fa_eq_Fb;
  maga_lt_magb = Ea_lt_Eb | (Ea_eq_Eb & Fa_lt_Fb);

    if (~unordered_int)
      begin
        if ((~diff_signs && ((~Sa && maga_gt_magb) || (Sa && maga_lt_magb))) || (diff_signs && ~Sa)) 
          agtb_int = 1'b1;
        else if (maga_eq_magb && (diff_signs == 1'b0))
          aeqb_int = 1'b1;
        else
          altb_int = 1'b1;
      end
end

always @ (agtb_int or zctr or zer_a or zer_b or inf_a or inf_b or nan_a or nan_b or unordered_int)
begin
  status0_int = 1'b0;
  status1_int = 1'b0;

  if (ieee_compliance == 1)
    sel = (agtb_int ^ zctr) && ~unordered_int;
  else
    sel = agtb_int ^ zctr;

  if (sel==1'b0)
    begin
      status0_int[7] = 1'b1;
      status0_int[1] = inf_a;
      status0_int[0] = zer_a;
      status0_int[2] = nan_a;
      status1_int[1] = inf_b;
      status1_int[0] = zer_b;
      status1_int[2] = nan_b;
    end
  else
    begin
      status0_int[1] = inf_b;
      status0_int[0] = zer_b;
      status0_int[2] = nan_b;
      status1_int[1] = inf_a;
      status1_int[0] = zer_a;
      status1_int[2] = nan_a;
      status1_int[7] = 1'b1;
    end
end

assign z1 = (a & {exp_width+sig_width+1{sel}}) | (b & {exp_width+sig_width+1{~sel}});
assign z0 = (a & {exp_width+sig_width+1{~sel}}) | (b & {exp_width+sig_width+1{sel}});
assign status0 = status0_int;
assign status1 = status1_int;
assign agtb = agtb_int;
assign aeqb = aeqb_int;
assign altb = altb_int;
assign unordered = unordered_int;

endmodule
