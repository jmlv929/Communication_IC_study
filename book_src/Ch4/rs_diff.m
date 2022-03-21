1 diff_sigma=zeros(1,length(sigma_x));
2 for  poly_coef=1:length(sigma_x)
3     if  mod(poly_coef,2)==0
4         diff_sigma(poly_coef-1)=sigma_x(poly_coef);
5     end
6 end
7 diff_sigma(length(sigma_x))=0; %
8 