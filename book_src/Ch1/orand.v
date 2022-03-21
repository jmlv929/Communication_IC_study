module orand (
  input a, b, c, d, e,
  output out
);
  assign out = e & (a | b) & (c | d);
  
endmodule
