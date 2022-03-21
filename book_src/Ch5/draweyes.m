clc
close all
osr=16;
a=dfai.Data;
b=squeeze(a);
dc_offset=0.10;
max=0.5;
c=reshape(b,1,[]);
c=c+dc_offset;
for i=1:length(c)
    if(c(i)>max)c(i)=c(i)-max;
    end
end
eye_fig(c,osr);
figure;
c_new=dc_remove(c);
%eye_fig(a,osr);
eye_fig(c_new,osr);






