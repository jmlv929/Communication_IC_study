always @ (graycode) begin
  for(i=0;i<=n-1;i=i+1)
  	binarycode[i]=^(graycode>>i); //�Ƚ��˷ѿռ�
end

always @ (graycode) begin
  binarycode[n-1]=graycode[n-1];
  for(i=1;i<=n-1;i=i+1)
	  binarycode[i-1]=graycode[i-1] ^ binarycode[i]; //�ȽϽ�ʡ�ռ�
end

binarycode=graycode^(graycode>>1);

