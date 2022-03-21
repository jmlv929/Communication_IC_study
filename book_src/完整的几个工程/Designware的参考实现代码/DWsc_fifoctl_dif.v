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
//        8/01/06
//
// VERSION:   Verilog Synthesis Model
//
// DesignWare_version: 61194e74
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
//
// ABSTRACT: Destination domain (pop operation) interface FIFO controller
//
//           Used for FIFOs with synchronous pipelined RAMs and 
//           external caching.  Status flags are dynamically
//           configured.
//
//
//      Parameters     Valid Values   Description
//      ==========     ============   ===========
//      width           1 to 1024     default: 8
//                                    Width of data to/from RAM
//
//      ram_depth     4 to 16777216   default: 8
//                                    Depth of the RAM in the FIFO (does not include cache depth)
//
//      mem_mode         0 to 7       default: 3
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
//      ram_re_ext       0 or 1       default: 0
//                                    Determines the charateristic of the ram_re_d_n signal to RAM
//                                      0 => Single-cycle pulse of ram_re_d_n at the read event to RAM
//                                      1 => Extend assertion of ram_re_d_n while read event active in RAM
//
//      err_mode         0 or 1       default: 0
//                                    Error Reporting Behavior
//                                      0 => sticky error flag
//                                      1 => dynamic error flag
//
//      arch_type        0 or 1       default: 0
//                                    Pre-fetch cache architecture type
//                                      0 => Pipeline style
//                                      1 => Register File style
//
//      Inputs 	            Size	  Description
//      ======	            ====	  ===========
//      clk_d	            1 bit	  Destination Domain Clock
//      rst_d_n	            1 bit	  Destination Domain Asynchronous Reset (active low)
//      init_d_n            1 bit	  Destination Domain Synchronous Reset (active low)
//      clr_sync_d          1 bit	  Destination Domain Synchronized Clear (active high pulse)
//      ae_level_d          Q bits        Destination Domain almost empty threshold setting
//      af_level_d          Q bits        Destination Domain almost empty threshold setting
//      clr_in_prog_d       1 bit         Destination Domain Clear in Progress (unregistered)
//      pop_d_n             1 bit         Destination Domain pop request (active low)
//      rd_data_d           W bits        Destination Domain data from RAM
//      wr_ptr_d            M bits        Destination Domain synchronized write pointer (relative to RAM) for counting
//      rd_ptr_d            M bits        Destination Domain next read pointer (relative to RAM) for counting
//
//      Outputs	            Size	  Description
//      =======	            ====	  ===========
//      ram_re_d_n          1 bit         Destination Domain Read Enable to RAM (active-low)
//      rd_en_d             1 bit         Destination Domain enable to gray code synchronizer
//      data_d              W bits        Destination Domain data out
//      word_cnt_d          Q bits        Destination Domain FIFO word count (includes cache)
//      ram_word_cnt_d      M bits        Destination Domain RAM only word count
//      cache_census_gray_d N bits        Destination Domain external cache count in gray-code (incl. RAM read in progress)
//      empty_d	            1 bit	  Destination Domain Empty Flag
//      almost_empty_d      1 bit	  Destination Domain Almost Empty Flag
//      half_full_d         1 bit	  Destination Domain Half Empty Flag
//      almost_full_d       1 bit	  Destination Domain Almost Empty Flag
//      full_d	            1 bit	  Destination Domain Empty Flag
//      error_d	            1 bit	  Destination Domain Error Flag
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
//           Note: W is the width parameter
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
//         DLL - 6/6/11
//         (1) Removed all `define macros with #define macros and localparams.
//         (2) Subsequently, removed some 'leda off' and 'leda on' pragmas since `define
//             macros covnverted to localparams.
//         (3) Convert to generate statements replacing constant conditional expressions.
//
//              DLL   11/15/10 Fixed default values for some parameters to match across all
//                             source code.
//                             This fix addresses STAR#9000429754.
//
//              DLL   8/20/10  Fixed corner-case for 'almost_full_d' when cache depth is '1'
//                             and 'af_level_d == eff_depth'.
//                             This fix addresses STAR#9000413916.
//
//              DLL   3/17/10  Fixed the de-assertion conditions for 'almost_empty_d' and
//                             assertion condtions for 'half_full_d', 'almost_full_d', and
//                             'full_d'.  This allows blind popping in with data underruns.
//                             This fix addresses STAR#9000380664.
//                             This fix addresses STAR#9000381207.
//
//              DLL   3/16/10  Apply 'clr_in_prog_d' for synchronous resets to registers
//                             instead of 'clr_sync_d'.
//                             This fix addresses STAR#9000381235.
//                             This fix addresses STAR#9000381234.
//
//              DLL   11-4-09  Create cache count that includes RAM read in progress
//                             state.  Change the meaning/naming of 'cache_inuse_d' to
//                             a gray-coded vector.  New name is "cache_census_gray_d"
//                             This fix addresses STAR#9000353986.
//
//              DLL   1-10-07  Converted looping variables from global to local
//
//		
////////////////////////////////////////////////////////////////////////////////


module DWsc_fifoctl_dif(
        clk_d,
        rst_d_n,
        init_d_n,
        clr_sync_d,
        ae_level_d,
        af_level_d,
        clr_in_prog_d,
        pop_d_n,
        rd_data_d,
        wr_ptr_d,
        rd_ptr_d,
  
	ram_re_d_n,
	rd_en_d,
        data_d,
        word_cnt_d,
        ram_word_cnt_d,
        cache_census_gray_d,
        empty_d,
        almost_empty_d,
        half_full_d,
        almost_full_d,
        full_d,
        error_d
        // Embedded dc_shell script
        // set_attribute _current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
        // _model_constraint_1
	);

parameter width         =  8;   // RANGE 1 to 1024
parameter ram_depth     =  8;	// RANGE 4 to 16777216
parameter mem_mode      =  3;	// RANGE 0 to 7
parameter ram_re_ext    =  0;   // RANGE 0 to 1
parameter err_mode	=  0;	// RANGE 0 to 1
parameter arch_type	=  0;	// RANGE 0 to 1
   

localparam eff_depth             = (((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2));
localparam cnt_width             = (((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>65536)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16777216)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>268435456)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>536870912)?30:29):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>67108864)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>134217728)?28:27):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>33554432)?26:25))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>1048576)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4194304)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8388608)?24:23):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2097152)?22:21)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>262144)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>524288)?20:19):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>131072)?18:17)))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>256)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4096)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16384)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>32768)?16:15):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8192)?14:13)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>1024)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2048)?12:11):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>512)?10:9))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>64)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>128)?8:7):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>32)?6:5)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8)?4:3):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2)?2:1)))));
localparam ram_cnt_width         = ((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))));
localparam cache_inuse_width     = (((mem_mode==0)||(mem_mode==4)) ? 1 : (((mem_mode==3)||(mem_mode==7)) ? 3 : 2));
localparam cache_inuse_idx_width = (((((mem_mode==0)||(mem_mode==4)) ? 1 : (((mem_mode==3)||(mem_mode==7)) ? 3 : 2)) == 1) ? 1 : 2);
localparam leftover_cnt          = ((1 << ((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))) - ((ram_depth == (1 << (((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))-1)))? (ram_depth*2) : ((ram_depth+2) - (ram_depth & 1))));
localparam offset                = (((1 << ((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))) - ((ram_depth == (1 << (((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))-1)))? (ram_depth*2) : ((ram_depth+2) - (ram_depth & 1)))) / 2);
localparam one_deep_cache        = ((mem_mode==0) || (mem_mode==4));
localparam two_deep_cache        = ((mem_mode==1) || (mem_mode==2) || (mem_mode==5) || (mem_mode==6));
localparam three_deep_cache      = ((mem_mode==3) || (mem_mode==7));
  
localparam hf_level              = (((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2)) + 1)/ 2);



input                            clk_d;          // Destination Domain Clock 
input                            rst_d_n;        // Destination Domain Asynchronous Reset (active low) 
input                            init_d_n;       // Destination Domain Synchronous Reset (active low) 
input                            clr_sync_d;     // Destination Domain Synchronized Clear (active high pulse) 
input  [cnt_width-1:0]           ae_level_d;     // Destination Domain almost empty threshold setting 
input  [cnt_width-1:0]           af_level_d;     // Destination Domain almost empty threshold setting 
input                            clr_in_prog_d;  // Destination Domain Clear in Progress (unregistered) 
input                            pop_d_n;        // Destination Domain pop request (active low) 
input  [width-1:0]               rd_data_d;      // Destination Domain data from RAM 
input  [ram_cnt_width-1:0]       wr_ptr_d;       // Destination Domain next write pointer (relative to RAM) - unregistered 
input  [ram_cnt_width-1:0]       rd_ptr_d;       // Destination Domain synchronized read pointer (relative to RAM) 

output                           ram_re_d_n;     // Destination Domain Read Enable to RAM (active-low) 
output                           rd_en_d;        // Destination Domain enable to gray code synchronizer 
output [width-1:0]               data_d;         // Destination Domain data out 
output [cnt_width-1:0]           word_cnt_d;     // Destination Domain FIFO word count (includes cache) 
output [ram_cnt_width-1:0]       ram_word_cnt_d; // Destination Domain RAM only word count 
output [cache_inuse_idx_width-1:0] cache_census_gray_d;// Destination Domain external cache count in gray-code
output                           empty_d;        // Destination Domain Full Flag 
output                           almost_empty_d; // Destination Domain Almost Empty Flag 
output                           half_full_d;    // Destination Domain Half Empty Flag 
output                           almost_full_d;  // Destination Domain Almost Empty Flag 
output                           full_d;	 // Destination Domain Empty Flag 
output                           error_d;        // Destination Domain Error Flag

wire [cnt_width-1:0]             a_empty_vector;
wire [cnt_width:0]               a_full_vector;
wire [31:0]                      a_full_vector_temp;
wire [cnt_width-1:0]             hlf_full_vector;
wire [cnt_width-1:0]             full_count_bus;
wire [cnt_width-1:0]             bus_low;

wire                             tie_low;
wire                             tie_high;
wire [ram_cnt_width-1:0]         residual_value_bus;
wire                             init_regs_n;

wire                             next_empty_d;
reg                              next_almost_empty_d;
reg                              next_half_full_d;
reg                              next_almost_full_d;
reg                              next_full_d;
wire                             error_seen;
wire                             next_error_d_int;

wire [cnt_width-1:0]             count;

wire [cnt_width-1:0]             next_word_cnt_d_int;
wire [ram_cnt_width-1:0]         next_ram_word_cnt_d_int;
reg  [ram_cnt_width-1:0]         next_ram_word_cnt_d_temp;
reg  [cnt_width-1:0]             next_word_cnt_d_temp;

wire [ram_cnt_width:0]           temp1;
wire [ram_cnt_width-1:0]         ram_word_cnt_d_p1;
wire [ram_cnt_width:0]           ram_word_cnt_d_p1_rgtw;
wire [cnt_width:0]               word_cnt_d_p1;
wire [cnt_width:0]               word_cnt_d_p1_rgtw;

reg  [cnt_width-1:0]             word_cnt_d_int;
reg  [ram_cnt_width-1:0]         ram_word_cnt_d_int;

wire [width-1:0]                 rd_data_d_int;
wire [width-1:0]                 data_d;

reg                              ram_empty;
wire                             next_ram_empty;
wire                             ram_empty_int;
reg                              ram_empty_d1;
wire                             ram_empty_d1_int;
wire                             ram_empty_pipe;
 
reg                              full_d_int;
reg                              empty_d_int;
reg                              almost_empty_d_int;
reg                              half_full_d_int;
reg                              almost_full_d_int;
reg                              error_d_int;

wire                             pop_d;
wire                             adv_cnt;
wire                             pop_ram;
wire                             ld_rdtr;

wire [1:0]                       next_rdtr_reg;
reg  [1:0]                       rdtr_reg;
wire                             ld_cache;


wire [cache_inuse_idx_width-1:0] cache_census_gray_d;
wire [2:0]                       next_inuse;
wire                             inuse_1dp_select0;
wire [2:0]                       next_inuse_1dp;
wire                             inuse_2dp_select0;
wire                             inuse_2dp_select1;
wire [2:0]                       next_inuse_2dp;
wire                             inuse_3dp_select0;
wire                             inuse_3dp_select1;
wire                             inuse_3dp_select2;
wire [2:0]                       next_inuse_3dp;
reg  [2:0]                       inuse;


// Pipeline Cache declarations
wire                             cache_data_1dp_ram_sel0;
wire [width-1:0]                 next_cache_data_1dp_s0;
wire [width-1:0]                 next_cache_data_1dp_s1;
wire [width-1:0]                 next_cache_data_1dp_s2;

wire                             cache_data_2dp_ram_sel0;
wire                             cache_data_2dp_shft_sel0;
wire                             cache_data_2dp_ram_sel1;
wire [width-1:0]                 next_cache_data_2dp_s0;
wire [width-1:0]                 next_cache_data_2dp_s1;
wire [width-1:0]                 next_cache_data_2dp_s2;

wire                             cache_data_3dp_ram_sel0;
wire                             cache_data_3dp_shft_sel0;
wire                             cache_data_3dp_ram_sel1;
wire                             cache_data_3dp_shft_sel1;
wire                             cache_data_3dp_ram_sel2;
wire [width-1:0]                 next_cache_data_3dp_s0;
wire [width-1:0]                 next_cache_data_3dp_s1;
wire [width-1:0]                 next_cache_data_3dp_s2;

reg  [width-1:0]                 next_cache_data  [0:2];
reg  [width-1:0]                 cache_data       [0:2];
// End of Pipeline Cache declarations



wire [cache_inuse_idx_width-1:0]     cache_max; 
wire [cache_inuse_width-1:0]         cache_inuse;
wire                                 next_cache_full;

reg  [cache_inuse_idx_width-1:0]     total_census; 
wire [cache_inuse_idx_width:0]       next_total_census;
wire [cache_inuse_idx_width-1:0]     next_rdtr_census; 
reg  [cache_inuse_idx_width-1:0]     next_cache_census; 
wire [cnt_width-1:0]                 next_cache_census_padded; 
wire [cache_inuse_idx_width-1:0]     next_total_census_btg; 
reg  [cache_inuse_idx_width-1:0]     total_census_btg;

  assign  pop_d  = ~pop_d_n;

generate 
  if (two_deep_cache) begin : GEN_RDTR_2DPC
    assign next_rdtr_census = {1'b0, next_rdtr_reg[0]};
  end else begin : GEN_RDTR_NOT_2DPC
    if (three_deep_cache) begin : GEN_RDTR_3DPC
      assign next_rdtr_census = {next_rdtr_reg[1]&next_rdtr_reg[0], next_rdtr_reg[1]^next_rdtr_reg[0]};
    end else begin : GEN_RDTR_1DPC
      assign next_rdtr_census = {cache_inuse_idx_width{1'b0}};
    end
  end
endgenerate

  always @(next_inuse) begin : next_inuse_PROC
    integer  j, cnt;
    cnt = 0;
    for (j=0; j<cache_inuse_width; j=j+1) begin
      cnt = cnt + ((next_inuse[j] == 1'b1) ? 1 : 0);
    end  // for-loop
    for (j=0;j<cache_inuse_idx_width;j=j+1) next_cache_census[ j ] = (((cnt>>j)&1)!=0)?1'b1:1'b0;
  end  // always @(next_inuse

  assign next_total_census = next_rdtr_census + next_cache_census;

  assign next_cache_census_padded = {{(cnt_width-cache_inuse_idx_width){1'b0}}, next_cache_census};

// Create count to be passed out
generate
  if (cache_inuse_idx_width == 2) begin : GEN_BTG_INUSE_INDEX_IS_2
    
  function [cache_inuse_idx_width-1:0] func_bin2gray ;
    input [cache_inuse_idx_width-1:0]		B;	// input
    begin 
      func_bin2gray  = B ^ { 1'b0, B[cache_inuse_idx_width-1 : 1] }; 
    end
  endfunction

  assign next_total_census_btg = func_bin2gray ( next_total_census[cache_inuse_idx_width-1:0] );
  end else begin : GEN_BTG_INUSE_INDEX_IS_1
    assign next_total_census_btg = next_total_census[cache_inuse_idx_width-1:0];   
  end
endgenerate


  assign cache_max = cache_inuse_width[cache_inuse_idx_width-1:0];

  assign adv_cnt = (total_census < cache_max) && ~ram_empty_int;

  assign pop_ram = pop_d && ~ram_empty_int;

  assign ld_rdtr = pop_ram || adv_cnt;

generate
  if (three_deep_cache) begin : GEN_RDTR_REG_3DPC
    assign next_rdtr_reg[1] = ld_rdtr;
    assign next_rdtr_reg[0] = rdtr_reg[1];
  end else begin : GEN_RDTR_REG_NON_3DPC
    assign next_rdtr_reg[1] = 1'b0;
    assign next_rdtr_reg[0] = ld_rdtr;
  end
endgenerate

generate
  if (one_deep_cache) begin : GEN_LD_CACHE_1DPC
    assign ld_cache = ld_rdtr;
  end else begin : GEN_LD_CACHE_GT_1DPC
    assign ld_cache = rdtr_reg[0];
  end
endgenerate



  assign inuse_1dp_select0 = pop_d || ld_cache;
  assign next_inuse_1dp[0] = inuse_1dp_select0 ? ld_cache : inuse[0];
  assign next_inuse_1dp[1] = 1'b0;
  assign next_inuse_1dp[2] = 1'b0;

  assign inuse_2dp_select0 = (ld_cache && ~inuse[0]) || (pop_d && ~ld_cache && ~inuse[1]);
  assign inuse_2dp_select1 = (pop_d && ~ld_cache) || (~pop_d && ld_cache && inuse[0]);
  assign next_inuse_2dp[0] = inuse_2dp_select0 ? ld_cache : inuse[0];
  assign next_inuse_2dp[1] = inuse_2dp_select1 ? ld_cache : inuse[1];
  assign next_inuse_2dp[2] = 1'b0;

  assign inuse_3dp_select0 = (pop_d && ld_cache) || (~pop_d && ld_cache) || (pop_d && ~ld_cache && ~inuse[1] && ~inuse[2]);
  assign inuse_3dp_select1 = (~pop_d && ld_cache && inuse[0] && ~inuse[2]) || (pop_d && ~ld_cache && ~inuse[2]);
  assign inuse_3dp_select2 = (pop_d && ~ld_cache) || (~pop_d && ld_cache && inuse[0] && inuse[1]);
  assign next_inuse_3dp[0] = inuse_3dp_select0 ? ld_cache : inuse[0];
  assign next_inuse_3dp[1] = inuse_3dp_select1 ? ld_cache : inuse[1];
  assign next_inuse_3dp[2] = inuse_3dp_select2 ? ld_cache : inuse[2];

generate
  if (one_deep_cache) begin : GEN_INUSE_1DPC
    assign next_inuse = next_inuse_1dp;
  end else begin : GEN_INUSE_NOT_1DPC
    if (two_deep_cache) begin : GEN_INUSE_2DPC
      assign next_inuse = next_inuse_2dp;
    end else begin : GEN_INUSE_3DPC
      assign next_inuse = next_inuse_3dp;
    end
  end
endgenerate

  assign cache_census_gray_d    = total_census_btg;


generate
  if (((mem_mode % 2) == 0) && (((mem_mode/2) % 2) == 1)) begin : GEN_MM_EQ_2_OR_6
    assign ram_empty_pipe = ram_empty_d1_int;
  end else begin : GEN_MM_NE_2_AND_NE_6
    assign ram_empty_pipe = ram_empty_int;
  end
endgenerate

generate
  if ((mem_mode % 2) == 0) begin : GEN_MM_EVEN
    assign rd_data_d_int = (ram_empty_pipe == 1'b1) ? {width{1'b0}} : rd_data_d;
  end else begin : GEN_MM_ODD
    assign rd_data_d_int = rd_data_d;
  end
endgenerate

  //### Pipeline Cache loading data section ###
    // load cache data
    assign cache_data_1dp_ram_sel0 = (ld_cache && ~inuse[0]) || (pop_d && ld_cache && inuse[0]);
    assign next_cache_data_1dp_s0  = cache_data_1dp_ram_sel0 ? rd_data_d_int : cache_data[0];
    assign next_cache_data_1dp_s1  = {width{1'b0}};
    assign next_cache_data_1dp_s2  = {width{1'b0}};
  
    assign cache_data_2dp_ram_sel0  = (ld_cache && ~inuse[0]) || (pop_d && ld_cache && ~inuse[1]);
    assign cache_data_2dp_shft_sel0 = pop_d && inuse[1];
    assign cache_data_2dp_ram_sel1  = (~pop_d && ld_cache && inuse[0] && ~inuse[1]) || (pop_d && ld_cache && inuse[1]);
    assign next_cache_data_2dp_s0   = cache_data_2dp_ram_sel0 ? rd_data_d_int : cache_data_2dp_shft_sel0 ? cache_data[1] : cache_data[0];
    assign next_cache_data_2dp_s1   = cache_data_2dp_ram_sel1 ? rd_data_d_int : cache_data[1];
    assign next_cache_data_2dp_s2   = {width{1'b0}};
  
    assign cache_data_3dp_ram_sel0  = (ld_cache && ~inuse[0]) || (pop_d && ld_cache && ~inuse[1]);
    assign cache_data_3dp_shft_sel0 = pop_d && inuse[1];
    assign cache_data_3dp_ram_sel1  = (~pop_d && ld_cache && inuse[0] && ~inuse[1]) || (pop_d && ld_cache && inuse[1] && ~inuse[2]);
    assign cache_data_3dp_shft_sel1 = pop_d && inuse[2];
    assign cache_data_3dp_ram_sel2  = (~pop_d && ld_cache && inuse[1] && ~inuse[2]) || (pop_d && ld_cache && inuse[2]);
    assign next_cache_data_3dp_s0   = cache_data_3dp_ram_sel0 ? rd_data_d_int : cache_data_3dp_shft_sel0 ? cache_data[1] : cache_data[0];
    assign next_cache_data_3dp_s1   = cache_data_3dp_ram_sel1 ? rd_data_d_int : cache_data_3dp_shft_sel1 ? cache_data[2] : cache_data[1];
    assign next_cache_data_3dp_s2   = cache_data_3dp_ram_sel2 ? rd_data_d_int : cache_data[2];
  
generate
    if (one_deep_cache) begin : GEN_CDATA_1DPC
      always @(next_cache_data_1dp_s0 or next_cache_data_1dp_s1 or next_cache_data_1dp_s2) begin
        next_cache_data[0] = next_cache_data_1dp_s0;
        next_cache_data[1] = next_cache_data_1dp_s1;
        next_cache_data[2] = next_cache_data_1dp_s2;
      end  // of always
    end else begin : GEN_CDATA_NOT_1DPC
      if (two_deep_cache) begin : GEN_CDATA_2DPC
        always @(next_cache_data_2dp_s0 or next_cache_data_2dp_s1 or next_cache_data_2dp_s2) begin
          next_cache_data[0] = next_cache_data_2dp_s0;
          next_cache_data[1] = next_cache_data_2dp_s1;
          next_cache_data[2] = next_cache_data_2dp_s2;
        end  // of always
      end else begin : GEN_CDATA_3DPC
        always @( next_cache_data_3dp_s0 or next_cache_data_3dp_s1 or next_cache_data_3dp_s2) begin
          next_cache_data[0] = next_cache_data_3dp_s0;
          next_cache_data[1] = next_cache_data_3dp_s1;
          next_cache_data[2] = next_cache_data_3dp_s2;
        end  // of always
      end
    end 
endgenerate
  //### End of Pipeline Cache data loading section ###


  assign a_empty_vector        = ae_level_d;
  assign hlf_full_vector       = hf_level[cnt_width-1:0];
  assign a_full_vector_temp    = (eff_depth - af_level_d);
  assign a_full_vector         = a_full_vector_temp[cnt_width:0];
  assign full_count_bus        = eff_depth[cnt_width-1:0];
  assign bus_low               = {cnt_width{1'b0}};
  assign residual_value_bus    = leftover_cnt[ram_cnt_width-1:0];
 
  assign tie_low               = 1'b0;
  assign tie_high              = 1'b1;

generate
  if (cache_inuse_width > 1) begin : GEN_INUSE_MULTIBIT
    assign next_cache_full = &next_inuse[cache_inuse_width-1:0];
  end else begin : GEN_INUSE_ONEBIT
    assign next_cache_full = next_inuse[0];
  end
endgenerate

  assign next_empty_d          = ~next_inuse[0];

generate
  if (cache_inuse_idx_width == 1) begin : GEN_NEXT_AED_CIIW_EQ_1
    always @(next_word_cnt_d_int or a_empty_vector or next_cache_full or almost_empty_d) begin
      if (almost_empty_d == 1'b1) begin
        next_almost_empty_d = ~((next_word_cnt_d_int > a_empty_vector) && (next_cache_full == 1'b1));
      end else begin
        next_almost_empty_d = (next_word_cnt_d_int <= a_empty_vector);
      end 
    end
  end else begin : GEN_NEXT_AED_CIIW_EQ_2
    always @(next_word_cnt_d_int or a_empty_vector or next_cache_full or almost_empty_d or next_cache_census_padded) begin
      if (almost_empty_d == 1'b1) begin
        next_almost_empty_d = ~((next_word_cnt_d_int > a_empty_vector) && 
                                ((next_cache_full == 1'b1) || (next_cache_census_padded > a_empty_vector)));
      end else begin
        next_almost_empty_d = (next_word_cnt_d_int <= a_empty_vector);
      end 
    end
  end
endgenerate

  always @(next_word_cnt_d_int or a_full_vector or next_cache_full or almost_full_d or next_cache_census_padded) begin
    if (almost_full_d == 1'b0) begin
      next_almost_full_d = (next_word_cnt_d_int >= a_full_vector[cnt_width-1:0]) && 
                           ((next_cache_full == 1'b1) || (next_cache_census_padded >= a_full_vector[cnt_width-1:0]));
    end else begin
      next_almost_full_d = (next_word_cnt_d_int >= a_full_vector[cnt_width-1:0]);
    end
  end

  always @(next_word_cnt_d_int or next_cache_full or half_full_d) begin
    if (half_full_d == 1'b0) begin
      next_half_full_d = (next_word_cnt_d_int >= $unsigned(hf_level)) && (next_cache_full == 1'b1);
    end else begin
      next_half_full_d = (next_word_cnt_d_int >= $unsigned(hf_level));
    end
  end

  always @(next_word_cnt_d_int or next_cache_full or full_d) begin
    if (full_d == 1'b0) begin
      next_full_d = (next_word_cnt_d_int == $unsigned(eff_depth)) && (next_cache_full == 1'b1);
    end else begin
      next_full_d = (next_word_cnt_d_int == $unsigned(eff_depth));
    end
  end



  assign error_seen = pop_d && empty_d;
generate
  if (err_mode == 0) begin : GEN_EM_EQ_0
    assign next_error_d_int = error_seen || error_d_int;
  end else begin : GEN_EM_NE_0
    assign next_error_d_int = error_seen;
  end
endgenerate

  // Merge synchronous reset signals into one
  assign init_regs_n = init_d_n && ~clr_in_prog_d;

  always @ (posedge clk_d or negedge rst_d_n) begin : clk_d_reg_PROC
     integer  c_idx;

     if (!rst_d_n) begin
       inuse               <= {3{1'b0}};
       rdtr_reg            <= {2{1'b0}};
       ram_empty           <= 1'b0;
       ram_empty_d1        <= 1'b0;
       total_census        <= {cache_inuse_idx_width{1'b0}};
       total_census_btg    <= {cache_inuse_idx_width{1'b0}};
       word_cnt_d_int      <= {cnt_width{1'b0}};
       ram_word_cnt_d_int  <= {ram_cnt_width{1'b0}};
       empty_d_int         <= 1'b0;
       almost_empty_d_int  <= 1'b0;
       half_full_d_int     <= 1'b0;
       almost_full_d_int   <= 1'b0;
       full_d_int          <= 1'b0;
       error_d_int         <= 1'b0;
       for (c_idx=0; c_idx<3; c_idx=c_idx+1) begin
	 cache_data[c_idx] <= {width{1'b0}};
       end  // for-loop
     end else begin
       inuse               <= next_inuse & {3{init_regs_n}};
       rdtr_reg            <= next_rdtr_reg & {2{init_regs_n}};
       ram_empty           <= next_ram_empty & init_regs_n;
       ram_empty_d1        <= ram_empty & init_regs_n;
       total_census        <= next_total_census[cache_inuse_idx_width-1:0] & {cache_inuse_idx_width{init_regs_n}};
       total_census_btg    <= next_total_census_btg & {cache_inuse_idx_width{init_regs_n}};
       word_cnt_d_int      <= next_word_cnt_d_int & {cnt_width{init_regs_n}};
       ram_word_cnt_d_int  <= next_ram_word_cnt_d_int & {ram_cnt_width{init_regs_n}};
       empty_d_int         <= ~next_empty_d & init_regs_n;
       almost_empty_d_int  <= ~next_almost_empty_d & init_regs_n;
       half_full_d_int     <= next_half_full_d & init_regs_n;
       almost_full_d_int   <= next_almost_full_d & init_regs_n;
       full_d_int          <= next_full_d & init_regs_n;
       error_d_int         <= next_error_d_int & init_regs_n;
       for (c_idx=0; c_idx<3; c_idx=c_idx+1) begin
	 cache_data[c_idx] <= next_cache_data[c_idx] & {width{init_regs_n}};
       end  // for-loop
     end
    end




  assign ram_empty_int     = ~ram_empty;
  assign ram_empty_d1_int  = ~ram_empty_d1;
 
  assign next_ram_empty = |next_ram_word_cnt_d_temp && ~clr_in_prog_d;

generate
  if (one_deep_cache || (ram_re_ext == 0)) begin : GEN_RRE_EQ_0_OR_1DPC
    assign ram_re_d_n = ~ld_rdtr;
  end else begin : GEN_RRE_NE_0_AND_NOT_1DPC
    if (two_deep_cache) begin : GEN_RRE_NE_0_AND_2DPC
      assign ram_re_d_n = ~ld_rdtr & ~rdtr_reg[0];
    end else begin : GEN_RRE_NE_0_AND_3DPC
      assign ram_re_d_n = ~ld_rdtr & ~rdtr_reg[0] & ~rdtr_reg[1];
    end
  end
endgenerate

  assign rd_en_d            = ld_rdtr;


  assign word_cnt_d         = word_cnt_d_int;
  assign ram_word_cnt_d     = ram_word_cnt_d_int;

  assign data_d             = cache_data[0];

  assign empty_d            = ~empty_d_int;
  assign almost_empty_d     = ~almost_empty_d_int;
  assign half_full_d        = half_full_d_int;
  assign almost_full_d      = almost_full_d_int;
  assign full_d             = full_d_int;
  assign error_d            = error_d_int;


  assign temp1                   = wr_ptr_d - rd_ptr_d;
  assign ram_word_cnt_d_p1       = temp1[ram_cnt_width-1 : 0];
  assign ram_word_cnt_d_p1_rgtw  = ram_word_cnt_d_p1 - residual_value_bus;
  assign word_cnt_d_p1           = ram_word_cnt_d_p1 + next_total_census[cache_inuse_idx_width-1:0];
  assign word_cnt_d_p1_rgtw      = ram_word_cnt_d_p1_rgtw[ram_cnt_width-1:0] + next_total_census[cache_inuse_idx_width-1:0];


  always @( ram_word_cnt_d_p1 or ram_word_cnt_d_p1_rgtw or rd_ptr_d or wr_ptr_d or 
	    word_cnt_d_p1 or word_cnt_d_p1_rgtw) begin
    if (rd_ptr_d > wr_ptr_d) begin
      next_ram_word_cnt_d_temp = ram_word_cnt_d_p1_rgtw[ram_cnt_width-1:0];
      next_word_cnt_d_temp     = word_cnt_d_p1_rgtw[cnt_width-1:0];
    end else begin
      next_ram_word_cnt_d_temp = ram_word_cnt_d_p1;
      next_word_cnt_d_temp     = word_cnt_d_p1[cnt_width-1:0];
    end
  end

  assign next_ram_word_cnt_d_int  = next_ram_word_cnt_d_temp;
  assign next_word_cnt_d_int      = next_word_cnt_d_temp;


endmodule
