module  RS_EncCor  #(
parameter  n  =  15,   // Encoded message length
parameter  k  =  9 ,   // Unencoded message length
parameter  m  =  4     // I/O wordlength
)(
input               clk,   // Global clock (posedge)
input               syn_rst,// Global reset (active high)
input [0:m-1]       data,  // Data input sequence (n-r symbols)
input               ienb,  // Input enable (for accepting new input)
input               oenb,  // Output enable (for processing data)
input               enb,   // Global enable
input [0:(n-k)*m-1] gp,    // Generator polynomial (gp[0]...gp[n-k-1])
input [0:m-1]       pp,    // Primitive polynomial for GF(2^m)
output[0:m-1]       rsout  // Data output sequence (N symbols)
);
wire  [0:m-1]  rii ;
wire           riei , riri ;
wire  [0:m-1]  gpi  [0:n-k-1] ;
wire  [0:m-1]  mi ;
wire  [0:m-1]  mo  [0:n-k-1] ;
wire  [0:m-1]  ao  [0:n-k-1] ;
wire  [0:m-1]  ri  [0:n-k-1] ;

reg   [0:m-1]  inpd ;
reg            rieo , irst ;
reg   [0:m-1]  ro  [0:n-k-1] ;

// Input data registering logic
assign  rii  =  ienb  ?  data  :  inpd ;
// Internal reset logic
assign  riei  =  ienb ;
assign  riri  =  ienb  &  ~rieo ;

// Form mi from encoder output and data input
assign mi=oenb ? 0: (inpd^(irst?0:ro[n-k-1]));
// Encode logic
genvar  i ;
generate
  assign  gpi[0]  =  gp[0:m-1] ;
  RS_GfMul  #( .m(m) )  me0(.a(gpi[0]),.b(mi),.p(pp),.y(mo[0]));
  assign  ao[0]  =  mo[0] ;
  assign  ri[0]  =  ao[0] ;
  for ( i  =  1 ;  i  <=  (n-k-1) ;  i  =  i + 1 )
    begin  :  enc
      assign  gpi[i]  =  gp[ i*m : (i+1)*m-1 ] ;
      RS_GfMul#(.m(m)) mei(.a(gpi[i]),.b(mi),.p(pp),.y(mo[i]));
      assign  ao[i]  =  mo[i]  ^  ( irst ? 0 : ro[i-1] ) ;
      assign  ri[i]  =  ao[i] ;
    end
  //
endgenerate

// Define RS encoder output
assign  rsout  =  oenb  ?  ro[n-k-1]  :  inpd ;
//////////////////////////////////////////////////
// Update internal registers
always @ (posedge clk)
  if ( syn_rst == 1'b1 ) 
    inpd  <= #1  0 ;
    rieo  <= #1  0 ;
    irst  <= #1  0 ;
  end
  else if  ( enb ) begin
    inpd  <= #1  rii ;
    rieo  <= #1  riei ;
    irst  <= #1  riri ;
  end

genvar  j ;
generate
  for ( j  =  0 ;  j  <=  (n-k-1) ;  j  =  j + 1 )
    begin  :  regfor
      always @ (posedge clk)
        if ( syn_rst == 1'b1 ) ro[j] <= #1  0 ;
        else if  ( enb )  ro[j] <= #1  ri[j] ;
    end  // regfor
endgenerate

endmodule
