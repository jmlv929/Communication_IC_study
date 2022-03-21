function [DecOutput] = gf2dec(GFInput,m,prim_poly)
GFInput = GFInput(:)';% force a row vector
if nargin < 3
    if nargin<2
        m=8;
    end
    prim_poly=primpoly(m);
end
GFRefArray = gf([0:(2^m)-1],m,prim_poly);
len=length(GFInput);
DecOutput=zeros(len,1);
for i=1:len
    for k=0:(2^m)-1
        temp = isequal(GFInput(i),GFRefArray(k+1));
        if (temp==1)
            DecOutput(i) = k;
        end
    end
end

