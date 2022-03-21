num=[1];%分子
%den=[0.745 -1.7 1];%分母
den=[1 -1.8 0.885];%分母
Ts=-1;% 采样时间-1表示不确定采样时间
G=tf(num,den,Ts);
G_z=zpk(G);
[z,p,k]=tf2zp(num,den);
pole_root=roots(den) ;