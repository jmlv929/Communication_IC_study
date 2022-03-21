 1 `define N 6 // 64点FFT的倒序
 2 //  bitrevorder[N-1:0]=inorder[0:N-1]
 3 assign bitrevorder[N-1]=inorder[N-6];
 4 assign bitrevorder[N-2]=inorder[N-5];
 5 assign bitrevorder[N-3]=inorder[N-4];
 6 assign bitrevorder[N-4]=inorder[N-3];
 7 assign bitrevorder[N-5]=inorder[N-2];
 8 assign bitrevorder[N-6]=inorder[N-1];
 9 assign mem_addr=bitrevorder[N-1:0];
