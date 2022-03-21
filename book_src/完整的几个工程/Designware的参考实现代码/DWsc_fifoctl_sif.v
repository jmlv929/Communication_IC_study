////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
//        7/17/06
//
// VERSION:   Verilog Synthesis Model
//
// DesignWare_version: e4895831
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
//
// ABSTRACT: Source domain (push operation) interface FIFO controller
//
//           Used for FIFOs with synchronous pipelined RAMs and 
//           external caching.  Status flags are dynamically
//           configured.
//
//
//      Parameters     Valid Values   Description
//      ==========     ============   ===========
//      ram_depth     4 to 16777216   default: 8
//                                    Depth of the RAM in the FIFO (does not include cache depth)
//
//      mem_mode         0 to 7       default: 5
//                                    Defines where and how many re-timing stages:
//                                      0 => no RAM pre or post retiming
//                                      1 => RAM data out (post) re-timing
//                                      2 => RAM read address (pre) re-timing
//                                      3 => RAM read address (pre) and data out (post) re-timing
//                                      4 => RAM write interface (pre) re-timing
//                                      5 => RAM write interface (pre) and data out (post) re-timing
//                                      6 => RAM write interface (pre) and read address (pre) re-timing
//                                      7 => RAM write interface (pre), read address re-timing (pre), and data out (post) re-timing
//
//      err_mode         0 or 1       default: 0
//                                    Error Reporting Behavior
//                                      0 => sticky error flag
//                                      1 => dynamic error flag
//
//      Inputs 	         Size	    Description
//      ======	         ====	    ===========
//      clk_s	         1 bit	    Source Domain Clock
//      rst_s_n	         1 bit	    Source Domain Asynchronous Reset (active low)
//      init_s_n         1 bit	    Source Domain Synchronous Reset (active low)
//      clr_sync_s       1 bit	    Source Domain Synchronized Clear (active high pulse)
//      ae_level_s       M bits     Source Domain almost empty threshold setting
//      af_level_s       M bits     Source Domain almost full threshold setting
//      clr_in_prog_s    1 bit      Source Domain Clear in Progress (unregistered)
//      push_s_n         1 bit      Source Domain push request (active low)
//      wr_ptr_s         M bits     Source Domain next write pointer (relative to RAM) for counting (unregistered)
//      rd_ptr_s         M bits     Source Domain synchronized read pointer (relative to RAM) for counting
//      cache_census_s   N bits     Source Domain synchronized external cache count (includes RAM read in progress)  (binary-value vector)
//
//      Outputs	         Size	    Description
//      =======	         ====	    ===========
//      wr_en_s_n        1 bit      Source Domain write enable to RAM (active low)
//      wr_en_s          1 bit      Source Domain enable to gray code synchronizer
//      fifo_word_cnt_s  Q bits     Source Domain FIFO word count (includes cache)
//      word_cnt_s       M bits     Source Domain RAM only word count
//      fifo_empty_s     1 bit	    Source Domain FIFO Empty Flag
//      empty_s          1 bit	    Source Domain RAM Empty Flag
//      almost_empty_s   1 bit	    Source Domain RAM Almost Empty Flag
//      half_full_s      1 bit	    Source Domain RAM Half Full Flag
//      almost_full_s    1 bit	    Source Domain RAM Almost Full Flag
//      full_s	         1 bit	    Source Domain RAM Full Flag
//      error_s	         1 bit	    Source Domain Error Flag
//
//           Note: M is based on ram_depth:
//                   M = ceil(log2(ram_depth+1))
//
//           Note: N is based on the mem_mode parameter:
//                   N = 1 when mem_mode = 0 or 4
//                   N = 2 when mem_mode = 1, 2, 3, 5, 6, or 7
//		
//           Note: Q is based on the mem_mode parameter:
//                   Q = ceil(log2((ram_depth+1)+1)) when mem_mode = 0 or 4
//                   Q = ceil(log2((ram_depth+1)+2)) when mem_mode = 1, 2, 5, or 6
//                   Q = ceil(log2((ram_depth+1)+3)) when mem_mode = 3 or 7
//
//
// MODIFIED:
//
//	   RJK - 3/21/12
//	   Corrected problems with use when depth is greater than 65533
//	   (STAR 9000530636)
//  
//         DLL - 10/07/11
//         Added labels to all regions of generate statements.
//
//         DLL - 6/2/11
//         (1) Consolidated init_s_n and clr_in_prog_s into on signal that
//             is used for synchronous reset.  Also, reduced one 'else' block
//             in the sequential process.
//         (2) Removed all `define macros with #define macros and localparams.
//         (3) Subsequently, removed some 'leda off' and 'leda on' pragmas since `define
//             macros covnverted to localparams.
//         (4) Convert to generate statements replacing constant conditional expressions.
//
//         DLL - 3/16/10
//         Apply 'clr_in_prog_s' for synchronous resets to registers
//         instead of 'clr_sync_s'.
//         This fix addresses STAR#9000381235.
//         This fix addresses STAR#9000381234.
//
//         DLL - 11/4/09
//         Take in cache count that includes RAM read in progress
//         count.  Change the naming and meaing of 'cache_inuse_s' to
//         a binary-valued vector.  Name change to "cache_census_s".
//         This fix addresses STAR#9000353986.
//
//		
////////////////////////////////////////////////////////////////////////////////


module DWsc_fifoctl_sif(
        clk_s,
        rst_s_n,
        init_s_n,
        clr_sync_s,
        ae_level_s,
        af_level_s,
        clr_in_prog_s,
        push_s_n,
        wr_ptr_s,
        rd_ptr_s,
        cache_census_s,
  
	wr_en_s_n,
	wr_en_s,
        fifo_word_cnt_s,
        word_cnt_s,
        fifo_empty_s,
        empty_s,
        almost_empty_s,
        half_full_s,
        almost_full_s,
        full_s,
        error_s
        // Embedded dc_shell script
        // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
        // _model_constraint_1
	);

parameter ram_depth     =  8;	// RANGE 4 to 16777216
parameter mem_mode      =  5;	// RANGE 0 to 7
parameter err_mode	=  0;	// RANGE 0 to 1
   

localparam eff_depth            = (((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2));
localparam fifo_cnt_width       = (((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>65536)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16777216)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>268435456)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>536870912)?30:29):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>67108864)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>134217728)?28:27):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>33554432)?26:25))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>1048576)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4194304)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8388608)?24:23):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2097152)?22:21)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>262144)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>524288)?20:19):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>131072)?18:17)))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>256)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4096)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16384)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>32768)?16:15):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8192)?14:13)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>1024)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2048)?12:11):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>512)?10:9))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>64)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>128)?8:7):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>32)?6:5)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8)?4:3):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2)?2:1)))));
localparam cnt_width            = ((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))));
localparam cache_cnt_idx_width  = (((((mem_mode==0)||(mem_mode==4)) ? 1 : (((mem_mode==3)||(mem_mode==7)) ? 3 : 2)) == 1) ? 1 : 2);
localparam leftover_cnt         = ((1 << ((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))) - ((ram_depth == (1 << (((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))-1)))? (ram_depth*2) : ((ram_depth+2) - (ram_depth & 1))));
localparam hf_level           = (ram_depth  +  1 )/ 2;

input                            clk_s;          // Source Domain Clock 
input                            rst_s_n;        // Source Domain Asynchronous Reset (active low) 
input                            init_s_n;       // Source Domain Synchronous Reset (active low) 
input                            clr_sync_s;     // Source Domain Synchronized Clear (active high pulse) 
input  [cnt_width-1:0]           ae_level_s;     // Source Domain RAM almost empty threshold setting 
input  [cnt_width-1:0]           af_level_s;     // Source Domain RAM almost full threshold setting 
input                            clr_in_prog_s;  // Source Domain Clear in Progress (unregistered) 
input                            push_s_n;       // Source Domain push request (active low) 
input  [cnt_width-1:0]           wr_ptr_s;       // Source Domain next write pointer (relative to RAM) - unregistered 
input  [cnt_width-1:0]           rd_ptr_s;       // Source Domain synchronized read pointer (relative to RAM) 
input  [cache_cnt_idx_width-1:0] cache_census_s;  // Source Domain synchronized external cache count (binary value vector) 

output                           wr_en_s_n;       // Source Domain write enable to RAM (active low) 
output                           wr_en_s;         // Source Domain enable to gray code synchronizer 
output [fifo_cnt_width-1:0]      fifo_word_cnt_s; // Source Domain FIFO word count (includes cache) 
output [cnt_width-1:0]           word_cnt_s;      // Source Domain RAM only word count 
output                           fifo_empty_s;    // Source Domain FIFO Empty Flag 
output                           empty_s;         // Source Domain RAM Empty Flag 
output                           almost_empty_s;  // Source Domain RAM Almost Empty Flag 
output                           half_full_s;     // Source Domain RAM Half Full Flag 
output                           almost_full_s;   // Source Domain RAM Almost Full Flag 
output                           full_s;	  // Source Domain RAM Full Flag 
output                           error_s;         // Source Domain Error Flag 

wire [cnt_width-1 : 0]           a_empty_vector;
wire [cnt_width-1 : 0]           a_full_vector;
wire [cnt_width-1 : 0]           hlf_full_vector;
wire [cnt_width-1 : 0]           full_count_bus;
wire [cnt_width-1 : 0]           bus_low_ram;
wire [fifo_cnt_width-1 : 0]      bus_low_fifo;

wire                             push_s;

wire [cnt_width-1 : 0]           residual_value_bus;
wire                             init_regs_n;

wire                             next_almost_empty_s;
wire                             next_half_full_s;
wire                             next_almost_full_s;
wire                             next_full_s;
wire                             error_seen;
wire                             next_error_s_int;

wire                             next_fifo_empty_s;
wire                             next_empty_s;

wire                             advance;

reg  [fifo_cnt_width-1 : 0]      next_fifo_word_cnt_s_int;
reg  [cnt_width-1 : 0]           next_word_cnt_s_int;

wire [cnt_width : 0]             temp1;
wire [cnt_width-1 : 0]           word_cnt_s_p1;
wire [cnt_width-1 : 0]           word_cnt_s_p1_rgtw;       // rptr greater than wptr result
wire [fifo_cnt_width : 0]        fifo_word_cnt_s_p1;
wire [fifo_cnt_width : 0]        fifo_word_cnt_s_p1_rgtw;  // rptr greater than wptr result


reg  [fifo_cnt_width-1 : 0]      fifo_word_cnt_s_int;
reg  [cnt_width-1 : 0]           word_cnt_s_int;
 
reg                              fifo_empty_s_int;
reg                              empty_s_int;
reg                              almost_empty_s_int;
reg                              half_full_s_int;
reg                              almost_full_s_int;
reg                              full_s_int;
reg                              error_s_int;



  assign push_s  = ~push_s_n;

  assign a_empty_vector        = ae_level_s;
  assign hlf_full_vector       = hf_level;
// leda W484 off
  assign a_full_vector         = (ram_depth  - af_level_s );
// leda W484 on
  assign full_count_bus        = ram_depth;
  assign bus_low_ram           = {cnt_width{1'b0}};
  assign residual_value_bus    = leftover_cnt[cnt_width-1:0];
  assign bus_low_fifo          = {fifo_cnt_width{1'b0}};
 
  assign next_almost_empty_s   = (next_word_cnt_s_int <= a_empty_vector) ? 1'b1 : 1'b0;
  assign next_half_full_s      = (next_word_cnt_s_int >= hlf_full_vector) ? 1'b1 : 1'b0; 
  assign next_almost_full_s    = (next_word_cnt_s_int >= a_full_vector) ? 1'b1 : 1'b0; 
  assign next_empty_s          = (next_word_cnt_s_int == bus_low_ram) ? 1'b1 : 1'b0; 
  assign next_full_s           = (next_word_cnt_s_int == full_count_bus) ? 1'b1 : 1'b0; 
  assign next_fifo_empty_s     = (next_fifo_word_cnt_s_int == bus_low_fifo) ? 1'b1 : 1'b0; 

  assign error_seen            = push_s && full_s_int;

  generate
    if (err_mode == 0) begin : GEN_EM_EQ_0
      assign next_error_s_int  = error_seen || error_s_int;
    end else begin : GEN_EM_NE_0
      assign next_error_s_int  = error_seen;
    end
  endgenerate

  // Merge synchronous reset signals into one
  assign init_regs_n = init_s_n && ~clr_in_prog_s;
 
  always @ (posedge clk_s or negedge rst_s_n) begin
     if (!rst_s_n) begin
       fifo_word_cnt_s_int <= {fifo_cnt_width{1'b0}};
       word_cnt_s_int      <= {cnt_width{1'b0}};
       fifo_empty_s_int    <= 1'b0;
       empty_s_int         <= 1'b0;
       almost_empty_s_int  <= 1'b0;
       half_full_s_int     <= 1'b0;
       almost_full_s_int   <= 1'b0;
       full_s_int          <= 1'b0;
       error_s_int         <= 1'b0;
     end else begin
       fifo_word_cnt_s_int <= next_fifo_word_cnt_s_int & {fifo_cnt_width{init_regs_n}};
       word_cnt_s_int      <= next_word_cnt_s_int & {fifo_cnt_width{init_regs_n}};
       fifo_empty_s_int    <= ~next_fifo_empty_s & init_regs_n;
       empty_s_int         <= ~next_empty_s & init_regs_n;
       almost_empty_s_int  <= ~next_almost_empty_s & init_regs_n;
       half_full_s_int     <= next_half_full_s & init_regs_n;
       almost_full_s_int   <= next_almost_full_s & init_regs_n;
       full_s_int          <= next_full_s & init_regs_n;
       error_s_int         <= next_error_s_int & init_regs_n;
     end
    end

  assign wr_en_s_n          = ~(push_s && ~full_s_int);
  assign wr_en_s            = push_s && ~full_s_int;

  assign fifo_word_cnt_s    = fifo_word_cnt_s_int;
  assign word_cnt_s         = word_cnt_s_int;

  assign fifo_empty_s       = ~fifo_empty_s_int;
  assign empty_s            = ~empty_s_int;
  assign almost_empty_s     = ~almost_empty_s_int;
  assign half_full_s        = half_full_s_int;
  assign almost_full_s      = almost_full_s_int;
  assign full_s             = full_s_int;
  assign error_s            = error_s_int;


  assign advance            = push_s && ~full_s_int;

  assign temp1               = wr_ptr_s - rd_ptr_s;
  assign word_cnt_s_p1       = temp1[cnt_width-1 : 0];
// leda W484 off
  assign word_cnt_s_p1_rgtw  = word_cnt_s_p1 - residual_value_bus;
// leda W484 on

  
  assign fifo_word_cnt_s_p1       = word_cnt_s_p1 + {{fifo_cnt_width-cache_cnt_idx_width{1'b0}}, cache_census_s};
  assign fifo_word_cnt_s_p1_rgtw  = word_cnt_s_p1_rgtw + {{fifo_cnt_width-cache_cnt_idx_width{1'b0}}, cache_census_s};

  always @( word_cnt_s_p1 or word_cnt_s_p1_rgtw or fifo_word_cnt_s_p1 or 
	    fifo_word_cnt_s_p1_rgtw or rd_ptr_s or wr_ptr_s) begin : next_cnt_s_PROC
      if (rd_ptr_s > wr_ptr_s) begin
        next_word_cnt_s_int       = word_cnt_s_p1_rgtw;
        next_fifo_word_cnt_s_int  = fifo_word_cnt_s_p1_rgtw[fifo_cnt_width-1:0];
      end else begin
        next_word_cnt_s_int       = word_cnt_s_p1;
        next_fifo_word_cnt_s_int  = fifo_word_cnt_s_p1[fifo_cnt_width-1:0];
      end
  end  // block: next_cnt_s_PROC


endmodule
