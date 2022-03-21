//计算有符号数的绝对值

module  DWF_absval#(
    parameter N = 8 
) (
    input[N-1:0] opa,
    output[N-1:0] opb
);


function [N-1:0] cal;
input [N-1:0] A;
begin
cal = (^(A ^ A) !== 1'b0) ? ({N{1'bx}}) : ((A[N-1] == 1'b1 ) ? (~A + 1'b1) : A);

end
endfunction
    
assign opb = cal(opa);

endmodule