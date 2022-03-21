clc
x=-10:0.01:10;
y=tpdf(x-1,2); %1是中心，2 是自由度
plot(x,y);grid;
export_fig voice_pdf.png -m2

x=-3:0.2:3;
y=normpdf(x,0,1);
plot(x,y)


x=0:20;
y1=poisspdf(x,2.5);
y2=poisspdf(x,5);
y3=poisspdf(x,10);
hold on
plot(x,y1,':r*')
plot(x,y2,':b*')
plot(x,y3,':g*')
hold off
title('Poisson分布')
