1 j=1; 
2 for i=1:n 
3   sum_result=RS_polyN_calc(sigma_x, alpha_to(i)); 
4   if sum_result== 0 
5     root(j)= alpha_to(i); % 
6     j=j+1; 
7   end 
8 end 

