function  y=preamble(flag)
  if flag==1;
    y=ones(1,144);
    y(1,129:144)=[1 1 1 1 0 0 1 1 1 0 1 0 0 0 0 0];
  else
    y=zeros(1,72);
    y(1,57:72)=[0 0 0 0 0 1 0 1 1 1 0 0 1 1 1 1 ];
  end
end
