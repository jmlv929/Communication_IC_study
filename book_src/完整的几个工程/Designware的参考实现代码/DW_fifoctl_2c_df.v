
////////////////////////////////////////////////////////////////////////////////
//
//
// ABSTRACT: Dual clock domain interface FIFO controller
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
//      f_sync_type      1 to 4       default: 2
//                                    Mode of forward synchronization (source to destination)
//                                      1 => 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing,
//                                      2 => 2-stage synchronization w/ both stages pos-edge capturing,
//                                      3 => 3-stage synchronization w/ all stages pos-edge capturing
//                                      4 => 4-stage synchronization w/ all stages pos-edge capturing
//
//      r_sync_type      1 to 4       default: 2
//                                    Mode of reverse synchronization (destination to source)
//                                      1 => 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing,
//                                      2 => 2-stage synchronization w/ both stages pos-edge capturing,
//                                      3 => 3-stage synchronization w/ all stages pos-edge capturing
//                                      4 => 4-stage synchronization w/ all stages pos-edge capturing
//
//      clk_ratio   -7 to 1, 1 to 7   default: 1
//                                    Rounded quotient between clk_s and clk_d
//                                      1 to 7   => when clk_d rate faster than clk_s rate: round(clk_d rate / clk_s rate)
//                                      -7 to -1 => when clk_d rate slower than clk_s rate: 0 - round(clk_s rate / clk_d rate)
//                                      NOTE: 0 is illegal
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
//      tst_mode         0 to 2       default: 0
//                                    Latch insertion for testing purposes
//                                      0 => no hold latch inserted,
//                                      1 => insert hold 'latch' using a neg-edge triggered register
//                                      2 => insert hold latch using active low latch
//
//        verif_en       0 to 4       Synchronization missampling control (Simulation verification)
//                                    Default value = 1
//                                    0 => no sampling errors modeled,
//                                    1 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 1 cycle delay
//                                    2 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 1.5 cycle delay
//                                    3 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 3 cycle delay
//                                    4 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 0.5 cycle delay
//                                    Note: Use `define DW_MODEL_MISSAMPLES to define the Verilog macro
//                                          that turns on missample modeling in a Verilog HDL file.  Use
//                                          +define+DW_MODEL_MISSAMPLES simulator command line option to turn
//                                          on missample modeleng from the simulator command.
//
//      clr_dual_domain  0 or 1       default: 1
//                                    Activity of clr_s and/or clr_d
//                                      0 => either clr_s or clr_d can be activated, but the other must be tied 'low'
//                                      1 => both clr_s and clr_d can be activated
//
//      arch_type        0 or 1       default: 0
//                                    Pre-fetch cache architecture type
//                                      0 => Pipeline style
//                                      1 => Register File style
//
//
//      Inputs 	         Size	    Description
//      ======	         ====	    ===========
//      clk_s	         1 bit	    Source Domain Clock
//      rst_s_n	         1 bit	    Source Domain Asynchronous Reset (active low)
//      init_s_n         1 bit	    Source Domain Synchronous Reset (active low)
//      clr_s            1 bit      Source Domain Clear to initiate orchestrated reset (active high pulse)
//      ae_level_s       N bits     Source Domain RAM almost empty threshold setting
//      af_level_s       N bits     Source Domain RAM almost full threshold setting
//      push_s_n         1 bit      Source Domain push request (active low)
//
//      clk_d	         1 bit	    Destination Domain Clock
//      rst_d_n	         1 bit	    Destination Domain Asynchronous Reset (active low)
//      init_d_n         1 bit	    Destination Domain Synchronous Reset (active low)
//      clr_d            1 bit      Destination Domain Clear to initiate orchestrated reset (active high pulse)
//      ae_level_d       Q bits     Destination Domain FIFO almost empty threshold setting
//      af_level_d       Q bits     Destination Domain FIFO almost full threshold setting
//      pop_d_n          1 bit      Destination Domain pop request (active low)
//      rd_data_d        M bits     Destination Domain read data from RAM
//
//      test             1 bit      Test input
//
//      Outputs	         Size	    Description
//      =======	         ====	    ===========
//      clr_sync_s       1 bit      Source Domain synchronized clear (active high pulse)
//      clr_in_prog_s    1 bit      Source Domain orchestrate clearing in progress
//      clr_cmplt_s      1 bit      Source Domain orchestrated clearing complete (active high pulse)
//      wr_en_s_n        1 bit      Source Domain write enable to RAM (active low)
//      wr_addr_s        P bits     Source Domain write address to RAM
//      fifo_word_cnt_s  Q bits     Source Domain FIFO word count (includes cache)
//      word_cnt_s       N bits     Source Domain RAM only word count
//      fifo_empty_s     1 bit	    Source Domain FIFO Empty Flag
//      empty_s          1 bit	    Source Domain RAM Empty Flag
//      almost_empty_s   1 bit	    Source Domain RAM Almost Empty Flag
//      half_full_s      1 bit	    Source Domain RAM Half Full Flag
//      almost_full_s    1 bit	    Source Domain RAM Almost Full Flag
//      full_s	         1 bit	    Source Domain RAM Full Flag
//      error_s	         1 bit	    Source Domain Error Flag
//
//      clr_sync_d       1 bit      Destination Domain synchronized clear (active high pulse)
//      clr_in_prog_d    1 bit      Destination Domain orchestrate clearing in progress
//      clr_cmplt_d      1 bit      Destination Domain orchestrated clearing complete (active high pulse)
//      ram_re_d_n       1 bit      Destination Domain Read Enable to RAM (active-low)
//      rd_addr_d        P bits     Destination Domain read address to RAM
//      data_d           M bits     Destination Domain data out
//      word_cnt_d       Q bits     Destination Domain FIFO word count (includes cache)
//      ram_word_cnt_d   N bits     Destination Domain RAM only word count
//      empty_d	         1 bit	    Destination Domain Empty Flag
//      almost_empty_d   1 bit	    Destination Domain Almost Empty Flag
//      half_full_d      1 bit	    Destination Domain Half Full Flag
//      almost_full_d    1 bit	    Destination Domain Almost Full Flag
//      full_d	         1 bit	    Destination Domain Full Flag
//      error_d	         1 bit	    Destination Domain Error Flag
//
//           Note: M is equal to the width parameter
//
//           Note: N is based on ram_depth:
//                   N = ceil(log2(ram_depth+1))
//
//           Note: P is ceil(log2(ram_depth))
//
//           Note: Q is based on the mem_mode parameter:
//                   Q = ceil(log2((ram_depth+1)+1)) when mem_mode = 0 or 4
//                   Q = ceil(log2((ram_depth+1)+2)) when mem_mode = 1, 2, 5, or 6
//                   Q = ceil(log2((ram_depth+1)+3)) when mem_mode = 3 or 7
//
//
// MODIFIED:
//
//	    RJK - 3/21/12
//	    Corrected problems with use when depth is greater than 65533
//	    (STAR 9000530636)
//  
//          DLL - 10/04/11
//          Instrumented to allow the "alt" version of this component for
//          BCMs to be used for its derivation.
//
//          DLL - 7/29/11
//          Removed 'init_s_n_merge' into DW_sync...only use 'init_s_n'.  Also added
//          tst_mode=2 capability.
//
//          DLL - 7/6/11
//          Edits to cleanup Leda warnings/errors.
//
//          DLL - 11/15/10
//          Fixed default values for some parameters to match across all
//          source code.
//          This fix addresses STAR#9000429754.
//
//          DLL - 3/16/10
//          Add 'clr_in_prog_s' to 'init_s_n' to initialize synchronizer handling
//          the cache count gray code value from destination to source domains.
//          This fix addresses STAR#9000381235.
//          This fix addresses STAR#9000381234.
//
//
//          DLL - 11/4/09
//          Change wire width and naming related to cache_inuse_d
//          because now the cache count includes RAM read in progress
//          state.  Change the naming of "cache_inuse" to "cache_census"
//          and created a gray code vector to be decoded into the 'sif'.
//          This fix addresses STAR#9000353986.
//
//          DLL - 10/31/08
//          Added 'arch_type' parameter to match 'lpwr' implementation.
//
//		
////////////////////////////////////////////////////////////////////////////////


module DW_fifoctl_2c_df(
        clk_s,
        rst_s_n,
        init_s_n,
        clr_s,
        ae_level_s,
        af_level_s,
        push_s_n,
  
        clr_sync_s,
        clr_in_prog_s,
        clr_cmplt_s,
	wr_en_s_n,
	wr_addr_s,
        fifo_word_cnt_s,
        word_cnt_s,
        fifo_empty_s,
        empty_s,
        almost_empty_s,
        half_full_s,
        almost_full_s,
        full_s,
        error_s,

        clk_d,
        rst_d_n,
        init_d_n,
        clr_d,
        ae_level_d,
        af_level_d,
        pop_d_n,
        rd_data_d,
  
        clr_sync_d,
        clr_in_prog_d,
        clr_cmplt_d,
	ram_re_d_n,
	rd_addr_d,
        data_d,
        word_cnt_d,
        ram_word_cnt_d,
        empty_d,
        almost_empty_d,
        half_full_d,
        almost_full_d,
        full_d,
        error_d,

	test
        // Embedded dc_shell script
        //   set_implementation "rtl"  [find "cell" "U_DIF"]
        // _model_constraint_1
	);

parameter width            =  8;   // RANGE 1 to 1024
parameter ram_depth        =  8;   // RANGE 4 to 16777216
parameter mem_mode         =  3;   // RANGE 0 to 7
parameter f_sync_type	   =  2;   // RANGE 1 to 4
parameter r_sync_type      =  2;   // RANGE 1 to 4
parameter clk_ratio        =  1;   // RANGE -7 to -1, 1 to 7
parameter ram_re_ext       =  0;   // RANGE 0 to 1
parameter err_mode  	   =  0;   // RANGE 0 to 1
parameter tst_mode  	   =  0;   // RANGE 0 to 2

parameter verif_en  	   =  1;   // RANGE 0 to 4

parameter clr_dual_domain  =  1;   // RANGE 0 to 1
parameter arch_type  	   =  0;   // RANGE 0 to 1
   





localparam lcl_addr_width      = ((ram_depth>65536)?((ram_depth>1048576)?((ram_depth>4194304)?((ram_depth>8388608)?24:23):((ram_depth>2097152)?22:21)):((ram_depth>262144)?((ram_depth>524288)?20:19):((ram_depth>131072)?18:17))):((ram_depth>256)?((ram_depth>4096)?((ram_depth>16384)?((ram_depth>32768)?16:15):((ram_depth>8192)?14:13)):((ram_depth>1024)?((ram_depth>2048)?12:11):((ram_depth>512)?10:9))):((ram_depth>16)?((ram_depth>64)?((ram_depth>128)?8:7):((ram_depth>32)?6:5)):((ram_depth>4)?((ram_depth>8)?4:3):((ram_depth>2)?2:1)))));
localparam cnt_width           = ((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))));
localparam lcl_fifo_cnt_width  = (((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>65536)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16777216)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>268435456)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>536870912)?30:29):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>67108864)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>134217728)?28:27):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>33554432)?26:25))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>1048576)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4194304)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8388608)?24:23):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2097152)?22:21)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>262144)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>524288)?20:19):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>131072)?18:17)))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>256)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4096)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16384)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>32768)?16:15):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8192)?14:13)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>1024)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2048)?12:11):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>512)?10:9))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>64)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>128)?8:7):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>32)?6:5)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8)?4:3):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2)?2:1)))));
localparam cache_cnt_idx_width = (((((mem_mode==0)||(mem_mode==4)) ? 1 : (((mem_mode==3)||(mem_mode==7)) ? 3 : 2)) == 1) ? 1 : 2);
localparam offset             = (((1 << ((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))) - ((ram_depth == (1 << (((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))-1))) ? (ram_depth*2) : ((ram_depth+2) - (ram_depth & 1)))) / 2);
localparam gray_verif_en      = ((verif_en==2)?4:((verif_en==3)?1:verif_en));


localparam push_bin2gray_delay = (((mem_mode & 4) == 4) ? (((f_sync_type & 7) + (((mem_mode & 2) == 2) ? 2 : 1)) <= clk_ratio) : 0);
localparam pop_bin2gray_delay  = (((((ram_depth == (1 << (((ram_depth+1>65536)?((ram_depth+1>16777216)?((ram_depth+1>268435456)?((ram_depth+1>536870912)?30:29):((ram_depth+1>67108864)?((ram_depth+1>134217728)?28:27):((ram_depth+1>33554432)?26:25))):((ram_depth+1>1048576)?((ram_depth+1>4194304)?((ram_depth+1>8388608)?24:23):((ram_depth+1>2097152)?22:21)):((ram_depth+1>262144)?((ram_depth+1>524288)?20:19):((ram_depth+1>131072)?18:17)))):((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1)))))-1))) ? 1 : 0) == 1) && ((mem_mode & 2) == 2)) ? ((0 - ((r_sync_type & 7) + (((mem_mode & 4) == 4) ? 2 : 1))) >= clk_ratio) : 0);



input                            clk_s;            // Source Domain Clock 
input                            rst_s_n;          // Source Domain Asynchronous Reset (active low) 
input                            init_s_n;         // Source Domain Synchronous Reset (active low) 
input                            clr_s;            // Source Domain Clear for coordinated reset (active high pulse) 
input  [cnt_width-1:0]           ae_level_s;       // Source Domain RAM almost empty threshold setting 
input  [cnt_width-1:0]           af_level_s;       // Source Domain RAM almost full threshold setting 
input                            push_s_n;         // Source Domain push request (active low) 

output                           clr_sync_s;       // Source Domain synchronized clear (active high pulse) 
output                           clr_in_prog_s;    // Source Domain orchestrate clearing in progress (unregistered) 
output                           clr_cmplt_s;      // Source Domain orchestrated clearing complete (active high pulse) 
output                           wr_en_s_n;        // Source Domain write enable to RAM (active low) 
output [lcl_addr_width-1:0]      wr_addr_s;        // Source Domain write address to RAM 
output [lcl_fifo_cnt_width-1:0]  fifo_word_cnt_s;  // Source Domain FIFO word count (includes cache) 
output [cnt_width-1:0]           word_cnt_s;       // Source Domain RAM only word count 
output                           fifo_empty_s;     // Source Domain FIFO Empty Flag 
output                           empty_s;          // Source Domain RAM Empty Flag 
output                           almost_empty_s;   // Source Domain RAM Almost Empty Flag 
output                           half_full_s;      // Source Domain RAM Half Full Flag 
output                           almost_full_s;    // Source Domain RAM Almost Full Flag 
output                           full_s;	   // Source Domain RAM Full Flag 
output                           error_s;          // Source Domain Error Flag 

input                            clk_d;            // Destination Domain Clock 
input                            rst_d_n;          // Destination Domain Asynchronous Reset (active low) 
input                            init_d_n;         // Destination Domain Synchronous Reset (active low) 
input                            clr_d;            // Destination Domain Clear to initiate orchestrated reset (active high pulse) 
input  [lcl_fifo_cnt_width-1:0]  ae_level_d;       // Destination Domain FIFO almost empty threshold setting 
input  [lcl_fifo_cnt_width-1:0]  af_level_d;       // Destination Domain FIFO almost full threshold setting 
input                            pop_d_n;          // Destination Domain pop request (active low) 
input  [width-1:0]               rd_data_d;        // Destination Domain data read from RAM 

output                           clr_sync_d;       // Destination Domain synchronized orchestrated clear (active high pulse) 
output                           clr_in_prog_d;    // Destination Domain orchestrate clearing in progress (unregistered) 
output                           clr_cmplt_d;      // Destination Domain orchestrated clearing complete (active high pulse) 
output                           ram_re_d_n;       // Destination Domain Read Enable to RAM (active-low) 
output [lcl_addr_width-1:0]      rd_addr_d;        // Destination Domain read address to RAM 
output [width-1:0]               data_d;           // Destination Domain data out 
output [lcl_fifo_cnt_width-1:0]  word_cnt_d;       // Destination Domain FIFO word count (includes cache) 
output [cnt_width-1:0]       ram_word_cnt_d;   // Destination Domain RAM only word count 
output                           empty_d;          // Destination Domain Empty Flag 
output                           almost_empty_d;   // Destination Domain Almost Empty Flag 
output                           half_full_d;      // Destination Domain Half Full Flag 
output                           almost_full_d;    // Destination Domain Almost Full Flag 
output                           full_d;	   // Destination Domain Full Flag 
output                           error_d;          // Destination Domain Error Flag 

input                            test;             // Test input 

// wiring for DW_sync
wire  [cache_cnt_idx_width-1:0]  cache_census_gray_d_cc;
reg   [cache_cnt_idx_width-1:0]  cache_census_gray_d_l;
// synchronized gray-coded vector
wire  [cache_cnt_idx_width-1:0]  cache_census_gray_s;

// Source Domain interconnects
wire                         wr_en_s;        // Source Domain enable to gray code synchronizer
wire  [cnt_width-1:0]    wr_ptr_s;       // Source Domain next write pointer (relative to RAM) - unregisterd
wire  [cnt_width-1:0]    rd_ptr_s;       // Source Domain synchronized read pointer (relative to RAM)
wire  [cache_cnt_idx_width-1:0]  cache_census_s;  // Source Domain synchronized external cache count (binary value vector)

// Destination Domain interconnects
wire  [cnt_width-1:0]    wr_ptr_d;       // Destination Domain next write pointer (relative to RAM) - unregisterd
wire  [cnt_width-1:0]    rd_ptr_d;       // Destination Domain synchronized read pointer (relative to RAM)

// Write address from DW_gray_sync that goes to RAM possibility with
// one less bit if cnt_width > lcl_addr_width
// So, always wire up to RAM wr_addr_s_u_fwd_gray[lcl_addr_width-1:0].
wire  [cnt_width-1:0]    wr_addr_s_u_fwd_gray;

wire  [cache_cnt_idx_width-1:0]  cache_census_gray_d;  // Destination Domain external cache count in gray-code (incl RAM read in progress count)
wire                             rd_en_d;

// Read address from DW_gray_sync that goes to RAM possibility with
// one less bit if cnt_width > lcl_addr_width
// So, always wire up to RAM rd_addr_d_u_rev_gray[lcl_addr_width-1:0].
wire  [cnt_width-1:0]    rd_addr_d_u_rev_gray;

wire   init_s_n_merge;
wire   init_d_n_merge;





DW_reset_sync #((f_sync_type + 8), (r_sync_type + 8), 0, 0, tst_mode, verif_en) U1 (
            .clk_s(clk_s),
            .rst_s_n(rst_s_n),
            .init_s_n(init_s_n),
            .clr_s(clr_s),
            .clk_d(clk_d),
            .rst_d_n(rst_d_n),
            .init_d_n(init_d_n),
            .clr_d(clr_d),
            .test(test),
            .clr_sync_s(clr_sync_s),
            .clr_in_prog_s(clr_in_prog_s),
            .clr_cmplt_s(clr_cmplt_s),
            .clr_in_prog_d(clr_in_prog_d),
            .clr_sync_d(clr_sync_d),
            .clr_cmplt_d(clr_cmplt_d)
            );


// Source Domain (push) interface
DWsc_fifoctl_sif #(ram_depth, mem_mode, err_mode) U_SIF (
            .clk_s(clk_s),
            .rst_s_n(rst_s_n),
            .init_s_n(init_s_n),
            .clr_sync_s(clr_sync_s),
            .ae_level_s(ae_level_s),
            .af_level_s(af_level_s),
	    .clr_in_prog_s(clr_in_prog_s),
            .push_s_n(push_s_n),
            .wr_ptr_s(wr_ptr_s),
            .rd_ptr_s(rd_ptr_s),
            .cache_census_s(cache_census_s),
            .wr_en_s_n(wr_en_s_n),
            .wr_en_s(wr_en_s),
            .fifo_word_cnt_s(fifo_word_cnt_s),
            .word_cnt_s(word_cnt_s),
            .fifo_empty_s(fifo_empty_s),
            .empty_s(empty_s),
            .almost_empty_s(almost_empty_s),
            .half_full_s(half_full_s),
            .almost_full_s(almost_full_s),
            .full_s(full_s),
            .error_s(error_s)
            ); 


// Destination domain (pop) interface
DWsc_fifoctl_dif #(width, ram_depth, mem_mode, ram_re_ext, err_mode, arch_type) U_DIF (
            .clk_d(clk_d),
            .rst_d_n(rst_d_n),
            .init_d_n(init_d_n),
            .clr_sync_d(clr_sync_d),
            .ae_level_d(ae_level_d),
            .af_level_d(af_level_d),
	    .clr_in_prog_d(clr_in_prog_d),
            .pop_d_n(pop_d_n),
            .rd_data_d(rd_data_d),
            .wr_ptr_d(wr_ptr_d),
            .rd_ptr_d(rd_ptr_d),
	    .ram_re_d_n(ram_re_d_n),
            .rd_en_d(rd_en_d),
            .data_d(data_d),
            .word_cnt_d(word_cnt_d),
            .ram_word_cnt_d(ram_word_cnt_d),
            .cache_census_gray_d(cache_census_gray_d),
            .empty_d(empty_d),
            .almost_empty_d(almost_empty_d),
            .half_full_d(half_full_d),
            .almost_full_d(almost_full_d),
            .full_d(full_d),
            .error_d(error_d)
            );


  assign init_s_n_merge  = init_s_n && ~clr_in_prog_s;
  assign init_d_n_merge  = init_d_n && ~clr_in_prog_d;

DW_gray_sync #(cnt_width, offset, 0, (f_sync_type + 8), tst_mode, gray_verif_en, push_bin2gray_delay, 0, 1) U_FWD_GRAY (
            .clk_s(clk_s),
            .rst_s_n(rst_s_n),
            .init_s_n(init_s_n_merge),  
            .en_s(wr_en_s),
            .count_s(wr_ptr_s), 
            .offset_count_s(wr_addr_s_u_fwd_gray),
            .clk_d(clk_d), 
            .rst_d_n(rst_d_n), 
            .init_d_n(init_d_n_merge),
            .count_d(wr_ptr_d), 
            .test(test)
            );

DW_gray_sync #(cnt_width, offset, 0, (r_sync_type + 8), tst_mode, gray_verif_en, pop_bin2gray_delay, 0, 1) U_REV_GRAY (
            .clk_s(clk_d),
            .rst_s_n(rst_d_n),
            .init_s_n(init_d_n_merge),  
            .en_s(rd_en_d),
            .count_s(rd_ptr_d), 
            .offset_count_s(rd_addr_d_u_rev_gray),
            .clk_d(clk_s), 
            .rst_d_n(rst_s_n), 
            .init_d_n(init_s_n_merge),
            .count_d(rd_ptr_s), 
            .test(test)
            );



  
generate
  if (((r_sync_type&7)>1)&&(tst_mode==2)) begin : GEN_LATCH_rvs_hold_latch_PROC
    always @ (clk_d or cache_census_gray_d) begin : rvs_hold_latch_PROC
      if (clk_d == 1'b0)

	cache_census_gray_d_l <= cache_census_gray_d;

    end // rvs_hold_latch_PROC

    assign cache_census_gray_d_cc = (test==1'b1)? cache_census_gray_d_l : cache_census_gray_d;
  end else begin : GEN_DIRECT_rvs_hold_latch_PROC
    assign cache_census_gray_d_cc = cache_census_gray_d;
  end
endgenerate

  DW_sync #(cache_cnt_idx_width, r_sync_type+8, tst_mode, verif_en) U_DW_SYNC_R(
	.clk_d(clk_s),
	.rst_d_n(rst_s_n),
	.init_d_n(init_s_n),
	.data_s(cache_census_gray_d_cc),
	.test(test),
	.data_d(cache_census_gray_s) );

  
  function [cache_cnt_idx_width-1:0] func_gray2bin ;
    input [cache_cnt_idx_width-1:0]		G;	// input
    reg   [cache_cnt_idx_width-1:0]		b;
    integer			i;
    begin 
      b = {cache_cnt_idx_width{1'b0}};
      for (i=cache_cnt_idx_width-1 ; i >= 0 ; i=i-1) begin
        if (i < cache_cnt_idx_width-1)


	  b[i] = G[i] ^ b[i+1];


	else
	  b[i] = G[i];
      end // for (i
      func_gray2bin  = b; 
    end
  endfunction

  assign cache_census_s = func_gray2bin ( cache_census_gray_s );

// Assign Source Domain Outputs
  assign wr_addr_s  = wr_addr_s_u_fwd_gray[lcl_addr_width-1:0];

// Assign Destination Domain Outputs
  assign rd_addr_d  = rd_addr_d_u_rev_gray[lcl_addr_width-1:0];

endmodule
