#define NUM_WORDS 192
void interleave(sc_int<8> x_in[NUM_WORDS], 
	sc_int<8> y[NUM_WORDS/3], bool load){
  static sc_int<8> x[NUM_WORDS];
  int idx = 0;

  if(load)
    for(int i=0;i<NUM_WORDS;i+=1)
      x[i] = x_in[i];
   else for(int i=0;i<NUM_WORDS;i+=3)
          y[idx++] = x[i]+x[i+1]+x[i+2];
}

