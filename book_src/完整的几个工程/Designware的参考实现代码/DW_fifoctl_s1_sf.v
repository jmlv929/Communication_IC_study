
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Synchronous with Static Flags  
//           static programmable almost empty and almost full flags
//
//           This FIFO controller designed to interface to synchronous
//           true dual port RAMs.
//
//              Parameters:     Valid Values
//              ==========      ============
//              depth           [ 2 to 16777216 ]
//              ae_level        [ 1 to (depth-1) ]
//              af_level        [ 1 to (depth-1) ]
//              err_mode        [ 0 = sticky error flag w/ ptr check,
//                                1 = sticky error flag (no ptr chk),
//                                2 = dynamic error flag ]
//              rst_mode        [ 0 = asynchronous reset,
//                                1 = synchronous reset ]
//              
//              Input Ports:    Size    Description
//              ===========     ====    ===========
//              clk             1 bit   Input Clock
//              rst_n           1 bit   Active Low Async. Reset
//              push_req_n      1 bit   Active Low Push Request
//              pop_req_n       1 bit   Active Low Pop Request
//              diag_n          1 bit   Active Low diagnostic control
//
//              Output Ports    Size    Description
//              ============    ====    ===========
//              we_n            1 bit   Active low Write Enable (to RAM)
//              empty           1 bit   Empty Flag
//              almost_empty    1 bit   Almost Empty Flag
//              half_full       1 bit   Half Full Flag
//              almost_full     1 bit   Almost Full Flag
//              full            1 bit   Full Flag
//              error           1 bit   Error Flag
//              wr_addr         N bits  Write Address (to RAM)
//              rd_addr         N bits  Read Address (to RAM)
//
//                Note: the value of N for wr_addr and rd_addr is
//                      the value of the parameter 'addr_width'
//                      which should be set to the value :
//                              ceil( log2( depth ) )
//              
//
//
// MODIFIED: 
//
////////////////////////////////////////////////////////////////////////////////

module DW_fifoctl_s1_sf (
    clk,
    rst_n,
    push_req_n,
    pop_req_n,
    diag_n,
    we_n,
    empty,
    almost_empty,
    half_full,
    almost_full,
    full,
    error,
    wr_addr,
    rd_addr
    // Embedded dc_shell script
    //   set_implementation "rtl" "U1"
    // _model_constraint_1
    );

parameter depth  = 4;		// RANGE 2 to 16777216
parameter ae_level = 1;         // RANGE 1 to 16777215
parameter af_level = 1;         // RANGE 1 to 16777215
parameter err_mode  =  0 ;	// RANGE 0 to 2
parameter rst_mode  =  0 ;      // RANGE 0 to 1
`define DW_addr_width ((depth>65536)?((depth>1048576)?((depth>4194304)?((depth>8388608)?24:23):((depth>2097152)?22:21)):((depth>262144)?((depth>524288)?20:19):((depth>131072)?18:17))):((depth>256)?((depth>4096)?((depth>16384)?((depth>32768)?16:15):((depth>8192)?14:13)):((depth>1024)?((depth>2048)?12:11):((depth>512)?10:9))):((depth>16)?((depth>64)?((depth>128)?8:7):((depth>32)?6:5)):((depth>4)?((depth>8)?4:3):((depth>2)?2:1)))))

input			clk;		// Input Clock (pos edge)
input			rst_n;		// Async reset (active low)
input			push_req_n;	// Push request (active low)
input			pop_req_n;	// Pop Request (active low)
input			diag_n;		// Diagnostic sync. reset rd_addr (active low)
output			we_n;		// RAM Write Enable output (active low)
output			empty;		// FIFO Empty flag output (active high)
output			almost_empty;	// FIFO Almost Empty flag output (active high)
output			half_full;	// FIFO Half Full flag output (active high)
output			almost_full;	// FIFO almost Full flag output (active high)
output			full;		// FIFO full flag output (active high)
output			error;		// FIFO Error flag output (active high)
output [`DW_addr_width-1:0]	wr_addr;	// RAM Write Address output bus
output [`DW_addr_width-1:0]	rd_addr;	// RAM Read Address output bus

wire a_rst_n, s_rst_n;
wire [`DW_addr_width-1:0] wrd_count_nc;
wire nxt_empty_n_nc, nxt_full_nc, nxt_error_nc;

wire [`DW_addr_width-1:0] ae_level_int;
wire [`DW_addr_width-1:0] af_thresh_int;

    assign a_rst_n = (rst_mode == 0)? rst_n : 1'b1;
    assign s_rst_n = (rst_mode == 0)? 1'b1 : rst_n;

    assign ae_level_int  = ae_level[`DW_addr_width-1:0];
    assign af_thresh_int = depth[`DW_addr_width-1:0] - af_level[`DW_addr_width-1:0];

    DWsc_fifoctl_s1_df #(depth, err_mode, `DW_addr_width, 1) U1(
        .clk(clk),
        .rst_n(a_rst_n),
        .init_n(s_rst_n),
        .push_req_n(push_req_n),
        .pop_req_n(pop_req_n),
        .diag_n(diag_n),
        .ae_level(ae_level_int),
        .af_thresh(af_thresh_int),
        .we_n(we_n),
        .empty(empty),
        .almost_empty(almost_empty),
        .half_full(half_full),
        .almost_full(almost_full),
        .full(full),
        .error(error),
        .wr_addr(wr_addr),
        .rd_addr(rd_addr),
        .wrd_count(wrd_count_nc),
        .nxt_empty_n(nxt_empty_n_nc),
        .nxt_full(nxt_full_nc),
        .nxt_error(nxt_error_nc)
        );

`undef DW_addr_width
endmodule
