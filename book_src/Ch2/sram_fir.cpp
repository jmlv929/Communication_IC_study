01  #define NUM_WORDS 192
02  void interleave(sc_int<8> x_in[NUM_WORDS],
03                  sc_int<8> y[NUM_WORDS/3], bool load) {
04      static sc_int<8> x[NUM_WORDS];
05      int idx = 0;
06      if(load)
07        for (int i=0; i<NUM_WORDS; i+=1)
08          x[i] = x_in[i];
09      else for (int i=0; i<NUM_WORDS/3; i+=3)
10          y[i] = x[3*i]+x[3*i+1]+x[3*i+2];
11  }
12