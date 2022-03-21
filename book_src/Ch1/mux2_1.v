module MUX2_1(
input a,b,sel,  //声明a,b,sel为输入端口
output out      //声明out为输出端口
);
  wire a1, b1, sel_n;  //定义内部节点信号（连线）
  not u1 (sel_n,sel ); //调用内置“非”门元件 
  and u2 (a1,a,sel_n); //调用内置“与”门元件 
  and u3 (b1,b,sel  ); //调用内置“与”门元件 
  or u4  (out,a1,b1 ); //调用内置“或”门元件 
endmodule
