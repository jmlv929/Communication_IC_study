function [3:0] sub_11_remain(input [4:0]data,output X)
   X = data > 5'd11;
   sub_11_remain = X ? data - 5'd11 : data;
endfunction
