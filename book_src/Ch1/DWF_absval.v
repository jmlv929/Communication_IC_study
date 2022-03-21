function[width-1 : 0] DWF_absval;
  input  [width-1 : 0] A;
begin

  DWF_absval = ((^(A ^ A) !== 1'b0)) ? {width{1'bx}} : 
		(A[width-1] == 1'b0) ? A : (-A);
end
endfunction
