
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT:  Synchronous Two-Clock RAM (one clock for the write port and
//            one clock for the read port)
//
//            Parameters:     Valid Values
//            ==========      ============
//             width          [ 1 to 1024 ]
//             depth          [ 2 to 1024 ]
//             addr_width     ceil(log2(depth)) [ 1 to 10 ]
//             mem_mode       [ 0 to 7 ]
//             rst_mode       [ 0 => resets clear RAM array
//				1 => reset do not clear RAM ]
//
//            Write Port Interface
//            ====================
//            Ports           Size      Description
//            =====           ====      ===========
//            clk_w            1        Write Port clock
//            rst_w_n          1        Active Low Asynchronous Reset (write clock domain)
//            init_w_n         1        Active Low Synchronous  Reset (write clock domain)
//            en_w_n           1        Active Low Write Enable input
//            addr_w       addr_width   write address input
//            data_w         width      write data input
//
//            Read Port Interface
//            ====================
//            Ports           Size      Description
//            =====           ====      ===========
//            clk_r            1        Read Port clock
//            rst_r_n          1        Active Low Asynchronous Reset (read clock domain)
//            init_r_n         1        Active Low Synchronous  Reset (read clock domain)
//            en_r_n           1        Active Low Read Enable input
//            addr_r       addr_width   read address input
//            data_r_a         1        read data arrival output
//            data_r         width      read data output
//
// MODIFICATIONS:
//
//        DLL   06-29-11  Added a couple of pragmas to disable Leda warnings.
//
////////////////////////////////////////////////////////////////////////////////

module DW_ram_r_w_2c_dff (
	clk_w,		// Write clock input
	rst_w_n,	// write domain active low asynch. reset
	init_w_n,	// write domain active low synch. reset
	en_w_n,		// acive low write enable
	addr_w,		// Write address input
	data_w,		// Write data input

	clk_r,		// Read clock input
	rst_r_n,	// read domain active low asynch. reset
	init_r_n,	// read domain active low synch. reset
	en_r_n,		// acive low read enable
	addr_r,		// Read address input
	data_r_a,	// Read data arrival status output
	data_r		// Read data output
    // Embedded dc_shell script
    // _model_constraint_1
);

parameter width = 8;	// RANGE 1 to 1024
parameter depth = 4;	// RANGE 2 to 1024
parameter addr_width = 2; // RANGE 1 to 10
parameter mem_mode = 1; // RANGE 0 to 7
parameter rst_mode = 0;	// RANGE 0 to 1

 input				clk_w;
 input				rst_w_n;
 input				init_w_n;
 input				en_w_n;
 input [addr_width-1 : 0]	addr_w;
 input [width-1 : 0]		data_w;

 input				clk_r;
 input				rst_r_n;
 input				init_r_n;
 input				en_r_n;
 input [addr_width-1 : 0]	addr_r;
output				data_r_a;
output [width-1 : 0]		data_r;



 reg [(depth*width)-1 : 0]	the_memory;
 reg [(depth*width)-1 : 0]	next_memory;

wire [addr_width-1 : 0]	addr_w_mem;
 reg [addr_width-1 : 0]	addr_w_q;
wire 			en_w_mem;
 reg 			en_w_q;
wire [width-1 : 0]	data_w_mem;
 reg [width-1 : 0]	data_w_q;
wire [addr_width-1 : 0]	addr_r_mem;
 reg [addr_width-1 : 0]	addr_r_q;
wire 			en_r_mem;
 reg 			en_r_q;
 reg 			en_r_qq;
wire [width-1 : 0]	rd_data_mem;
 reg [width-1 : 0]	rd_data_q;

  
generate
  if (rst_mode == 0) begin : GEN_RM0W
    always @ (posedge clk_w or negedge rst_w_n) begin : PROC_clk_w_regs
      integer i;
      if (rst_w_n == 1'b0) begin
	the_memory <= {(depth*width){1'b0}};
	addr_w_q <= {addr_width{1'b0}};
	data_w_q <= {width{1'b0}};
	en_w_q   <= 1'b0;
      end else if (init_w_n == 1'b0) begin
	the_memory <= {(depth*width){1'b0}};
	addr_w_q <= {addr_width{1'b0}};
	data_w_q <= {width{1'b0}};
	en_w_q   <= 1'b0;
      end else begin
	if (en_w_mem == 1)
	  the_memory <= next_memory;
	if (en_w_n == 1'b0) begin
	  addr_w_q <= addr_w;
	  data_w_q <= data_w;
	end
	en_w_q   <= ~en_w_n;
      end
    end
  end else begin : GEN_RM1W
    always @ (posedge clk_w or negedge rst_w_n) begin : PROC_clk_w_regs
      integer i;
      if (rst_w_n == 1'b0) begin
	addr_w_q <= {addr_width{1'b0}};
	data_w_q <= {width{1'b0}};
	en_w_q   <= 1'b0;
      end else if (init_w_n == 1'b0) begin
	addr_w_q <= {addr_width{1'b0}};
	data_w_q <= {width{1'b0}};
	en_w_q   <= 1'b0;
      end else begin
	if (en_w_mem == 1)

	  the_memory <= next_memory;

	if (en_w_n == 1'b0) begin
	  addr_w_q <= addr_w;
	  data_w_q <= data_w;
	end
	en_w_q   <= ~en_w_n;
      end
    end
  end
endgenerate


  always @ (the_memory or addr_w_mem or data_w_mem) begin : mk_next_mem
    integer i, j, k;
    next_memory = the_memory;

    k = 0;
    for (i=0 ; i < depth ; i=i+1) begin
      if (i == addr_w_mem) begin
        for (j=0 ; j < width ; j=j+1)
	  next_memory[k+j] = data_w_mem[j];
      end

      k = k + width;
    end
  end


generate
  if ((mem_mode & 4) == 4) begin : GEN_MMBT2_1
    assign addr_w_mem = addr_w_q;
    assign en_w_mem =   en_w_q;
    assign data_w_mem = data_w_q;
  end else begin : GEN_MMBT2_0
    assign addr_w_mem = addr_w;
    assign en_w_mem =   ~en_w_n;
    assign data_w_mem = data_w;
  end
endgenerate



  always @ (posedge clk_r or negedge rst_r_n) begin : PROC_clk_r_regs
    integer i;
    if (rst_r_n == 1'b0) begin
      addr_r_q <= {addr_width{1'b0}};
      rd_data_q <= {width{1'b0}};
      en_r_q   <= 1'b0;
      en_r_qq  <= 1'b0;
    end else if (init_r_n == 1'b0) begin
      addr_r_q <= {addr_width{1'b0}};
      rd_data_q <= {width{1'b0}};
      en_r_q   <= 1'b0;
      en_r_qq  <= 1'b0;
    end else begin
      if (en_r_n == 1'b0)
	addr_r_q <= addr_r;
      if (en_r_mem == 1'b1)
	rd_data_q <= rd_data_mem;
      en_r_q  <= ~en_r_n;
      en_r_qq <= en_r_q;
    end
  end


   
  function [width-1:0] func_read_mux ;
    input [width*depth-1:0]	a;	// input bus
    input [addr_width-1:0]  	sel;	// select
    reg   [width-1:0]	z;
    integer			i, j, k;
    begin
      z = {width {1'b0}};
      j = 0;
      k = 0;   // Temporary fix for a Leda issue
      for (i=0 ; i<depth ; i=i+1) begin
	if (i == sel) begin
	  for (k=0 ; k<width ; k=k+1) begin
	    z[k] = a[j + k];
	  end // for (k
	end // if
	j = j + width;
      end // for (i
      func_read_mux  = z;
    end
  endfunction

  assign rd_data_mem = func_read_mux ( the_memory, addr_r_mem );



generate
  if ((mem_mode & 2) == 2) begin : GEN_MMBT1_1
    assign addr_r_mem = addr_r_q;
    assign en_r_mem   = en_r_q;
  end else begin : GEN_MMBT1_0
    assign addr_r_mem = addr_r;
    assign en_r_mem   = ~en_r_n;
  end
endgenerate

generate
  if ((mem_mode & 1) == 1) begin : GEN_MMBT0_1
    assign data_r      = rd_data_q;
  end else begin : GEN_MMBT0_0
    assign data_r      = rd_data_mem;
  end
endgenerate

generate
  if ((mem_mode & 3) == 0) begin : GEN_MMBT10_0
    assign data_r_a    = ~en_r_n;
  end

  if ((mem_mode & 3) == 1) begin : GEN_MMCT10_1
    assign data_r_a    = en_r_q;
  end

  if ((mem_mode & 3) == 2) begin : GEN_MMCT10_2
    assign data_r_a    = en_r_q;
  end

  if ((mem_mode & 3) == 3) begin : GEN_MMCT10_3
    assign data_r_a    = en_r_qq;
  end
endgenerate

endmodule
