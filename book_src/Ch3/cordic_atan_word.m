03 x=10;
04 y=20;
05 x_n=zeros(12,1);
06 y_n=zeros(12,1);
07 %% 原始数据
08 fprintf('orignal is \t %f,%f\n',x,y);
09 %% 第一步数据
10 i=1;
11 [x_n(i),y_n(i)]=cordic_atan(x,y,pi/(bitshift(2,i)));
12 fprintf('shift %d result is \t %f,%f\n',i,x_n(i),y_n(i));
13 %% 进入迭代循环
14 N=4;
15 for i=2:N
16   if(y_n(i-1)>0) % 旋转旋转方向
17     [x_n(i),y_n(i)]=cordic_atan(x_n(i-1),y_n(i-1),pi/(bitshift(2,i)));
18   else
19     [x_n(i),y_n(i)]=cordic_atan(x_n(i-1),y_n(i-1),-pi/(bitshift(2,i)));
20   end
21   fprintf('shift %d result is \t %f,%f\n',i,x_n(i),y_n(i));
22 end
