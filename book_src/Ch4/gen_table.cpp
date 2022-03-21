void gen_table()
{
  int MM = 8;
  int gf_2M = 255;
  int alphaToMM = 45;//¦Á^8=¦Á^5+¦Á^3+¦Á^2+1
  int *alphaTo = new int[gf_2M + 1];
  int *expOf = new int[gf_2M + 1];

  alphaTo[MM] = alphaToMM;
  expOf[alphaToMM] = MM;
  alphaTo[gf_2M] = 0;
  expOf[0] = gf_2M;

  int i, shift;
  shift = 1;
  for(i = 0; i < MM; i++) {
    alphaTo[i] = shift;//2^i
    expOf[alphaTo[i]] = i;
    shift <<= 1;
  }
  shift = 128;
  for(i = MM + 1; i < gf_2M-1; i++) {
    if(alphaTo[i - 1] >= shift) {
      alphaTo[i] = alphaTo[MM] ^ ((alphaTo[i - 1] ^ shift) << 1); //alphaTo[i-1]*alpha+alpha^8
    } else {
      alphaTo[i] = alphaTo[i - 1] << 1;
    }
    expOf[alphaTo[i]] = i;
  }
}
