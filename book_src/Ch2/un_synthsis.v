always @(posedge clk or negege rst) // 必须紧跟always否则不可综合
begin
  if(!rst)
    dout<=0;
   else
    dout<=din;
   @(posedge clk) // 多余的@，不可综合
     dout<=din2;
end

integer［<msb>:<lsb>］<identifier>

always @(a or b or c1 or c2)
begin
  if(c1)
    out1=a;
  else
    out2=b;
  
  if(c2) //
    out2=b;
end

always @(a or b or c1 or c2)
begin
  if(c1)
    out1=a;
  else
    out1=b;
  
  if(c2) //
    c1=out1 & a;
end

