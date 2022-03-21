function [gf_out]=get_gf_data(index,m)
if nargin<2
    m=8;
end

% global norml_gf_table inv_gf_table
% norml_gf_table=zeros(1,2^m);
% inv_gf_table=zeros(1,2^m);
% i=2^m-1; %not need since default is zero
%  norml_gf_table(i+1)=0;
%  inv_gf_table(i+1)=-inf;
% for i=0:2^m-2
%     bb=gftuple(i,m);
%     order=bi2de(bb);
%     norml_gf_table(i+1)=order;
%     inv_gf_table(order)=i;
% end

global norml_gf_table inv_gf_table

if index == -inf
      gf_out=0;
  else
      index1=mod(index,2^m-1);
      gf_out=norml_gf_table(index1+1);
  end
end
