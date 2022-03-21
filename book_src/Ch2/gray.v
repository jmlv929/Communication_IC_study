always @ (graycode) begin
  for(i=0;i<=n-1;i=i+1)
  	binarycode[i]=^(graycode>>i); //比较浪费空间
end

always @ (graycode) begin
  binarycode[n-1]=graycode[n-1];
  for(i=1;i<=n-1;i=i+1)
	  binarycode[i-1]=graycode[i-1] ^ binarycode[i]; //比较节省空间
end

binarycode=graycode^(graycode>>1);

