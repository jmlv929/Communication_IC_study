num=[1];%����
%den=[0.745 -1.7 1];%��ĸ
den=[1 -1.8 0.885];%��ĸ
Ts=-1;% ����ʱ��-1��ʾ��ȷ������ʱ��
G=tf(num,den,Ts);
G_z=zpk(G);
[z,p,k]=tf2zp(num,den);
pole_root=roots(den) ;