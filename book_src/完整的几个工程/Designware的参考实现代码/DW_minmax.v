
//
// ABSTRACT:  Determines the minimum or maximum value of multiple inputs
//   
// MODIFIED: James Feagans May 18, 2004
//           Took Rick's minmax_1.vpp and resized value and index arrays
//
//           Rick Kelly : May 23, 2011
//           Leda updates : use integer loop variables and test integer
//           variables to set bits (instead of copying 'bits' from the
//           integers)
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: DWbb_minmax selects the minimum (or maximum as directed
//           by the 'min_max' input) value from a packed array of input
//           values given on the input port, 'a'.  It also reports the
//           index of the value selected (i.e. which element of the
//           input value array) on the output, 'index'.  The 'tc' input
//           is used to indicate whether the input values in the array,
//           'a', are unsigned (tc = 0) or signed (tc = 1).
//
//              Parameters:                          Valid Values
//              ==========                           ============
//              width                                [ >= 1 ]
//              num_inputs                           [ >= 2 ]
//		index_width	                     ceil(log2(num_inputs))
//              
//              Input Ports:  Size                   Description
//              ===========   ====                   ===========
//              a             num_inputs*width bits  Packed array of input values
//              tc            1 bit                  Signed/unsigned countrol
//              min_max       1 bit                  Min versus max control
//						     [ 0 => find min
//						       1 => find max ]
//
//              Output Ports  Size                   Description
//              ============  ====                   ===========
//		value         width bits             Selected min/max value
//		index         index_width bits       Index (in input array) of
//						       value selected
//
////////////////////////////////////////////////////////////////////////////////

  module DW_minmax (
      // Inputs
	a,
	tc,
	min_max,
      // Outputs
	value,
	index
);

parameter width = 		4;	// element width
parameter num_inputs = 		8;	// number of elements in input array

localparam index_width = 	((num_inputs>65536)?((num_inputs>1048576)?((num_inputs>4194304)?((num_inputs>8388608)?24:23):((num_inputs>2097152)?22:21)):((num_inputs>262144)?((num_inputs>524288)?20:19):((num_inputs>131072)?18:17))):((num_inputs>256)?((num_inputs>4096)?((num_inputs>16384)?((num_inputs>32768)?16:15):((num_inputs>8192)?14:13)):((num_inputs>1024)?((num_inputs>2048)?12:11):((num_inputs>512)?10:9))):((num_inputs>16)?((num_inputs>64)?((num_inputs>128)?8:7):((num_inputs>32)?6:5)):((num_inputs>4)?((num_inputs>8)?4:3):((num_inputs>2)?2:1)))));
localparam [index_width : 0] num_inputs_log2 = 1 << (((num_inputs>65536)?((num_inputs>1048576)?((num_inputs>4194304)?((num_inputs>8388608)?24:23):((num_inputs>2097152)?22:21)):((num_inputs>262144)?((num_inputs>524288)?20:19):((num_inputs>131072)?18:17))):((num_inputs>256)?((num_inputs>4096)?((num_inputs>16384)?((num_inputs>32768)?16:15):((num_inputs>8192)?14:13)):((num_inputs>1024)?((num_inputs>2048)?12:11):((num_inputs>512)?10:9))):((num_inputs>16)?((num_inputs>64)?((num_inputs>128)?8:7):((num_inputs>32)?6:5)):((num_inputs>4)?((num_inputs>8)?4:3):((num_inputs>2)?2:1))))));

input  [num_inputs*width-1 : 0]		a;	// Concatenated input vector
input					tc;	// 0 = unsigned, 1 = signed
input					min_max;// 0 = find min, 1 = find max
output [width-1:0]			value;	// mon or max value found
output [index_width-1:0]		index;	// index to value found



wire   [num_inputs*width-1 : 0]		a_uns, a_trans;
reg    [width-1:0]			val_int;
wire   [width-1:0]			val_trans;
reg    [index_width-1:0]		indx_int;


generate
  if (width == 1) begin : GEN_W_EQ1
    assign a_uns = a ^ {num_inputs{tc}};
    assign value = val_trans ^ tc;
  end else begin : GEN_W_GT1
    assign a_uns = a ^ { num_inputs { tc, { width-1 {1'b0}}}};
    assign value = val_trans ^ { tc, { width-1 {1'b0}}};
  end
endgenerate

  assign a_trans = a_uns;

  always @ (a_trans or min_max) begin : PROC_find_minmax
      reg    [width-1:0]	val_1, val_2;
      reg    [index_width-1 : 0]	indx_1, indx_2;
      reg    [( (2 << index_width)-1)*width-1 : 0]	 val_array;
      reg    [( (2 << index_width)-1)*index_width-1:0] indx_array;
      integer		i, j, k, l, m, n;

    i = 0;
    j = 0;
    val_array = {width << (index_width+1){1'b0}};
    indx_array = {index_width << (index_width+1){1'b0}};
    for (n=0 ; n<num_inputs ; n=n+1) begin
      for (m=0 ; m<width ; m=m+1) 
        val_array[i+m] = a_trans[i+m];

      for (m=0;m<index_width;m=m+1) indx_array[ m + j ] = (((n>>m)&1)!=0)?1'b1:1'b0;

      i = i + width;
      j = j + index_width;
    end

    for (n=num_inputs ; n<(1 << index_width) ; n=n+1) begin
      for (m=0 ; m<width ; m=m+1) 
        val_array[i+m] = val_array[(num_inputs-1)*width+m];

      for (m=0 ; m < index_width ; m=m+1)
        indx_array[j+m] = indx_array[(num_inputs-1)*index_width+m];

      i = i + width;
      j = j + index_width;      
    end

    k = 0;
    l = 0;
    for (n=0 ; n < (1 << (index_width-1))*2-1 ; n=n+1) begin
      
      for (m=0 ; m<width ; m=m+1) begin
	  val_1[m] = val_array[k+m];
      end
      
      for (m=0 ; m<index_width ; m=m+1) begin
	  indx_1[m] = indx_array[l+m];
      end

      k = k + width;
      l = l + index_width;
      
      for (m=0 ; m<width ; m=m+1) begin
	  val_2[m] = val_array[k+m];
      end 

      for (m=0 ; m<index_width ; m=m+1) begin
	  indx_2[m] = indx_array[l+m];
      end

      k = k + width;
      l = l + index_width;

      if (((min_max==1'b1) && (val_1 > val_2)) || ((min_max==1'b0) && (val_1 <= val_2))) begin
        for (m=0 ; m<width ; m=m+1)
	  val_array[i+m] = val_1[m];
	
	for (m=0 ; m<index_width ; m=m+1)
	  indx_array[j+m] = indx_1[m];

      end else begin
        for (m=0 ; m<width ; m=m+1)
	  val_array[i+m] = val_2[m];
	
	for (m=0 ; m<index_width ; m=m+1)
	  indx_array[j+m] = indx_2[m];

      end

      i = i + width;
      j = j + index_width;
    end


    for (m=0 ; m < width ; m=m+1)
      val_int[m] = val_array[k+m];
    
    for (m=0 ; m < index_width ; m=m+1)
      indx_int[m] = indx_array[l+m];
    
  end

  assign val_trans = val_int;
  assign index = indx_int;



endmodule
