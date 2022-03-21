%% plot eye diagram for GSMK
%usage: eye_fig(a,osr)
function eye_fig(a,osr)
%% usage: eye_fig(a,osr)
 if nargin==2,len=800;end
 if nargin==1,len=800;osr=8;end
    b=squeeze(a);
    start=100;
    len=floor(numel(a)/osr/2)*2;
    x=size(a);
    c=b(:,1:(len*osr)/x(1));
    f=reshape(c,2*osr,len/2);
    %% run for diagram
    plot(1:2*osr,f(:,start:len/2));grid;
    test_f=abs(f(:,start:len/2));
    figure;
    plot(1:2*osr,test_f);grid;
    f_sn=sum(test_f,2);
    figure;
    plot(f_sn);grid;
end

