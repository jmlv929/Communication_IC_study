
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
//
// ABSTRACT: Dual clock domain interface assymetric FIFO controller Verilog Synthesis Model
//
//           Used for assymetric FIFOs with synchronous pipelined RAMs and
//           external caching.  Status flags are dynamically
//           configured.
//
//
//      Parameters     Valid Values   Description
//      ==========     ============   ===========
//      data_s_width    1 to 1024     default: 16
//                                    Width of data_s
//
//      data_d_width    1 to 1024     default: 8
//                                    Width of data_d
//
//      ram_depth       4 to 1024     default: 8
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
//      arch_type        0 or 1       default: 0
//                                    Pre-fetch cache architecture type
//                                      0 => Pipeline style
//                                      1 => Register File style
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
//      byte_order       1 to 0       default: 0
//                                      0 => the first byte (or subword) is in MSBs
//                                      1 => the first byte  (or subword)is in LSBs
//
//      flush_value      1 to 0        default: 0 
//                                      0 => fill empty bits of partial word with 0's upon flush
//                                      1 => fill empty bits of partial word with 1's upon flush
//
//      clk_ratio   -7 to 1, 1 to 7   default: 1
//                                    Rounded quotient between clk_s and clk_d
//                                      1 to 7   => when clk_d rate faster than clk_s rate: round(clk_d rate / clk_s rate)
//                                      -7 to -1 => when clk_d rate slower than clk_s rate: 0 - round(clk_s rate / clk_d rate)
//                                      NOTE: 0 is illegal
//
//      ram_re_ext       0 or 1       default: 1
//                                    Determines the charateristic of the ram_re_d_n signal to RAM
//                                      0 => Single-cycle pulse of ram_re_d_n at the read event to RAM
//                                      1 => Extend assertion of ram_re_d_n while read event active in RAM
//
//      err_mode         0 or 1       default: 0
//                                    Error Reporting Behavior
//                                      0 => sticky error flag
//                                      1 => dynamic error flag
//
//      tst_mode         0 or 1       default: 0
//                                    Latch insertion for testing purposes
//                                      0 => no hold latch inserted,
//                                      1 => insert hold 'latch' using a neg-edge triggered register
//                                      2 => insert hold latch using active low latch
//
//        verif_en     0, 1, or 4     Synchronization missampling control (Simulation verification)
//                                    Default value = 1
//                                    0 => no sampling errors modeled,
//                                    1 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 1 cycle delay
//                                    4 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 0.5 cycle delay
//                                    Note: Use `define DW_MODEL_MISSAMPLES to define the Verilog macro
//                                          that turns on missample modeling in a Verilog HDL file.  Use
//                                          +define+DW_MODEL_MISSAMPLES simulator command line option to turn
//                                          on missample modeleng from the simulator command.
//
//      Inputs           Size       Description
//      ======           ====       ===========
//      clk_s            1 bit      Source Domain Clock
//      rst_s_n          1 bit      Source Domain Asynchronous Reset (active low)
//      init_s_n         1 bit      Source Domain Synchronous Reset (active low)
//      clr_s            1 bit      Source Domain Clear to initiate orchestrated reset (active high pulse)
//      ae_level_s       N bits     Source Domain RAM almost empty threshold setting
//      af_level_s       N bits     Source Domain RAM almost full threshold setting
//      push_s_n         1 bit      Source Domain push request (active low)
//      flush_s_n        1 bit      Source Domain Flush the partial word into the full word memory (active low)
//      data_s           L bits     Source Domain data
//
//      clk_d            1 bit      Destination Domain Clock
//      rst_d_n          1 bit      Destination Domain Asynchronous Reset (active low)
//      init_d_n         1 bit      Destination Domain Synchronous Reset (active low)
//      clr_d            1 bit      Destination Domain Clear to initiate orchestrated reset (active high pulse)
//      ae_level_d       Q bits     Destination Domain FIFO almost empty threshold setting
//      af_level_d       Q bits     Destination Domain FIFO almost full threshold setting
//      pop_d_n          1 bit      Destination Domain pop request (active low)
//      rd_data_d        M bits     Destination Domain read data from RAM
//
//      test             1 bit      Test input
//
//      Outputs          Size       Description
//      =======          ====       ===========
//      clr_sync_s       1 bit      Source Domain synchronized clear (active high pulse)
//      clr_in_prog_s    1 bit      Source Domain orchestrate clearing in progress
//      clr_cmplt_s      1 bit      Source Domain orchestrated clearing complete (active high pulse)
//      wr_en_s_n        1 bit      Source Domain write enable to RAM (active low)
//      wr_addr_s        P bits     Source Domain write address to RAM
//      wr_data_s        M bits     Source Domain write data to RAM
//      inbuf_part_wd_s  1 bit      Source Domain partial word in input buffer flag (meaningful when data_s_width < data_d_width)
//      inbuf_full_s     1 bit      Source domain input buffer full flag (meaningful when data_s_width < data_d_width)
//      fifo_word_cnt_s  Q bits     Source Domain FIFO word count (includes cache)
//      word_cnt_s       N bits     Source Domain RAM only word count
//      fifo_empty_s     1 bit      Source Domain FIFO Empty Flag
//      empty_s          1 bit      Source Domain RAM Empty Flag
//      almost_empty_s   1 bit      Source Domain RAM Almost Empty Flag
//      half_full_s      1 bit      Source Domain RAM Half Full Flag
//      almost_full_s    1 bit      Source Domain RAM Almost Full Flag
//      ram_full_s       1 bit      Source Domain RAM Full Flag
//      push_error_s     1 bit      Source Domain Push Error Flag
//
//      clr_sync_d       1 bit      Destination Domain synchronized clear (active high pulse)
//      clr_in_prog_d    1 bit      Destination Domain orchestrate clearing in progress
//      clr_cmplt_d      1 bit      Destination Domain orchestrated clearing complete (active high pulse)
//      ram_re_d_n       1 bit      Destination Domain Read Enable to RAM (active-low)
//      rd_addr_d        P bits     Destination Domain read address to RAM
//      data_d           R bits     Destination Domain data out
//      outbuf_part_wd_d 1 bit      Destination Domain outbuf partial word popped flag (meaningful when data_s_width > data_d_width)
//      word_cnt_d       Q bits     Destination Domain FIFO word count (includes cache)
//      ram_word_cnt_d   N bits     Destination Domain RAM only word count
//      empty_d          1 bit      Destination Domain Empty Flag
//      almost_empty_d   1 bit      Destination Domain Almost Empty Flag
//      half_full_d      1 bit      Destination Domain Half Full Flag
//      almost_full_d    1 bit      Destination Domain Almost Full Flag
//      full_d           1 bit      Destination Domain Full Flag
//      pop_error_d      1 bit      Destination Domain Pop Error Flag
//
//           Note: L is equal to the data_s_width parameter
//           Note: M is equal to larger of data_s_width and data_d_width
//           Note: R is equal to the data_d_width parameter
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
//          DLL - 10/07/11
//          Added labels to all regions of generate statements.
//
//
////////////////////////////////////////////////////////////////////////////////

module DW_asymfifoctl_2c_df(
        clk_s,
        rst_s_n,
        init_s_n,
        clr_s,
        ae_level_s,
        af_level_s,
        push_s_n,
        flush_s_n,
        data_s,

        clr_sync_s,
        clr_in_prog_s,
        clr_cmplt_s,
        wr_en_s_n,
        wr_addr_s,
        wr_data_s,
        inbuf_part_wd_s,
        inbuf_full_s,
        fifo_word_cnt_s,
        word_cnt_s,
        fifo_empty_s,
        empty_s,
        almost_empty_s,
        half_full_s,
        almost_full_s,
        ram_full_s,
        push_error_s,

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
        outbuf_part_wd_d,
        word_cnt_d,
        ram_word_cnt_d,
        empty_d,
        almost_empty_d,
        half_full_d,
        almost_full_d,
        full_d,
        pop_error_d,

        test
        // Embedded dc_shell script
        //   set_implementation "rtl"  [find "cell" "U_FIFOCTL"]
        // _model_constraint_1

        );

parameter data_s_width     =  16;  // RANGE 1 to 1024
parameter data_d_width     =  8;   // RANGE 1 to 1024
parameter ram_depth        =  8;   // RANGE 4 to 1024
parameter mem_mode         =  3;   // RANGE 0 to 7
parameter arch_type        =  0;   // RANGE 0 to 1
parameter f_sync_type      =  2;   // RANGE 1 to 4
parameter r_sync_type      =  2;   // RANGE 1 to 4
parameter byte_order       =  0;   // RANGE 0 to 1
parameter flush_value      =  0;   // RANGE 0 to 1
parameter clk_ratio        =  1;   // RANGE -7 to -1, 1 to 7
parameter ram_re_ext       =  1;   // RANGE 0 to 1
parameter err_mode         =  0;   // RANGE 0 to 1
parameter tst_mode         =  0;   // RANGE 0 to 2
parameter verif_en         =  1;   // RANGE 0, 1, or 4






localparam lcl_addr_width       =  ((ram_depth>256)?((ram_depth>4096)?((ram_depth>16384)?((ram_depth>32768)?16:15):((ram_depth>8192)?14:13)):((ram_depth>1024)?((ram_depth>2048)?12:11):((ram_depth>512)?10:9))):((ram_depth>16)?((ram_depth>64)?((ram_depth>128)?8:7):((ram_depth>32)?6:5)):((ram_depth>4)?((ram_depth>8)?4:3):((ram_depth>2)?2:1))));
localparam lcl_cnt_width        =  ((ram_depth+1>256)?((ram_depth+1>4096)?((ram_depth+1>16384)?((ram_depth+1>32768)?16:15):((ram_depth+1>8192)?14:13)):((ram_depth+1>1024)?((ram_depth+1>2048)?12:11):((ram_depth+1>512)?10:9))):((ram_depth+1>16)?((ram_depth+1>64)?((ram_depth+1>128)?8:7):((ram_depth+1>32)?6:5)):((ram_depth+1>4)?((ram_depth+1>8)?4:3):((ram_depth+1>2)?2:1))));
localparam lcl_fifo_cnt_width   =  (((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>256)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4096)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16384)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>32768)?16:15):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8192)?14:13)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>1024)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2048)?12:11):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>512)?10:9))):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>16)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>64)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>128)?8:7):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>32)?6:5)):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>4)?(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>8)?4:3):(((((mem_mode==0)||(mem_mode==4)) ? ram_depth+1 : (((mem_mode==3)||(mem_mode==7)) ? ram_depth+3 : ram_depth+2))+1>2)?2:1))));

localparam lcl_ram_width = ((data_s_width>=data_d_width)?data_s_width:data_d_width);
   

input                            clk_s;            // Source Domain Clock
input                            rst_s_n;          // Source Domain Asynchronous Reset (active low)
input                            init_s_n;         // Source Domain Synchronous Reset (active low)
input                            clr_s;            // Source Domain Clear for coordinated reset (active high pulse)
input  [lcl_cnt_width-1:0]       ae_level_s;       // Source Domain RAM almost empty threshold setting
input  [lcl_cnt_width-1:0]       af_level_s;       // Source Domain RAM almost full threshold setting
input                            push_s_n;         // Source Domain push request (active low)
input                            flush_s_n;        // Source Domain flush partial word (active low)
input  [data_s_width-1:0]        data_s;           // Source Domain push data

output                           clr_sync_s;       // Source Domain synchronized clear (active high pulse)
output                           clr_in_prog_s;    // Source Domain orchestrate clearing in progress (unregistered)
output                           clr_cmplt_s;      // Source Domain orchestrated clearing complete (active high pulse)
output                           wr_en_s_n;        // Source Domain write enable to RAM (active low)
output [lcl_addr_width-1:0]      wr_addr_s;        // Source Domain write address to RAM
output [lcl_ram_width-1:0]       wr_data_s;        // Source Domain write data to RAM
output                           inbuf_part_wd_s;  // Source Domain partial word to inbuf (meaningful when data_s_width < data_d_width)
output                           inbuf_full_s;     // Source Domain inbuf Full Flag (meaningful when data_s_width < data_d_width)
output [lcl_fifo_cnt_width-1:0]  fifo_word_cnt_s;  // Source Domain FIFO word count (includes cache)
output [lcl_cnt_width-1:0]       word_cnt_s;       // Source Domain RAM only word count
output                           fifo_empty_s;     // Source Domain FIFO Empty Flag
output                           empty_s;          // Source Domain RAM Empty Flag
output                           almost_empty_s;   // Source Domain RAM Almost Empty Flag
output                           half_full_s;      // Source Domain RAM Half Full Flag
output                           almost_full_s;    // Source Domain RAM Almost Full Flag
output                           ram_full_s;       // Source Domain RAM Full Flag
output                           push_error_s;     // Source Domain Push Error Flag

input                            clk_d;            // Destination Domain Clock
input                            rst_d_n;          // Destination Domain Asynchronous Reset (active low)
input                            init_d_n;         // Destination Domain Synchronous Reset (active low)
input                            clr_d;            // Destination Domain Clear to initiate orchestrated reset (active high pulse)
input  [lcl_fifo_cnt_width-1:0]  ae_level_d;       // Destination Domain FIFO almost empty threshold setting
input  [lcl_fifo_cnt_width-1:0]  af_level_d;       // Destination Domain FIFO almost full threshold setting
input                            pop_d_n;          // Destination Domain pop request (active low)
input  [lcl_ram_width-1:0]       rd_data_d;        // Destination Domain data read from RAM

output                           clr_sync_d;       // Destination Domain synchronized orchestrated clear (active high pulse)
output                           clr_in_prog_d;    // Destination Domain orchestrate clearing in progress (unregistered)
output                           clr_cmplt_d;      // Destination Domain orchestrated clearing complete (active high pulse)
output                           ram_re_d_n;       // Destination Domain Read Enable to RAM (active-low)
output [lcl_addr_width-1:0]      rd_addr_d;        // Destination Domain read address to RAM
output [data_d_width-1:0]        data_d;           // Destination Domain data out
output                           outbuf_part_wd_d; // Destination Domain outbuf partial word popped flag (meaningful when data_s_width > data_d_width)
output [lcl_fifo_cnt_width-1:0]  word_cnt_d;       // Destination Domain FIFO word count (includes cache)
output [lcl_cnt_width-1:0]       ram_word_cnt_d;   // Destination Domain RAM only word count
output                           empty_d;          // Destination Domain Empty Flag
output                           almost_empty_d;   // Destination Domain Almost Empty Flag
output                           half_full_d;      // Destination Domain Half Full Flag
output                           almost_full_d;    // Destination Domain Almost Full Flag
output                           full_d;           // Destination Domain Full Flag
output                           pop_error_d;      // Destination Domain Pop Error Flag

input                            test;             // Test input

wire                             inbuf_part_wd_nc; // Unconnected 
wire  [lcl_ram_width-1:0]        wr_data_inbuf;    // data out from inbuf
wire  [lcl_ram_width-1:0]        data_d_fifoctl;   // data out from fifoctl
wire  [data_d_width-1:0]         data_d_outbuf;    // data out from outbuf
   
wire                             ram_push_n;
wire                             ram_pop_n;
wire                             inbuf_full;
wire                             inbuf_push_error;
wire                             ram_push_wd_n;
   
wire                             error_s_fifoctl;

// Internal muxed signals to fifoctl inputs
wire                             fifoctl_push_s_n;
wire                             fifoctl_pop_d_n;
wire                             error_d_fifoctl;

// Internal muxed signals to fifoctl outputs
wire                             full_s_fifoctl;

// Internal muxed signals from outbuf
wire                             outbuf_pop_error;

// Internal muxed signals to outbuf inputs
wire                             pop_wd_n_outbuf;





generate 
if (data_s_width < data_d_width) begin : GEN_DSW_LT_DDW
wire              inbuf_part_wd;
  DW_asymdata_inbuf #(data_s_width, data_d_width, err_mode, byte_order, flush_value) U_INBUF (
                        .clk_push(clk_s),
                        .rst_push_n(rst_s_n),
                        .init_push_n(init_s_n & ~clr_in_prog_s),
                        .push_req_n(push_s_n),
                        .data_in(data_s),
                        .flush_n(flush_s_n),
                        .fifo_full(full_s_fifoctl),
                        .push_wd_n(ram_push_wd_n),
                        .data_out(wr_data_inbuf),
                        .inbuf_full(inbuf_full),
                        .part_wd(inbuf_part_wd),
                        .push_error(inbuf_push_error) );

  assign fifoctl_push_s_n  = ram_push_wd_n;
  assign wr_data_s         = wr_data_inbuf;

  assign inbuf_part_wd_s   = inbuf_part_wd;
  assign inbuf_full_s      = inbuf_full;
  assign push_error_s      = inbuf_push_error;

  assign fifoctl_pop_d_n   = pop_d_n;
  assign data_d            = data_d_fifoctl;

  assign pop_error_d       = error_d_fifoctl; 
  assign outbuf_part_wd_d  = 1'b0;
end
endgenerate


DW_fifoctl_2c_df #(lcl_ram_width, ram_depth, mem_mode, (f_sync_type + 8), (r_sync_type + 8), clk_ratio, ram_re_ext, err_mode, tst_mode, verif_en, 0, arch_type) U_FIFOCTL (
            .clk_s(clk_s),
            .rst_s_n(rst_s_n),
            .init_s_n(init_s_n),
            .clr_s(clr_s),
            .ae_level_s(ae_level_s),
            .af_level_s(af_level_s),
            .push_s_n(fifoctl_push_s_n),
            .clr_sync_s(clr_sync_s),
            .clr_in_prog_s(clr_in_prog_s),
            .clr_cmplt_s(clr_cmplt_s),
            .wr_en_s_n(wr_en_s_n),
            .wr_addr_s(wr_addr_s),
            .fifo_word_cnt_s(fifo_word_cnt_s),
            .word_cnt_s(word_cnt_s),
            .fifo_empty_s(fifo_empty_s), 
            .empty_s(empty_s),
            .almost_empty_s(almost_empty_s),
            .half_full_s(half_full_s),
            .almost_full_s(almost_full_s),
            .full_s(full_s_fifoctl),
            .error_s(error_s_fifoctl),
            .clk_d(clk_d),
            .rst_d_n(rst_d_n),
            .init_d_n(init_d_n),
            .clr_d(clr_d),
            .ae_level_d(ae_level_d),
            .af_level_d(af_level_d),
            .pop_d_n(fifoctl_pop_d_n),
            .rd_data_d(rd_data_d),
            .clr_sync_d(clr_sync_d),
            .clr_in_prog_d(clr_in_prog_d),
            .clr_cmplt_d(clr_cmplt_d),
            .ram_re_d_n(ram_re_d_n),
            .rd_addr_d(rd_addr_d),
            .data_d(data_d_fifoctl),
            .word_cnt_d(word_cnt_d),
            .ram_word_cnt_d(ram_word_cnt_d),
            .empty_d(empty_d),
            .almost_empty_d(almost_empty_d),
            .half_full_d(half_full_d),
            .almost_full_d(almost_full_d),
            .full_d(full_d),
            .error_d(error_d_fifoctl),
            .test(test)
            );

assign ram_full_s        = full_s_fifoctl;

generate
 if (data_s_width > data_d_width) begin : GEN_DSW_GT_DDW
  assign fifoctl_push_s_n  = push_s_n;
  assign wr_data_s         = data_s;

  assign inbuf_part_wd_s   = 1'b0;
  assign inbuf_full_s      = 1'b1;
  assign push_error_s      = error_s_fifoctl;

// Instance of DW_asymdata_outbuf
wire              outbuf_part_wd;
  DW_asymdata_outbuf #(lcl_ram_width, data_d_width, err_mode, byte_order) U_OUTBUF (
                       .clk_pop(clk_d),
                       .rst_pop_n(rst_d_n),
                       .init_pop_n(init_d_n & ~clr_in_prog_d),
                       .pop_req_n(pop_d_n),
                       .data_in(data_d_fifoctl),
                       .fifo_empty(empty_d),
                       .pop_wd_n(pop_wd_n_outbuf),
                       .data_out(data_d_outbuf),
                       .part_wd(outbuf_part_wd),
                       .pop_error(outbuf_pop_error) );

  assign fifoctl_pop_d_n   = pop_wd_n_outbuf;
  assign data_d            = data_d_outbuf;

  assign pop_error_d       = outbuf_pop_error;
  assign outbuf_part_wd_d  = outbuf_part_wd;
end
endgenerate

generate
 if (data_s_width == data_d_width) begin : GEN_DSW_EQ_DDW
   assign fifoctl_push_s_n  = push_s_n;
   assign wr_data_s         = data_s;

   assign inbuf_part_wd_s   = 1'b0;
   assign inbuf_full_s      = 1'b1;
   assign push_error_s      = error_s_fifoctl;

   assign fifoctl_pop_d_n   = pop_d_n;
   assign data_d            = data_d_fifoctl;

   assign pop_error_d       = error_d_fifoctl;
   assign outbuf_part_wd_d  = 1'b0;
 end
endgenerate
endmodule
