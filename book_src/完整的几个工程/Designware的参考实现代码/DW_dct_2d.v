
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  ABSTRACT:  
//    This block performs a 2d discrete cosine transform using Chen's
//    factorization. The block performs 2 1d transforms, and writes to
//    an intermediate ram. Please see data sheet for more i/o detail.
//
//
//      Parameters:	Valid Values
//      =====		======
//      bpp		4 - 24   
//      n		4-16 even numbers
//      reg_out 	0/1 register outputs
//      tc_mode 	0/1 input data type-0 is binary, 1 = two's complement
//      rt_mode 	0-1 round/truncate:0= round 1=truncate
//      idct		0/1 forward or inverse dct applied to input data
//      co_a - co_p	coeficient input
//
//      Input Ports:	Size	       Description
//      ============	======         =======================
//        clk		1	       clock input
//        rst_n 	1	       asynchronous reset
//        init_n	1	       synchronous reset
//        enable	1	       enable: 0 stall processing
//        start 	1	       1 clock cycle high starts processing
//        dct_rd_data 	bpp/bpt        read data input, pels or transform data
//        tp_rd_data	1-1/2*bpp+4    transform intermediate data
//
//      Output Ports	Size	Description
//      ============	====== =======================
//        done  	1	       first data block read
//        ready 	1	       first transform available
//        dct_rd_add  	bit width(n)   fetch data address out
//        tp_rd_add	bit width(n)   fetch transpose data address out
//        tp_wr_add	bit width(n)   write transpose data address out
//        tp_wr_n 	1	       transpose data write(not) signal
//        tp_wr_data	n+bpp	       transpose intermediate data out
//        dct_wr_add  	bit width(n)   write data out
//        dct_wr_n  	1	       final data write(not) signal
//        dct_wr_data  	n/2+bpp        final transformed data out(dct or pels)
//
//
//
//
//
//  MODIFIED:
//           jbd original synthesis model 0707
//
//
////////////////////////////////////////////////////////////////////////////////
module DW_dct_2d(
                    clk,
                    rst_n,
                    init_n,
                    enable,
                    start,
                    dct_rd_data,
		    tp_rd_data,
		    done,
                    ready,
                    dct_rd_add,
		    tp_rd_add,
		    tp_wr_add,
		    tp_wr_n,
		    tp_wr_data,
                    dct_wr_add,
                    dct_wr_n,
                    dct_wr_data
  // Embedded dc_shell script
  // _model_constraint_2
  // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
		  );
  parameter bpp = 8; // sample size 'bits per pixel'.
  parameter n   = 8; // Size of block element transformed
  parameter reg_out = 0; // register outputs = 1
  parameter tc_mode = 0; // treat input data of DCT as unsigned/signed
  parameter rt_mode = 0; // round data or truncate
  parameter idct_mode = 0;  // direction of transform 
  parameter co_a = 23170 ;
  parameter co_b = 32138 ;
  parameter co_c = 30274 ;
  parameter co_d = 27245 ;
  parameter co_e = 18205 ;
  parameter co_f = 12541 ;
  parameter co_g = 6393  ;
  parameter co_h = 35355 ;
  parameter co_i = 49039 ;
  parameter co_j = 46194 ;
  parameter co_k = 41573 ;
  parameter co_l = 27779 ;
  parameter co_m = 19134 ;
  parameter co_n = 9755  ;
  parameter co_o = 35355 ;
  parameter co_p = 49039 ;

// tick defines for various buses 
 // define forward data size forward dct data width
 `define fwrdsz (tc_mode ? bpp:(bpp+1))
 //define final data size (write data bus width)
 `define fnldat  (idct_mode == 1) ? bpp: (n/2+bpp)
 // define read data bus width
 `define rddatsz ((idct_mode == 1) ? (n/2+bpp) : bpp)
 // width of first adder 
 `define frstadr ((idct_mode == 1) ? (bpp/2+bpp+1) : ((`fwrdsz) +1))
 // intermediate data width
 `define idatsz (bpp/2+bpp+4  + ((1-tc_mode)*(1-idct_mode)))
 //first multiplier width
 `define prodsum0 ((`frstadr) + 17)
 //second(2d) mult width
 `define prodsum1 ((`idatsz) + 16)
 
 `define initregsz (idct_mode ? (`rddatsz):(n*(`rddatsz)))
 `define xfregsz   (idct_mode ? (n/2*(`prodsum0)): (n/2*(`frstadr)))

 `define scndregsz (idct_mode ? (`idatsz):(n*(`idatsz)))
 `define scndxfregsz   (idct_mode ? (n/2*(`prodsum1)): (n/2*((`idatsz)+1)))
 `define pidatsz (idct_mode ? (`idatsz)+1:(n*(`idatsz)))
  
 `define ppsdwire0 (idct_mode ? (n/2*(`prodsum0)):(`rddatsz)) 
 `define ppsdwire1 (idct_mode ? (n/2*(`prodsum1)):(`idatsz)) 
 
 `define nwidth ((n>16)?((n>64)?((n>128)?8:7):((n>32)?6:5)):((n>4)?((n>8)?4:3):((n>2)?2:1)))
 `define addwidth ((n*n>16)?((n*n>64)?((n*n>128)?8:7):((n*n>32)?6:5)):((n*n>4)?((n*n>8)?4:3):((n*n>2)?2:1)))

  input            clk;             //clock input
  input		   rst_n;           //Asynchronous reset
  input		   init_n;          //synchronous reset
  input		   enable;          // enable: Freezes operation at last datum
  input		   start;           // pulse high 1cc, starts transform
  input  [(`rddatsz)-1:0] dct_rd_data;    // input data to be transformed
  input  [(`idatsz)-1:0]  tp_rd_data; // input intermediate (1d) data
  
  output	   done;           //all n*n samples read
  output	   ready;          // first transformed output ready
  output [`addwidth-1:0] dct_rd_add;     // fetch data for transform
  output [`addwidth-1:0] tp_rd_add;  // fetch data from transPOSE ram
  output [`addwidth-1:0] tp_wr_add;  // write data to transpose ram
  output                 tp_wr_n;    // write data transpose write enable(not)
  output [(`idatsz)-1:0] tp_wr_data; // 1D transformed data write to tp ram
  output [`addwidth-1:0] dct_wr_add;     // final 2D output address
  output                 dct_wr_n;     // final write (not)
  output [(`fnldat)-1:0] dct_wr_data;     // transposed data out

//These are the coefficients used in the transform, 
//assembled as wires. The assembly happens during
//elaboration, not during operation. So none of the
//coefficient manipulation happens in sythesys.
  wire [(n/2*16)-1:0] coef_wire0;  
  wire [(n/2*16)-1:0] coef_wire1;  
  wire [(n/2*16)-1:0] coef_wire2;  
  wire [(n/2*16)-1:0] coef_wire3;  
  wire [(n/2*16)-1:0] coef_wire4;  
  wire [(n/2*16)-1:0] coef_wire5;  
  wire [(n/2*16)-1:0] coef_wire6;  
  wire [(n/2*16)-1:0] coef_wire7;  
  wire [(n/2*16)-1:0] coef_wire8;  
  wire [(n/2*16)-1:0] coef_wire9;  
  wire [(n/2*16)-1:0] coef_wire10;  
  wire [(n/2*16)-1:0] coef_wire11;  
  wire [(n/2*16)-1:0] coef_wire12;  
  wire [(n/2*16)-1:0] coef_wire13;  
  wire [(n/2*16)-1:0] coef_wire14;  
  wire [(n/2*16)-1:0] coef_wire15;
//gen_coef assigns the appropriate coef to the wire, 
//according to the block size and coefficient list  
  assign coef_wire0 = gen_fcoef(0);  
  assign coef_wire1 = gen_fcoef(1);  
  assign coef_wire2 = gen_fcoef(2);  
  assign coef_wire3 = gen_fcoef(3);  
  assign coef_wire4 =  n > 4 ? gen_fcoef(4):{(n/2*16){1'b0}};  
  assign coef_wire5 =  n > 4 ? gen_fcoef(5):{(n/2*16){1'b0}};  
  assign coef_wire6 =  n > 6 ? gen_fcoef(6):{(n/2*16){1'b0}};  
  assign coef_wire7 =  n > 6 ? gen_fcoef(7):{(n/2*16){1'b0}};  
  assign coef_wire8 =  n > 8 ? gen_fcoef(8):{(n/2*16){1'b0}};  
  assign coef_wire9 =  n > 8 ? gen_fcoef(9):{(n/2*16){1'b0}};  
  assign coef_wire10 =  n > 10 ? gen_fcoef(10):{(n/2*16){1'b0}};  
  assign coef_wire11 =  n > 10 ? gen_fcoef(11):{(n/2*16){1'b0}};  
  assign coef_wire12 =  n > 12 ? gen_fcoef(12):{(n/2*16){1'b0}};  
  assign coef_wire13 =  n > 12 ? gen_fcoef(13):{(n/2*16){1'b0}};  
  assign coef_wire14 =  n > 14 ? gen_fcoef(14):{(n/2*16){1'b0}};  
  assign coef_wire15 =  n > 14 ? gen_fcoef(15):{(n/2*16){1'b0}};  
//Follows are the 'inverse' coefficients to do the idct
//function:
  wire [(n/2*16)-1:0] coefp_wire0;  
  wire [(n/2*16)-1:0] coefp_wire1;  
  wire [(n/2*16)-1:0] coefp_wire2;  
  wire [(n/2*16)-1:0] coefp_wire3;  
  wire [(n/2*16)-1:0] coefp_wire4;  
  wire [(n/2*16)-1:0] coefp_wire5;  
  wire [(n/2*16)-1:0] coefp_wire6;  
  wire [(n/2*16)-1:0] coefp_wire7;  
  wire [(n/2*16)-1:0] coefp_wire8;  
  wire [(n/2*16)-1:0] coefp_wire9;  
  wire [(n/2*16)-1:0] coefp_wire10;  
  wire [(n/2*16)-1:0] coefp_wire11;  
  wire [(n/2*16)-1:0] coefp_wire12;  
  wire [(n/2*16)-1:0] coefp_wire13;  
  wire [(n/2*16)-1:0] coefp_wire14;  
  wire [(n/2*16)-1:0] coefp_wire15;
  assign coefp_wire0 = gen_icoef(0);  
  assign coefp_wire1 = gen_icoef(1);  
  assign coefp_wire2 = gen_icoef(2);  
  assign coefp_wire3 = gen_icoef(3);  
  assign coefp_wire4 =  n > 4 ? gen_icoef(4):{(n/2*16){1'b0}};  
  assign coefp_wire5 =  n > 4 ? gen_icoef(5):{(n/2*16){1'b0}};  
  assign coefp_wire6 =  n > 6 ? gen_icoef(6):{(n/2*16){1'b0}};  
  assign coefp_wire7 =  n > 6 ? gen_icoef(7):{(n/2*16){1'b0}};  
  assign coefp_wire8 =  n > 8 ? gen_icoef(8):{(n/2*16){1'b0}};  
  assign coefp_wire9 =  n > 8 ? gen_icoef(9):{(n/2*16){1'b0}};  
  assign coefp_wire10 =  n > 10 ? gen_icoef(10):{(n/2*16){1'b0}};  
  assign coefp_wire11 =  n > 10 ? gen_icoef(11):{(n/2*16){1'b0}};  
  assign coefp_wire12 =  n > 12 ? gen_icoef(12):{(n/2*16){1'b0}};  
  assign coefp_wire13 =  n > 12 ? gen_icoef(13):{(n/2*16){1'b0}};  
  assign coefp_wire14 =  n > 14 ? gen_icoef(14):{(n/2*16){1'b0}};  
  assign coefp_wire15 =  n > 14 ? gen_icoef(15):{(n/2*16){1'b0}};  
 
//these wires satisfy lint, 
  wire [`nwidth:0]   ninc;
  wire [`nwidth:0]   halfn;
  wire [`addwidth:0] blksz;
  wire [`nwidth:0]   nincm1;
  wire [`addwidth:0] blkszm1;

  assign ninc    = n[`nwidth:0];
  assign halfn   = n[`nwidth:0]/2;
  assign blksz   = ninc * ninc;
  assign nincm1  = n[`nwidth:0] - 1'b1;
  assign blkszm1 = ninc * nincm1;
  
// read data state machine
  wire          ready_nxt;
  reg           ready_int;
  wire          done_nxt;
  reg           done_int;
  wire		int_rst;

  reg  [n:0]           rd_pipe;
  wire [n:0]           rd_pipe_nxt;
  reg                  rd_mode;
  reg  [`addwidth-1:0] rd_state;
  wire [`addwidth-1:0] rd_add;
  wire [`addwidth-1:0] rd_state_nxt;
  wire [`addwidth-1:0] rd_add_col_nxt;
  wire [`nwidth-1:0]   rd_add_row_nxt;
  reg  [`addwidth-1:0] rd_add_col_int;
  reg  [`nwidth-1:0]   rd_add_row_int;
  wire [`addwidth-1:0] rd_add_nxt;
  wire                 rd_run;
  wire                 rd_st_eq;
  wire                 rd_rst_ql;
  wire                 rd_rst_en;
  wire                 rd_start;
  wire                 rd_mode_nxt;
  
  assign rd_mode_nxt = rd_start ? 1'b1 : rd_rst_en  ? 1'b0 : rd_mode;
  assign rd_start    = start;// fix for start pulse
  assign rd_run      = enable && rd_mode || start;
  assign rd_st_eq    = rd_state == blksz - 1'b1;
  assign rd_rst_en   = rd_rst_ql || int_rst;// internal reset qualified for timing
  assign rd_rst_ql   = rd_st_eq && 1'b1;// qual for reset
  assign rd_state_nxt = rd_rst_en ? {`addwidth {1'b0}} : rd_run ? rd_state +1'b1 : rd_state;
  assign rd_add      = rd_mode ? rd_state:{`addwidth {1'b0}};
  assign rd_pipe_nxt = {rd_pipe[n-1:0], start};
  
  assign rd_add_col_nxt = rd_rst_en || (rd_add_col_int == blkszm1 && rd_add_row_int == nincm1)? {`addwidth{1'b0}} :
                          rd_run ? rd_add_col_int + ninc:  rd_add_col_int;
  assign rd_add_row_nxt = rd_rst_en ||(rd_add_row_nxt == nincm1 && rd_add_col_int == nincm1) ? {`nwidth{1'b0}} :
                          ( rd_run && rd_add_col_int == blkszm1 )? rd_add_row_int + 1'b1: rd_add_row_int;
  assign rd_add_nxt = idct_mode ? rd_add_col_int + rd_add_row_int : rd_state;

  assign int_rst = start && rd_state != 1'b0;

  assign done_nxt = rd_state == blksz-1;

 
  reg  [`addwidth-1:0] tp_wr_state;
  wire [`addwidth-1:0] tp_wr_state_nxt;
  wire [`addwidth-1:0] tp_wr_add_wire;
  reg  [n:0]           tp_wr_pipe;
  wire [n:0]           tp_wr_pipe_nxt;
  reg   tp_wr_mode;
  wire  tp_wr_start;
  wire  tp_wr_run;
  wire  tp_wr_rst_mode;
  wire  tp_wr_rst_en;
  wire  tp_wr_state_rst;
  wire  tp_wr_mode_nxt;
  
  assign tp_wr_mode_nxt  = tp_wr_start ? 1'b1 : tp_wr_rst_en  ? 1'b0 : tp_wr_mode;
  assign tp_wr_run       = tp_wr_mode && enable;
  assign tp_wr_start     = rd_add == n;//rd_pipe[n-1];
  assign tp_wr_rst_en    = tp_wr_add_wire == blksz -1;
  assign tp_wr_rst_mode  = tp_wr_rst_en && ! tp_wr_start;
  assign tp_wr_state_rst = (int_rst || tp_wr_rst_en)|| tp_wr_state == blkszm1;// || start;
  assign tp_wr_state_nxt = tp_wr_state_rst ? {`addwidth{1'b0}} : tp_wr_run ? tp_wr_state + ninc:tp_wr_state;
  assign tp_wr_pipe_nxt  = {tp_wr_pipe[n-1:0], tp_wr_start};

  reg  [`nwidth-1:0]  cstate;
  wire [`nwidth-1:0]  cstate_nxt;
  reg  [n:0]          cmode;
  wire [n:0]          cmode_nxt;
  wire                cmode_en;

  assign cstate_nxt = idct_mode ? (cstate == nincm1 || (!tp_wr_mode && !rd_mode) ? {`nwidth{1'b0}} : cstate +1'b1)
                      : (cstate == nincm1 || rd_mode == 1'b0 ? {`nwidth{1'b0}} : cstate + 1'b1);
  //assign cmode_nxt  = idct_mode ? {cmode[n-1:0],tp_wr_mode} :
  assign cmode_nxt  =   {cmode[n-1:0],rd_mode};
  assign cmode_en   = cmode[4];
  
  reg   [`nwidth-1:0] tp_wr_col_state;
  reg   [n:0]         tp_wr_col_pipe;
  wire  [n:0]         tp_wr_col_pipe_nxt;
  wire  [`nwidth-1:0] tp_wr_col_state_nxt;
  wire                tp_wr_col_rst;
  wire                tp_wr_col_start;
  
  assign tp_wr_col_start     =  tp_wr_state == blkszm1;// fix for start pulse
  assign tp_wr_col_pipe_nxt  = {tp_wr_pipe[n-1:0],tp_wr_start};
  assign tp_wr_col_rst       = (int_rst || tp_wr_col_state == nincm1) && tp_wr_rst_en;
  assign tp_wr_col_state_nxt = tp_wr_col_rst ? {`nwidth{1'b0}}: 
                              tp_wr_col_start ? tp_wr_col_state +1'b1 : tp_wr_col_state;

  assign tp_wr_add_wire       = tp_wr_col_state + tp_wr_state;

  //reg   [n:0]         coef_add_pipe;
  //wire  [n:0]         coef_add_pipe_nxt;
  reg  [`nwidth-1:0]  coef_add_int;
  wire [`nwidth-1:0]  coef_add_nxt;
  wire                coef_add_rst;
    
  //assign coef_add_pipe_nxt = {coef_add_pipe[n-1:0],cmode[5]};
  assign coef_add_rst      = (coef_add_int == nincm1);
  assign coef_add_nxt      = coef_add_rst  ? {`nwidth{1'b0}} 
                            :  (tp_wr_mode  ? coef_add_int +1'b1 : coef_add_int);


  reg  signed [(`prodsum0):0]  idata_sum;
  wire signed [(`prodsum0):0]  idata_sum_rnd;
  wire  [(`idatsz)-1:0] yrnd;
  wire  [(`idatsz)-1:0] ytrnc;
  wire  [(`idatsz)-1:0] ydbg;
  wire signed [(`prodsum0):0] rndnum;

  assign rndnum = 1'b1 << ((`prodsum0)-(`idatsz));
  assign ydbg = idata_sum[`prodsum0:17];// >>> 16;
  assign idata_sum_rnd = idata_sum[`prodsum0] ?  idata_sum - rndnum : idata_sum + rndnum;
  assign yrnd  = idata_sum[`prodsum0:(11 + (1-tc_mode))];// >>> (11 + (1-tc_mode));
  assign ytrnc = idata_sum_rnd[`prodsum0:(`prodsum0-(`idatsz))+1'b1];
  //assign ytrnc     = $signed(idata_sum[`idatsz+11:11]);

//assign tp_wr_data = ytrnc;//idata_sum_rnd[`prodsum0:`prodsum0-`idatsz+1];
  
  reg                  tp_rd_mode;
  reg  [n:0]           tp_rd_pipe;
  reg  [`addwidth-1:0] tp_rd_state;
  wire                 tp_rd_tgl_nxt;
  reg                  tp_rd_tgl;
  wire [n:0]           tp_rd_pipe_nxt;
  wire [`addwidth-1:0] tp_rd_add_wire;
  wire [`addwidth-1:0] tp_rd_state_nxt;
  reg  [`nwidth-1:0]   tp_rd_cmode;
  wire [`nwidth-1:0]   tp_rd_cmode_nxt;
  wire                 tp_rd_st_eq;
  wire                 tp_rd_run;
  wire                 tp_rd_rst_ql;
  wire                 tp_rd_rst_en;
  wire                 tp_rd_start;
  wire                 tp_rd_mode_nxt;
  wire                 tp_rd_update;
  
  assign tp_rd_pipe_nxt = {tp_rd_pipe[n-1:0], tp_rd_run};
  assign tp_rd_mode_nxt = tp_rd_start ? 1'b1 : tp_rd_rst_en  ? 1'b0 : tp_rd_mode;
  assign tp_rd_start    = tp_wr_add_wire == 3*ninc-2;
  assign tp_rd_run      = enable && tp_rd_mode;//(tp_rd_mode || tp_rd_start);//(tp_rd_mode || tp_rd_start);
  assign tp_rd_st_eq    = tp_rd_state == blksz-1;
  assign tp_rd_state_nxt = tp_rd_rst_en ? {`addwidth{1'b0}} : tp_rd_run  ? tp_rd_state +1'b1:tp_rd_state;
  assign tp_rd_add_wire      = tp_rd_run ? tp_rd_state:{`addwidth{1'b0}};
  assign tp_rd_rst_ql   = tp_rd_st_eq && 1'b1;// qual for reset
  assign tp_rd_rst_en   = tp_rd_rst_ql || int_rst;// internal reset qualified for timing
  assign tp_rd_update   = tp_rd_pipe[0];
  assign tp_rd_tgl_nxt  = tp_rd_update ? ! tp_rd_tgl:1'b0;
  assign tp_rd_cmode_nxt = !tp_rd_update || tp_rd_cmode == nincm1 ?  {`nwidth{1'b0}} :
                            tp_rd_run  ? tp_rd_cmode +1'b1:tp_rd_cmode;


  reg                  wr_mode;
  wire [`nwidth-1:0] tp_rd_cadd_nxt;
  reg                tp_rd_cadd_tgl;
  wire               tp_rd_cadd_tgl_nxt;
  wire               tp_rd_cadd_start;
  reg                tp_rd_cadd_mode;
  reg  [`nwidth-1:0] tp_rd_cadd_int;
  wire               tp_rd_cadd_rst;
  wire               tp_rd_cadd_run;
  //reg  [n:0]         tp_rd_cadd_pipe;
  //wire [n:0]         tp_rd_cadd_pipe_nxt;
  wire               tp_rd_cadd_mode_nxt;
  
  //assign tp_rd_cadd_pipe_nxt = {tp_rd_cadd_pipe[n-1:0], tp_rd_mode};//cadd_start};
  assign tp_rd_cadd_mode_nxt =  wr_mode;//tp_rd_cadd_pipe[7];//tp_rd_cadd_start ? 1 :  tp_rd_st_eq ? 0 : tp_rd_cadd_mode;

  assign tp_rd_cadd_run      = enable && wr_mode;//tp_rd_cadd_mode;
  assign tp_rd_cadd_rst      = int_rst || tp_rd_cadd_int == nincm1;
  assign tp_rd_cadd_nxt      = tp_rd_cadd_rst ? {`nwidth{1'b0}} 
                              : tp_rd_cadd_run ? tp_rd_cadd_int +1'b1
			                        :tp_rd_cadd_int;

  assign tp_rd_cadd_tgl_nxt = tp_rd_cadd_run ? !tp_rd_cadd_tgl : 1'b0;
 

  reg  [n:0]           wr_pipe;
  wire [n:0]           wr_pipe_nxt;
  reg  [`addwidth-1:0] wr_state;
  reg  [`addwidth-1:0] wr_state_int;
  reg  [`addwidth-1:0] wr_state_out;
  wire [`addwidth-1:0] wr_state_nxt;
  wire [`nwidth-1:0]   wr_add_rwcnt_nxt;
  wire [`addwidth-1:0] wr_add_col_nxt;
  reg  [`nwidth-1:0]   wr_add_rwcnt_int;
  reg  [`addwidth-1:0] wr_add_col_int;
  reg  [`addwidth-1:0] wr_add_int;
  wire [`addwidth-1:0] wr_add_nxt;
  reg                  wr_run_int;
  wire                 wr_rst;
  wire                 wr_mode_rst;
  wire                 wr_run;
  wire                 wr_start;
  wire                 wr_mode_nxt;
  wire                 wr_rst_en;
  wire                 wr_out;
  reg                  wr_out_int;
  wire                 wr_reg_xfr_en;
  
  assign wr_start      = tp_rd_add_wire == n;// +1 ;
  assign wr_mode_nxt  = wr_start ? 1'b1 : wr_rst  ? 1'b0 : wr_mode;
  assign wr_rst       = (int_rst || (wr_state_int == blksz-1));
  assign wr_run       = enable && wr_mode;
  assign wr_state_nxt = wr_rst ? {`addwidth{1'b0}} : wr_run ? wr_state_int +1'b1 : wr_state_int;
  assign wr_out       = wr_run  && !(wr_state_int == blksz-1);
  
  assign wr_add_col_nxt =  int_rst || wr_add_col_int == blkszm1 ? {`addwidth{1'b0}} 
                            : wr_run ? wr_add_col_int + ninc
			    : wr_add_col_int;
  assign wr_add_rwcnt_nxt = int_rst || (wr_add_rwcnt_int == nincm1 && wr_add_col_int == blkszm1) ? {`nwidth{1'b0}} :
                        ( wr_run && wr_add_col_int == blkszm1 )? wr_add_rwcnt_int+1'b1: wr_add_rwcnt_int;
  assign wr_add_nxt = idct_mode == 0 ? wr_add_col_int + wr_add_rwcnt_int : wr_state_int;
  assign wr_pipe_nxt = {wr_pipe[n-1:0], (wr_add_col_nxt == 0 && wr_out == 1'b1)};//{wr_pipe[n-1:0], wr_start};
  assign wr_reg_xfr_en = ( wr_run && wr_add_col_nxt == blkszm1 )|| (tp_rd_add_wire == n  || tp_rd_add_wire == blksz );
   
  assign ready_nxt = wr_state_nxt == 1'b1;//dct_wr_n == 0 && wr_state_nxt == 1;

  wire signed [(`prodsum1)-1:0] fnl_sum;
  reg  signed [(`prodsum1)-1:0] fnl_sum_idct;
  reg  signed [(`prodsum1)-1:0] fnl_sum_fdct;
  reg  signed [(`fnldat)-1:0]   ydctsave_int;
  wire signed [(`fnldat)-1:0]   ydctrnd;
  wire signed [(`fnldat)-1:0]   ydcttrnc;
  wire signed [(`fnldat):0]     ydcthld;

  wire signed [(`fnldat)-1:0]   ydctsave;
  wire signed [(`fnldat)-1:0]   ydctdbg;
  wire signed [(`prodsum1)-1:0] ydctrnd_wire;
  wire signed [(`prodsum1)-1:0] fnl_rnd;

  assign fnl_sum = idct_mode ? fnl_sum_idct:fnl_sum_fdct;
  assign fnl_rnd = 1'b1 << ((`prodsum1)-(`fnldat)-1)-((bpp-1)*idct_mode);
  //assign fnl_rnd = idct_mode ? 1'b1 << 16: 1'b1 << ((`prodsum1)-(`fnldat)-1);//bpp/2+12;
  assign ydcthld = fnl_sum[(`prodsum1)-1:(`prodsum1)-(`fnldat)-1];
  assign ydctrnd_wire =  fnl_sum[(`prodsum1)-1] ? $signed(fnl_sum - fnl_rnd) : $signed(fnl_sum + fnl_rnd);

  assign ydcttrnc = idct_mode ? $signed(fnl_sum[(`fnldat)+16:17]) 
                    : $signed(fnl_sum[(`prodsum1)-1:(`prodsum1)-(`fnldat)]);//>>> 17);
  assign ydctrnd  = idct_mode ? $signed(ydctrnd_wire[(`fnldat)+16:17])
                    :$signed(ydctrnd_wire[(`prodsum1)-1:(`prodsum1)-(`fnldat)]);//>>>17);//;
  assign ydctsave = ydcttrnc;
  //$signed(fnl_sum[(`prodsum1)-1:(`prodsum1)-(`fnldat)]);//rt_mode  ? ydcttrnc : ydctrnd; 

  assign ydctdbg = $signed(fnl_sum[(`fnldat)+16:17]);// >>> (`prodsum1)-(`fnldat);//20 ; // prec: 16 bits + round 3 bits

  reg  [(`initregsz)-1:0] rx0;
  wire [(`initregsz)-1:0] rx0_nxt;
  reg  [((`xfregsz))-1:0] rxs0;
  reg  [((`xfregsz))-1:0] rxs1;
  reg  [((`xfregsz))-1:0] rxd0;
  reg  [((`xfregsz))-1:0] rxd1;
  wire [((`xfregsz))-1:0] rxs0_nxt;
  wire [((`xfregsz))-1:0] rxs1_nxt;
  wire [((`xfregsz))-1:0] rxd0_nxt;
  wire [((`xfregsz))-1:0] rxd1_nxt;
  reg  [(`frstadr)-1:0]   rxs0_nxt_wire;
  reg  [(`frstadr)-1:0]   rxd0_nxt_wire;
  
  reg [n/2*(`prodsum0)-1:0] pp0_nxt_wire;
  wire [((`xfregsz))-1:0] rxd0_wire;

  assign rx0_nxt    = idct_mode ? (rd_mode || start ? dct_rd_data:rx0)
                      :rd_mode || start ? {rx0[(`initregsz)-bpp-1:0],dct_rd_data}:rx0;

  assign rxd0_wire  = idct_mode ? (((rd_mode || tp_wr_mode) && (cstate > 1 )) ? rxd0 : {`xfregsz{1'b0}})
                    : {`prodsum0{1'b0}};
  
  assign rxs0_nxt   = idct_mode ? ((rd_mode || tp_wr_mode) ? (pp0_nxt_wire): rxs0)
                      : cstate >= halfn  ? {rxs0_nxt_wire,rxs0[(`xfregsz)-1:(`frstadr)]} : rxs0;
  assign rxd0_nxt   = idct_mode ? rxs0 //(rd_mode && (cstate == 0 ||cstate == nincm1) ? 0 : rxs0)
                      : cstate >= halfn  ? {rxd0_nxt_wire,rxd0[(`xfregsz)-1:(`frstadr)]} : rxd0;

  assign rxs1_nxt   = idct_mode ? ((rd_mode || tp_wr_mode) && (cstate == nincm1) ? rxd0_nxt : rxs1)
                     :cstate == nincm1 && cmode[1] ? rxs0_nxt : rxs1;
  assign rxd1_nxt   = idct_mode ? ((rd_mode || tp_wr_mode) && (cstate == nincm1) ? rxs0_nxt : rxd1)
                     :cstate == nincm1 && cmode[1] ? rxd0_nxt : rxd1;
  
  reg  [(`scndregsz)-1:0]    ry0;
  reg  [(`scndregsz)-1:0]    ry1;
  wire [(`scndregsz)-1:0]    ry0_nxt;
  wire [(`scndregsz)-1:0]    ry1_nxt;
  reg  [(`scndxfregsz)-1:0] rys0;
  reg  [(`scndxfregsz)-1:0] rys1;
  reg  [(`scndxfregsz)-1:0] ryd0;
  reg  [(`scndxfregsz)-1:0] ryd1;
  wire [(`scndxfregsz)-1:0] rys0_nxt;
  wire [(`scndxfregsz)-1:0] rys1_nxt;
  wire [(`scndxfregsz)-1:0] ryd0_nxt;
  wire [(`scndxfregsz)-1:0] ryd1_nxt;
   
  reg  [(`idatsz):0]  rys0_nxt_wire;
  reg  [(`idatsz):0]  ryd0_nxt_wire;
  wire [(`idatsz)-1:0]  ry0_nxt_wire;
  //wire [(`idatsz)-1:0]  rys0_nxt_dbg;
  reg  [(`scndxfregsz)-1:0] pp1_nxt_wire;
  //`define scndregsz (idct_mode ? (`idatsz):(n*(`idatsz)))
  //`define scndxfregsz   (idct_mode ? (n/2*(`prodsum1)): (n/2*((`idatsz)+1)))
  //`define pidatsz (idct_mode ? (`idatsz)+1:(n*(`idatsz)))
  //assign rys0_nxt_dbg = rys0_nxt_wire;
  
  assign ry0_nxt_wire = tp_rd_data;
  
  assign ry0_nxt  = idct_mode ? ry0_nxt_wire
                             :tp_rd_mode ? {ry0[`pidatsz-(`idatsz)-1:0],tp_rd_data}:ry0;

  assign rys0_nxt = idct_mode ? ((tp_rd_mode|| wr_mode)  ? pp1_nxt_wire : rys0)
                     :tp_rd_cmode >= halfn  ? {rys0_nxt_wire,rys0[(`scndxfregsz)-1:(`idatsz)+1'b1]} : rys0;

  assign ryd0_nxt = idct_mode ? rys0 
                     :tp_rd_cmode >= halfn  ? {ryd0_nxt_wire,ryd0[(n/2*((`idatsz)+1))-1:(`idatsz)+1]} : ryd0;

  assign rys1_nxt = idct_mode ? ((tp_rd_mode || wr_mode) && (tp_rd_cmode == nincm1 ) ? ryd0_nxt : rys1)
                     :tp_rd_cmode == nincm1 ? rys0_nxt:rys1;
  assign ryd1_nxt = idct_mode ? ((tp_rd_mode || wr_mode) && (tp_rd_cmode == nincm1)  ? rys0_nxt : ryd1)
                     :tp_rd_cmode == nincm1 ? ryd0_nxt:ryd1;

  // flops
  always @ (posedge clk or negedge rst_n) begin : STATE_SEQ_PROC
    if(rst_n == 1'b0) begin
      ready_int    <= 1'b0;
      done_int     <= 1'b0;
      cstate       <= {`nwidth{1'b0}};
      cmode        <= {n{1'b0}};
      //coef_add_pipe <= {n{1'b0}};
      coef_add_int <= {`nwidth{1'b0}};
      rd_pipe      <= {n{1'b0}};
      rd_state     <= {`addwidth{1'b0}};
      rd_add_col_int <= {`addwidth{1'b0}};
      rd_add_row_int <= {`nwidth{1'b0}};
      rx0          <= {(`initregsz){1'b0}};
      rxs0         <= {(`xfregsz){1'b0}};
      rxs1         <= {(`xfregsz){1'b0}};
      rxd0         <= {(`xfregsz){1'b0}};
      rxd1         <= {(`xfregsz){1'b0}};
      
      ry0          <= {(`initregsz){1'b0}};
      rys0         <= {(`scndxfregsz){1'b0}};
      rys1         <= {(`scndxfregsz){1'b0}};
      ry1          <= {(`scndxfregsz){1'b0}};
      ryd0         <= {(`scndxfregsz){1'b0}};
      ryd1         <= {(`scndxfregsz){1'b0}};
      
      tp_wr_state  <= {`addwidth-1{1'b0}};
      tp_wr_pipe <= {n{1'b0}};
      tp_wr_col_state <= {`nwidth-1{1'b0}};
      tp_wr_col_pipe   <= {n{1'b0}};
      tp_rd_pipe    <= {n{1'b0}};
      tp_rd_state   <= {`addwidth-1{1'b0}};
      tp_rd_tgl       <= 1'b0;
      tp_rd_cmode     <= {`nwidth-1{1'b0}};
      tp_rd_cadd_int  <= {`nwidth-1{1'b0}};
      //tp_rd_cadd_pipe <= {n{1'b0}};
      ydctsave_int    <= {(`fnldat){1'b0}};
      done_int        <= 1'b0;
      rd_mode         <= 1'b0;
      tp_wr_mode      <= 1'b0;
      tp_rd_mode      <= 1'b0;
      tp_rd_cadd_tgl  <= 1'b0;
      tp_rd_cadd_mode <= 1'b0;
      // write solution regs
      wr_pipe     <= {n{1'b0}};
      wr_state    <= {`addwidth-1{1'b0}};
      wr_mode     <= 1'b0;
      wr_run_int     <= 1'b0;
      wr_out_int <= 1'b0;
      wr_state_int    <= {`addwidth-1{1'b0}};
      wr_state_out    <= {`addwidth-1{1'b0}};
      wr_add_int <= {`addwidth-1{1'b0}};
      wr_add_col_int <= {`addwidth-1{1'b0}};
      wr_add_rwcnt_int <= {`addwidth{1'b0}};
    end else if(init_n == 1'b0) begin
      ready_int    <= 1'b0;
      done_int     <= 1'b0;
      cstate       <= {`nwidth{1'b0}};
      cmode        <= {n{1'b0}};
      //coef_add_pipe <= {n{1'b0}};
      coef_add_int <= {`nwidth{1'b0}};
      rd_pipe      <= {n{1'b0}};
      rd_state     <= {`addwidth{1'b0}};
      rd_add_col_int <= {`addwidth{1'b0}};
      rd_add_row_int <= {`nwidth{1'b0}};
      rx0          <= {(`initregsz){1'b0}};
      rxs0         <= {(`xfregsz){1'b0}};
      rxs1         <= {(`xfregsz){1'b0}};
      rxd0         <= {(`xfregsz){1'b0}};
      rxd1         <= {(`xfregsz){1'b0}};
      
      ry0          <= {(`initregsz){1'b0}};
      rys0         <= {(`scndxfregsz){1'b0}};
      rys1         <= {(`scndxfregsz){1'b0}};
      ry1          <= {(`scndxfregsz){1'b0}};
      ryd0         <= {(`scndxfregsz){1'b0}};
      ryd1         <= {(`scndxfregsz){1'b0}};
      
      tp_wr_state  <= {`addwidth-1{1'b0}};
      tp_wr_pipe <= {n{1'b0}};
      tp_wr_col_state <= {`nwidth-1{1'b0}};
      tp_wr_col_pipe   <= {n{1'b0}};
      tp_rd_pipe    <= {n{1'b0}};
      tp_rd_state   <= {`addwidth-1{1'b0}};
      tp_rd_tgl       <= 1'b0;
      tp_rd_cmode     <= {`nwidth-1{1'b0}};
      tp_rd_cadd_int  <= {`nwidth-1{1'b0}};
      //tp_rd_cadd_pipe <= {n{1'b0}};
      ydctsave_int    <= {(`fnldat){1'b0}};
      done_int        <= 1'b0;
      rd_mode         <= 1'b0;
      tp_wr_mode      <= 1'b0;
      tp_rd_mode      <= 1'b0;
      tp_rd_cadd_tgl  <= 1'b0;
      tp_rd_cadd_mode <= 1'b0;
      // write solution regs
      wr_pipe     <= {n{1'b0}};
      wr_state    <= {`addwidth-1{1'b0}};
      wr_mode     <= 1'b0;
      wr_run_int     <= 1'b0;
      wr_out_int <= 1'b0;
      wr_state_int    <= {`addwidth-1{1'b0}};
      wr_state_out    <= {`addwidth-1{1'b0}};
      wr_add_int <= {`addwidth-1{1'b0}};
      wr_add_col_int <= {`addwidth-1{1'b0}};
      wr_add_rwcnt_int <= {`addwidth{1'b0}};
    end else begin // init == 1 and rst_n = 1
      ready_int <= ready_nxt;
      done_int     <= done_nxt;

      rd_pipe  <=  rd_pipe_nxt;
      rd_state <=  rd_state_nxt;
      cstate   <=  cstate_nxt;
      rd_mode  <=  rd_mode_nxt;
      rd_add_col_int <= rd_add_col_nxt;
      rd_add_row_int <= rd_add_row_nxt;
      cmode    <=  cmode_nxt;
      rx0      <=  rx0_nxt;
      coef_add_int <=  coef_add_nxt;
      //coef_add_pipe <= coef_add_pipe_nxt;
      tp_wr_mode      <= tp_wr_mode_nxt;
      tp_wr_state <=  tp_wr_state_nxt;
      tp_wr_pipe <=  tp_wr_pipe_nxt;
      
      tp_wr_col_state <= tp_wr_col_state_nxt;
      tp_wr_col_pipe <=  tp_wr_col_pipe_nxt;
      tp_rd_mode      <= tp_rd_mode_nxt;
      tp_rd_cadd_mode <= tp_rd_cadd_mode_nxt;
      tp_rd_pipe     <=  tp_rd_pipe_nxt;
      tp_rd_state    <=  tp_rd_state_nxt;
      tp_rd_tgl      <=  tp_rd_tgl_nxt;
      tp_rd_cmode    <=  tp_rd_cmode_nxt;
      tp_rd_cadd_int <=  tp_rd_cadd_nxt;
      //tp_rd_cadd_pipe <=  tp_rd_cadd_pipe_nxt;

       
      rxs0 <=  rxs0_nxt;
      rxs1 <=  rxs1_nxt;
      rxd0 <=  rxd0_nxt;
      rxd1 <=  rxd1_nxt;
      ry0  <=  ry0_nxt;
      ry1  <=  ry1_nxt;

      rys0 <=  rys0_nxt;
      rys1 <=  rys1_nxt;
      ryd0 <=  ryd0_nxt;
      ryd1 <=  ryd1_nxt;
      
      wr_pipe   <=  wr_pipe_nxt;
      wr_state  <=  wr_state_nxt;
      wr_mode     <= wr_mode_nxt;
      wr_add_col_int <= wr_add_col_nxt;
      wr_add_rwcnt_int <= wr_add_rwcnt_nxt;
      wr_add_int <= wr_add_nxt;
      wr_run_int     <= wr_run;
      wr_state_int <= wr_state_nxt;
      wr_state_out    <= wr_state_int;
      wr_out_int <= wr_out;
      
      ydctsave_int  <=  ydctsave;
    end // not reset    
  end // flops 

// first forward DCT
// sum and diff of input for dct
  always @ (rx0 or cstate ) begin : FIRST_DCT_SUMDIFF_PROC
  reg [(`fwrdsz)-1:0] xl,xh;
  reg [(`fwrdsz):0] xs,xd;
  reg [`nwidth:0]   halfn_reg;
  
  integer i,j,k;
  xs = {(`fwrdsz)+1{1'b0}};
  xd = {(`fwrdsz)+1{1'b0}};
  rxs0_nxt_wire = 0;
  rxd0_nxt_wire = 0;
  halfn_reg   = n[`nwidth:0]/2;
    if(idct_mode == 1'b0) begin
      if(cstate >= halfn_reg) begin
        for(i=0;i<(`fwrdsz);i=i+1) begin
          j = (2*cstate-n+1)*bpp +i;
  	if(i == bpp && tc_mode == 0)
  	  xh[i] = 1'b0;
  	else
            xh[i] = rx0[j];
        end
        if(tc_mode == 0)
          xl = {1'b0,rx0[bpp-1:0]};
        else
          xl = {rx0[bpp-1],rx0[bpp-1:0]};
        //xs = $signed(xh) + $signed(xl);
        //xd = $signed(xh) - $signed(xl);
        rxs0_nxt_wire = $signed(xh) + $signed(xl);
        rxd0_nxt_wire = $signed(xh) - $signed(xl);
        //$display ("syn: cstate %d xl %x xh %x xs %x xd %x",cstate,xl,xh,xs,xd);
      end //cstate
    end // dct mode no
  end // end of first add su
  
// first forward IDCT
// first products for idct
  always @ (rx0 or cstate or tp_wr_mode or rd_mode or rxd0_wire) begin : FIRST_IDCT_PRODSUM_PROC
  // idct regs
  reg  [15:0] cf;
  reg signed  [(`rddatsz)-1:0] xsd;
  reg signed [(`prodsum0)-1:0] PPy;
  reg signed [(`prodsum0)-1:0] pr_pp;
  reg           [(n/2*16)-1:0] coef1;
  integer i,j,k;
    //follows for idct
  PPy = {(`prodsum0){1'b0}};
  pr_pp	 = {(`prodsum0){1'b0}};
  xsd = 0;
  cf  = 0;
  coef1 = 0;
  if(idct_mode) begin // end idct_mode == 0,start idct_mode = 1     
      pp0_nxt_wire = {n/2*(`prodsum0){1'b0}};
    if(tp_wr_mode || rd_mode) begin
      xsd = rx0;//[`rddatsz-1:0];
        coef1 = get_fcoef(cstate);
      for(i=0;i<n/2;i=i+1) begin
        for(j=0;j<16;j=j+1) begin
          k = (i * 16) +j;
          cf[j] = coef1[k];//get_fcoef(cstate);
        end
        for(j=0;j<`prodsum0;j=j+1) begin
          k = (i * ((`prodsum0))) +j;
          pr_pp[j] = rxd0_wire[k];//get_fcoef(cstate);
        end
        PPy = $signed(xsd) * $signed(cf) + $signed(pr_pp);//temp remove for examine
	pp0_nxt_wire = {PPy,pp0_nxt_wire[n/2*(`prodsum0)-1:(`prodsum0)]};
        //$display("cstate %d syn: data %d coef %d ppy %d ppe %d pr_pp %d",cstate,$signed(xsd),$signed(cf),PPy,pp0_nxt_wire, pr_pp);
       //$display("%d : %d * %d + %d = %d",cstate,$signed(xsd),$signed(cf), pr_pp,PPy);
      end // for i = 0
    end else begin // rd_mode == 1
      pp0_nxt_wire = {n/2*(`prodsum0){1'b0}};
    end // tp_wr_mode == 0
  end // end idct mode
  
end   

// first forward DCT
// prodsum of sum/diff
  always @ (rxs1 or rxd1 or coef_add_int or tp_wr_mode) begin : FIRST_DCT_PRODSUM_PROC
  integer i,j,k;
  reg  [15:0] cf;
  reg  [(`frstadr)-1:0] xsd;
  reg signed [(`prodsum0)-1:0] PPy;
  reg [(n/2*16)-1:0] coef1;
    reg signed [(`prodsum0):0] rndnum_reg;

    rndnum_reg = 1'b1 << ((`prodsum0)-(`idatsz));
  PPy = {(`prodsum0)+1{1'b0}};
  xsd = 0;
  if(idct_mode == 1'b0) begin
    coef1 = get_fcoef(coef_add_int);
    idata_sum = {`prodsum0{1'b0}};
    if(tp_wr_mode)begin
      for(i=0;i<n/2;i=i+1) begin
        for(j=0;j<(`frstadr);j=j+1) begin
          k = (i * ((`frstadr))) +j;
          if(coef_add_int[0])
            xsd[j] = rxd1[k];
          else
            xsd[j] = rxs1[k];
   	 //$display("j %d k %d",j,k);
        end
        for(j=0;j<16;j=j+1) begin
          k = (i * 16) +j;
          cf[j] = coef1[k];
        end
        PPy = PPy + $signed(xsd) * $signed(cf);
      //$display("cmode %d syn: data %d coef %d ppy %d",coef_add_int,$signed(xsd),$signed(cf),PPy);
      end
    if(PPy[`prodsum0-1] == 0)
      idata_sum = PPy + rndnum_reg;
    else
      idata_sum = PPy - rndnum_reg;//~((~(temp_ppy-1) + rndnum)+1);
      
      //idata_sum = PPy;
    end else
      idata_sum = {`prodsum0{1'b0}};
  end // idct_mode
  end // FIRST_DCT
 
// first idct
// final sum and difference for idct
  always @ (rxs1 or rxd1 or coef_add_int or tp_wr_mode) begin : FIRST_IDCT_SUMDIFF_PROC
  // for idct follows
   integer i,j,k;
   reg [(`prodsum0)-1:0] yl,yh;
    reg signed [(`prodsum0):0] ys,yd;
    reg [(`xfregsz)-1:0] temp_rxs1;
    reg [(`xfregsz)-1:0] temp_rxd1;
    reg [`nwidth:0]   halfn_reg;
    reg signed [(`prodsum0):0] rndnum_reg;

    rndnum_reg = 1'b1 << ((`prodsum0)-(`idatsz));
    yl = {(`prodsum0){1'b0}};
    yh = {(`prodsum0){1'b0}};
    ys = {(`prodsum0)+1{1'b0}};
    yd = {(`prodsum0)+1{1'b0}};
    halfn_reg   = n[`nwidth:0]/2;
    
   if(idct_mode) begin // end dct mode, begin idct mode
   temp_rxs1 = rxs1;
   temp_rxd1 = rxd1;
     if(tp_wr_mode) begin
       if(coef_add_int < halfn_reg) begin
         for(i=0;i<(`prodsum0);i=i+1) begin
	   j = (((`xfregsz)-1) - (coef_add_int*(`prodsum0)-1))+i- (`prodsum0);
           yh[i] = rxs1[j];
           yl[i] = rxd1[j];
         end
           idata_sum = $signed(yl) + $signed(yh);
          //$display("add %d yl %d + yh %d = idata_sum %d",coef_add_int,$signed(yl),$signed(yh),$signed(idata_sum));
       end else begin
         for(i=0;i<(`prodsum0);i=i+1) begin
	 j = (coef_add_int-halfn_reg)*(`prodsum0)+i;
           yl[i] = rxs1[j];
           yh[i] = rxd1[j];
	   //$display("i %d j %d ",i,j);
         end
        idata_sum = $signed(yl) - $signed(yh);
        //$display("add %d yl %d - yh %d = idata_sum %d",coef_add_int,$signed(yl),$signed(yh),$signed(idata_sum));
       end
     if(idata_sum[`prodsum0] == 1'b0)
       idata_sum = idata_sum + rndnum_reg;
     else
       idata_sum = idata_sum - rndnum_reg;//~((~(temp_ppy-1) + rndnum)+1);
     end else
       idata_sum = 0;
   end // idct_mode == 1
 end

// 2nd forward DCT
// sum and diff of dct_wr_dataa
  always @ (ry0 or tp_rd_cmode) begin : SECOND_DCT_SUMDIFF_PROC
    reg [(`idatsz)-1:0] yl,yh;
    reg signed [(`idatsz):0] ys,yd;
    reg [`nwidth:0]   halfn_reg;
    integer i,j;
    yl = {(`idatsz){1'b0}};
    yh = {(`idatsz){1'b0}};
    ys = {(`idatsz)+1{1'b0}};
    yd = {(`idatsz)+1{1'b0}};
    halfn_reg   = n[`nwidth:0]/2;
    //$display("ry0 %x",ry0);
  rys0_nxt_wire = 0;
  ryd0_nxt_wire = 0;
  if(idct_mode == 1'b0) begin
    if(tp_rd_cmode >= halfn_reg) begin
       for(i=0;i<(`idatsz);i=i+1) begin
        j = ((2*tp_rd_cmode-n)+1)*(`idatsz) +i;
	yh[i] = ry0[j];
       end
       yl = $signed(ry0[(`idatsz)-1:0]);
       rys0_nxt_wire = $signed(yh) + $signed(yl);
       ryd0_nxt_wire = $signed(yh) - $signed(yl);
      end        
    end else begin // idct mode
    end // idct_mode == 1
  end   
// 2nd forward DCT
// prodsum
  always @ (rys1 or ryd1 or tp_rd_cadd_int or wr_mode) begin : SECOND_DCT_PRODUSM_PROC
    integer i,j,k;
    reg  [15:0] cf;
    reg  [(`idatsz):0] ysd;
    reg signed [(`prodsum1)-1:0] PPy;
    reg [(n/2*16)-1:0] coef2;
    reg signed [(`prodsum1)-1:0] fnl_rnd_reg;
    fnl_rnd_reg = 1'b1 << ((`prodsum1)-(`fnldat)-1)-((bpp-1)*idct_mode);
    coef2 = get_fcoef(tp_rd_cadd_int);
    //$display("rys1:%d ryd1,%d",rys1,ryd1);
    PPy = 0;
    ysd = 0;
    PPy = {(`prodsum1){1'b0}};
      fnl_sum_fdct = {`prodsum1{1'b0}};
    if(wr_mode) begin
      if(idct_mode == 1'b0) begin
        for(i=0;i<n/2;i=i+1) begin
          for(j=0;j<=(`idatsz);j=j+1) begin
            k = (i * ((`idatsz)+1)) +j;
  	  //$display(" i %d j %d k %d",i,j,k);
            if(tp_rd_cadd_int[0])
              ysd[j] = ryd1[k];
            else
              ysd[j] = rys1[k];
          end
          for(j=0;j<16;j=j+1) begin
            k = (i * 16) +j;
            cf[j] = coef2[k];
          end
          PPy = PPy + $signed(ysd) * $signed(cf);
  	//$display("y %x c %x ppy %d",$signed(ysd), $signed(cf),PPy);
        end
        if(rt_mode == 1'b0)
          if(PPy[(`prodsum1)-1] == 1'b0)
  	    fnl_sum_fdct = PPy + fnl_rnd_reg;
  	  else
  	    fnl_sum_fdct = PPy - fnl_rnd_reg;
        else
          fnl_sum_fdct = PPy;
      end else //idct_mode
        fnl_sum_fdct = {`prodsum1{1'b0}};
    end else // wr_mode
        fnl_sum_fdct = {`prodsum1{1'b0}};
  end

// 2nd IDCT
// second products for idct
  always @ (ry0 or tp_rd_cmode or tp_rd_mode or ryd0 or wr_mode) begin : SCND_IDCT_PRODSUM_PROC
  // idct regs
  reg  [15:0] cf;
  reg signed  [(`idatsz)-1:0] xsd;
  reg signed [(`prodsum1)-1:0] PPy;
  reg signed [(`prodsum1)-1:0] pr_pp;
  reg           [(n/2*16)-1:0] coef1;
  integer i,j,k;
  
  //follows for idct
  PPy = {(`prodsum1)-1{1'b0}};
  xsd = 0;
  cf  = 0;
  coef1 = 0;
  if(idct_mode) begin // end idct_mode == 0,start idct_mode = 1     
      pp1_nxt_wire = {n/2*(`prodsum1){1'b0}};
    if(tp_rd_mode || wr_mode) begin
      xsd = ry0;//[`idatsz-1:0];
        coef1 = get_fcoef(tp_rd_cmode);
      for(i=0;i<n/2;i=i+1) begin
        for(j=0;j<16;j=j+1) begin
          k = (i * 16) +j;
          cf[j] = coef1[k];//get_fcoef(cstate);
        end
        for(j=0;j<`prodsum1;j=j+1) begin
          k = (i * (`prodsum1)) +j;
	  if(tp_rd_cmode > 1) 
            pr_pp[j] = ryd0[k];//get_fcoef(cstate);
	  else
            pr_pp[j] = 1'b0;//ryd0[k];//get_fcoef(cstate);
        end
	  
        PPy = $signed(xsd) * $signed(cf) + $signed(pr_pp);//temp remove for examine
	pp1_nxt_wire = {PPy,pp1_nxt_wire[(`scndxfregsz)-1:(`prodsum1)]};
        //$display("tp_rd_cmode %d syn: data %d coef %d ppy %d ppe %d pr_pp %d",tp_rd_cmode,$signed(xsd),$signed(cf),PPy,pp1_nxt_wire, pr_pp);
       //$display("%d : %d * %d + %d = %d",tp_rd_cmode,$signed(xsd),$signed(cf), pr_pp,PPy);
      end 
    end else begin // rd_mode == 1
      pp1_nxt_wire = {n/2*(`prodsum1){1'b0}};
    end 
  end // end idct mode
end   

// final sum and difference for idct
  always @ (rys1 or ryd1 or tp_rd_cadd_int or tp_rd_mode or wr_mode) begin : SCND_IDCT_SUMDIFF_PROC
  // for idct follows
    integer i,j,k;
    reg      [(`prodsum1)-1:0] yl,yh;
    reg signed [(`prodsum1)-1:0] ys,yd;
    reg       [(`xfregsz)-1:0] temp_rys1;
    reg       [(`xfregsz)-1:0] temp_ryd1;
    reg [`nwidth:0]   halfn_reg;
    reg signed [(`prodsum1)-1:0] fnl_rnd_reg;
    fnl_rnd_reg = 1'b1 << ((`prodsum1)-(`fnldat)-1)-((bpp-1)*idct_mode);
    yl = {(`prodsum1){1'b0}};
    yh = {(`prodsum1){1'b0}};
    ys = {(`prodsum1){1'b0}};
    yd = {(`prodsum1){1'b0}};
    halfn_reg   = n[`nwidth:0]/2;
    
    fnl_sum_idct = {`prodsum1{1'b0}};   
    if(idct_mode) begin // end dct mode, begin idct mode
    temp_rys1 = rys1;
    temp_ryd1 = ryd1;
      if( wr_mode) begin
        if(tp_rd_cadd_int < halfn_reg)begin
          for(i=0;i<(`prodsum1);i=i+1) begin
 	   j = (((`scndxfregsz)-1) - (tp_rd_cadd_int*(`prodsum1)-1))+i- (`prodsum1);
            yh[i] = rys1[j];
            yl[i] = ryd1[j];
          end
          fnl_sum_idct = $signed(yl) + $signed(yh);
          //$display("add %d yl %d + yh %d = fnl_sum %d",tp_rd_cmode,$signed(yl),$signed(yh),$signed(fnl_sum));
        end else begin
          for(i=0;i<(`prodsum1);i=i+1) begin
 	   j = (tp_rd_cadd_int-halfn_reg)*(`prodsum1)+i;
            yl[i] = rys1[j];
            yh[i] = ryd1[j];
 	   //$display("i %d j %d ",i,j);
          end
          fnl_sum_idct = $signed(yl) - $signed(yh);
         //$display("add %d yl %d - yh %d = fnl_sum %d",tp_rd_cmode,$signed(yl),$signed(yh),$signed(fnl_sum));
        end // if tp_rd_cadd_int < halfn_reg == n/2.....
        if(rt_mode == 1'b0)
          if(fnl_sum_idct[`prodsum1-1] == 1'b0)
            fnl_sum_idct = fnl_sum_idct + fnl_rnd_reg;
          else
            fnl_sum_idct = fnl_sum_idct - fnl_rnd_reg;
      end else
        fnl_sum_idct = {`prodsum1{1'b0}};   
   end  //else// idct_mode == 1
 end

// port assigns
  assign done  = reg_out ? done_int : done_nxt;
  assign ready = reg_out ? ready_int : ready_nxt;
  assign dct_rd_add  = rd_add_nxt;
  assign tp_wr_add  = tp_wr_add_wire;
  assign tp_wr_data = idata_sum[`prodsum0:`prodsum0-`idatsz+1];
  assign tp_rd_add  = tp_rd_add_wire;
  assign tp_wr_n    = !tp_wr_run;
  assign dct_wr_n  = reg_out ? !wr_run_int : !wr_run;
  assign dct_wr_add  = reg_out ? wr_add_int:wr_add_nxt;//wr_state;//cadd_int;
  assign dct_wr_data  = reg_out ? ydctsave_int:ydctsave;
 
// Functions follow

function [(n/2*16) - 1:0]gen_fcoef;
input[`nwidth-1:0] linenum;
integer cnt,ploop,cindx;
reg [n/2*4-1:0] coefsel;
reg [n/2-1:0]   signbit;
reg [15:0]    coefin;
reg [3:0]      indx;
reg            tsign;
reg [(n/2*16)-1:0]  tempcoef;
reg [((n+1)*16)-1:0] coefi_parms;

begin

  case (n)
     4 : coefi_parms = {co_e[15:0],co_d[15:0],co_c[15:0],co_b[15:0],co_a[15:0]};
     6 : coefi_parms = {co_g[15:0],co_f[15:0],co_e[15:0],co_d[15:0],
                        co_c[15:0],co_b[15:0],co_a[15:0]};
     8 : coefi_parms = {co_i[15:0],co_h[15:0],co_g[15:0],co_f[15:0],co_e[15:0],
                        co_d[15:0],co_c[15:0],co_b[15:0],co_a[15:0]};
    10 : coefi_parms = {co_k[15:0],co_j[15:0],co_i[15:0],co_h[15:0],co_g[15:0],co_f[15:0],
                        co_e[15:0],co_d[15:0],co_c[15:0],co_b[15:0],co_a[15:0]};
    12 : coefi_parms = {co_m[15:0],co_l[15:0],co_k[15:0],co_j[15:0],co_i[15:0],co_h[15:0],co_g[15:0],
                       co_f[15:0],co_e[15:0],co_d[15:0],co_c[15:0],co_b[15:0],co_a[15:0]};
    14 : coefi_parms = {co_o[15:0],co_n[15:0],co_m[15:0],co_l[15:0],co_k[15:0],co_j[15:0],co_i[15:0],
                       co_h[15:0],co_g[15:0],co_f[15:0],co_e[15:0],co_d[15:0],co_c[15:0],
		       co_b[15:0],co_a[15:0]}; 
    16 : coefi_parms = {co_p[15:0],co_p[15:0],co_o[15:0],co_n[15:0],co_m[15:0],co_l[15:0],co_k[15:0],
                       co_j[15:0],co_i[15:0],co_h[15:0],co_g[15:0],co_f[15:0],co_e[15:0],
		       co_d[15:0],co_c[15:0],co_b[15:0],co_a[15:0]};  
  endcase
  
  case(n)
    4 : begin
      case (linenum) 
          0 : signbit = 2'b00;
          1 : signbit = 2'b00;
          2 : signbit = 2'b01;
          3 : signbit = 2'b01;
        endcase
      end
    6 : begin
      case (linenum) 
          0 : signbit = 3'b000;
          1 : signbit = 3'b000;
          2 : signbit = 3'b001;
          3 : signbit = 3'b011;
          4 : signbit = 3'b010;
          5 : signbit = 3'b010;
        endcase
      end
    8 : begin
      case (linenum) 
          0 : signbit = 4'b0000;
          1 : signbit = 4'b0000;
          2 : signbit = 4'b0011;
          3 : signbit = 4'b0111;
          4 : signbit = 4'b0110;
          5 : signbit = 4'b0100;
          6 : signbit = 4'b0101;
          7 : signbit = 4'b0101;
        endcase
      end
    10 : begin
      case (linenum) 
          0 : signbit = 5'b00000;
          1 : signbit = 5'b00000;
          2 : signbit = 5'b00011;
          3 : signbit = 5'b00111;
          4 : signbit = 5'b01110;
          5 : signbit = 5'b01100;
          6 : signbit = 5'b01101;
          7 : signbit = 5'b01001;
          8 : signbit = 5'b01010;
          9 : signbit = 5'b01010;
        endcase
      end
    12 : begin
      case (linenum) 
           0 : signbit = 6'b000000;
           1 : signbit = 6'b000000;
           2 : signbit = 6'b000111;
           3 : signbit = 6'b001111;
           4 : signbit = 6'b001110;
           5 : signbit = 6'b011100;
           6 : signbit = 6'b011001;
           7 : signbit = 6'b011011;
           8 : signbit = 6'b010010;
           9 : signbit = 6'b010110;
          10 : signbit = 6'b010101;
          11 : signbit = 6'b010101;
        endcase
      end
    14 : begin
      case (linenum) 
           0 : signbit = 7'b0000000;
           1 : signbit = 7'b0000000;
           2 : signbit = 7'b0000111;
           3 : signbit = 7'b0011111;
           4 : signbit = 7'b0011100;
           5 : signbit = 7'b0111000;
           6 : signbit = 7'b0111001;
           7 : signbit = 7'b0110011;
           8 : signbit = 7'b0110110;
           9 : signbit = 7'b0100100;
          10 : signbit = 7'b0100101;
          11 : signbit = 7'b0101001;
          12 : signbit = 7'b0101010;
          13 : signbit = 7'b0101010;
        endcase
      end
    16 : begin
      case (linenum) 
           0 : signbit = 8'b00000000;
           1 : signbit = 8'b00000000;
           2 : signbit = 8'b00001111;
           3 : signbit = 8'b00011111;
           4 : signbit = 8'b00111100;
           5 : signbit = 8'b00111000;
           6 : signbit = 8'b01110001;
           7 : signbit = 8'b01100011;
           8 : signbit = 8'b01100110;
           9 : signbit = 8'b01101100;
          10 : signbit = 8'b01001101;
          11 : signbit = 8'b01001001;
          12 : signbit = 8'b01011010;
          13 : signbit = 8'b01010010;
          14 : signbit = 8'b01010101;
          15 : signbit = 8'b01010101;
        endcase
      end
  endcase

  case (n)
      4 : begin
      case (linenum) 
          0 : coefsel = 8'h00;
          1 : coefsel = 8'h13;
          2 : coefsel = 8'h00;
          3 : coefsel = 8'h31;
        endcase
      end
    6 : begin
      case (linenum) 
          0 : coefsel = 12'h000;
          1 : coefsel = 12'h105;
          2 : coefsel = 12'h262;
          3 : coefsel = 12'h333;
          4 : coefsel = 12'h404;
          5 : coefsel = 12'h501;
        endcase
      end
    8 : begin
      case (linenum) 
          0 : coefsel = 16'h0000;
          1 : coefsel = 16'h1357;
          2 : coefsel = 16'h2662;
          3 : coefsel = 16'h3715;
          4 : coefsel = 16'h0000;
          5 : coefsel = 16'h5173;
          6 : coefsel = 16'h6226;
          7 : coefsel = 16'h7531;
        endcase
      end
    10 : begin
      case (linenum) 
          0 : coefsel = 20'h00000;
          1 : coefsel = 20'h13079;
          2 : coefsel = 20'h26a62;
          3 : coefsel = 20'h39017;
          4 : coefsel = 20'h48084;
          5 : coefsel = 20'h00000;
          6 : coefsel = 20'h62a26;
          7 : coefsel = 20'h71093;
          8 : coefsel = 20'h84048;
          9 : coefsel = 20'h97031;
        endcase
      end
    12 : begin
      case (linenum) 
           0 : coefsel = 24'h000000;
           1 : coefsel = 24'h13579b;
           2 : coefsel = 24'h26aa62;
           3 : coefsel = 24'h399339;
           4 : coefsel = 24'h4c44c4;
           5 : coefsel = 24'h591b37;
           6 : coefsel = 24'h666666;
           7 : coefsel = 24'h73b195;
           8 : coefsel = 24'h808808;
           9 : coefsel = 24'h933993;
          10 : coefsel = 24'ha0220a;
          11 : coefsel = 24'hb97531;
        endcase
      end
    14 : begin
      case (linenum) 
           0 : coefsel = 28'h0000000;
           1 : coefsel = 28'h13509bd;
           2 : coefsel = 28'h26aea62;
           3 : coefsel = 28'h39d015b;
           4 : coefsel = 28'h4c808c4;
           5 : coefsel = 28'h5d30b19;
           6 : coefsel = 28'h6a2e2a6;
           7 : coefsel = 28'h7777777;
           8 : coefsel = 28'h84c0c48;
           9 : coefsel = 28'h91b03d5;
          10 : coefsel = 28'ha26e62a;
          11 : coefsel = 28'hb510d93;
          12 : coefsel = 28'hc84048c;
          13 : coefsel = 28'hdb90531;
        endcase
      end
    16 : begin
      case (linenum) 
           0 : coefsel = 32'h00000000;
           1 : coefsel = 32'h13579bdf;
           2 : coefsel = 32'h26aeea62;
           3 : coefsel = 32'h39fb517d;
           4 : coefsel = 32'h4cc44cc4;
           5 : coefsel = 32'h5f73d91b;
           6 : coefsel = 32'h6e2aa2e6;
           7 : coefsel = 32'h7b3f1d59;
           8 : coefsel = 32'h00000000;
           9 : coefsel = 32'h95d1f3b7;
          10 : coefsel = 32'ha2e66e2a;
          11 : coefsel = 32'hb19d37f5;
          12 : coefsel = 32'hc44cc44c;
          13 : coefsel = 32'hd715bf93;
          14 : coefsel = 32'hea6226ae;
          15 : coefsel = 32'hfdb97531;
        endcase
      end
  endcase

  tempcoef = 0;
  for ( cnt = 0; cnt < n/2; cnt = cnt + 1) begin
    indx = coefsel[3:0];
    coefsel = coefsel >> 4;
    for(ploop = 0; ploop < 16; ploop = ploop +1) begin
      cindx = 16 * indx + ploop;
      coefin[ploop] = coefi_parms[cindx];
    end
    if(signbit[cnt] == 1'b1)
      coefin = ~coefin +1;
    //$display("coefin %d",coefin);

    tempcoef = {coefin,tempcoef[n/2*16-1:16]};
  end // cnt looped n/2 times
  gen_fcoef = tempcoef;
  //$display("%d from scale: %x",linenum,tempcoef);
end
endfunction 

function [(n/2*16)-1:0] get_fcoef;
input [`nwidth-1:0] linenum;
begin
  case(linenum)
    0:  get_fcoef = coef_wire0;
    1:  get_fcoef = coef_wire1;
    2:  get_fcoef = coef_wire2;
    3:  get_fcoef = coef_wire3;
    4:  get_fcoef = coef_wire4;
    5:  get_fcoef = coef_wire5;
    6:  get_fcoef = coef_wire6;
    7:  get_fcoef = coef_wire7;
    8:  get_fcoef = coef_wire8;
    9:  get_fcoef = coef_wire9;
   10:  get_fcoef = coef_wire10;
   11:  get_fcoef = coef_wire11;
   12:  get_fcoef = coef_wire12;
   13:  get_fcoef = coef_wire13;
   14:  get_fcoef = coef_wire14;
   15:  get_fcoef = coef_wire15;
  endcase
end
endfunction
function [(n/2*16)-1:0] get_icoef;
input [`nwidth-1:0] linenum;
begin
  case(linenum)
    0:  get_icoef = coefp_wire0;
    1:  get_icoef = coefp_wire1;
    2:  get_icoef = coefp_wire2;
    3:  get_icoef = coefp_wire3;
    4:  get_icoef = coefp_wire4;
    5:  get_icoef = coefp_wire5;
    6:  get_icoef = coefp_wire6;
    7:  get_icoef = coefp_wire7;
    8:  get_icoef = coefp_wire8;
    9:  get_icoef = coefp_wire9;
   10:  get_icoef = coefp_wire10;
   11:  get_icoef = coefp_wire11;
   12:  get_icoef = coefp_wire12;
   13:  get_icoef = coefp_wire13;
   14:  get_icoef = coefp_wire14;
   15:  get_icoef = coefp_wire15;
  endcase
  //$display("get_icoef %x",get_icoef);
end
endfunction
function [(n/2*16)-1:0] gen_icoef;
input[`nwidth-1:0] linenum;
integer i,j,k,l;
reg [(n/2*16)-1:0] temp, temp_prime;
begin
temp_prime = 0;
temp = 0;
  if(linenum[0] == 1'b0) begin
  for(i=0;i<n;i=i+2)begin
    temp = gen_fcoef(i);
    //$display("%d line %d coef : %x",i,linenum,temp);
    for(j=0;j<16;j=j+1) begin
      //temp_prime[15:0] = temp[15:0];
      k = (n/2 - (linenum/2)-1) * 16;
      l = (n/2 - (i/2)-1) * 16;
      temp_prime[l+j] = temp[k+j];
      //$display("i %d j%d k %d l %d",i,j,k,l);
      //temp = temp >> 16;
    end
  end //for i
    //$display("%d temp_prime %x",linenum,temp_prime);
  end else begin
    temp_prime = gen_fcoef(linenum);
  end
  gen_icoef = temp_prime;
end
endfunction

`undef fwrdsz
`undef rddatsz
`undef frstadr
`undef idatsz
`undef prodsum0
`undef prodsum1
`undef nwidth
`undef addwidth
`undef fnldat
 `undef initregsz
 `undef xfregsz 
 `undef scndregsz 
 `undef scndxfregsz 
 `undef pidatsz
 `undef ppsdwire0
 `undef ppsdwire1

endmodule
