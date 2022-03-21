function [index_out]=get_gf_index(data_in,m)
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
  if data_in == 0
      index_out=-inf;
  elseif abs(data_in)<=2^m-1
      index_out=inv_gf_table(data_in);
  else
      index_out=-inf;
      disp('error with input data!');
  end
end