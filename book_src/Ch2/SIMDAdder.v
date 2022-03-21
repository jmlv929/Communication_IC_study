36 module SIMDAdder (/*AUTOARG*/
37   // Outputs
38   AUOut, COut, GE, Sat, Ext,
39   // Inputs
40   ADataEx, BDataEx, CIn, SignedSIMD, AuInvT, AuInvB, SignedSat
41   );
47   // Control Inputs
48   input         SignedSIMD;
49   input         AuInvT;
50   input         AuInvB;
51   input         SignedSat;
53   // Data Inputs
54   input  [31:0] ADataEx;
55   input  [31:0] BDataEx;
56   input  [6:0]  CIn;
58   // Data Outputs
59   output [31:0] AUOut;
60   output        COut;
61   output [3:0]  GE;
62   output [3:0]  Sat;
63   output [3:0]  Ext;
68
69   wire   [34:0] iAUOut;
70   wire   [3:0]  iExt;
71
72   wire [3:0]    CryOut;
74   wire [3:0]    EarlySat;
75   wire [3:0]    EarlyGE;
77   wire [34:0]   InAEx;
78   wire [34:0]   InBEx;
87   // -----------------------------------
88   // Create the 35-bit A and B buses
89   // -----------------------------------
91   assign InAEx[34:0] = {ADataEx[31:24],CIn[5],ADataEx[23:16],CIn[3],
92                          ADataEx[15: 8],CIn[1],ADataEx[ 7: 0]};
93
94   assign InBEx[34:0] = {BDataEx[31:24],CIn[6],BDataEx[23:16],CIn[4],
95                          BDataEx[15: 8],CIn[2],BDataEx[ 7: 0]};
97   // -----------------------------------
98   // 35 bit add
99   // -----------------------------------
101   A1176CoreAdd35 uAdd35(
102      // Inputs
103      .A     (InAEx[34:0]),
104      .B     (InBEx[34:0]),
105      .CI    (CIn[0]),
106      // Outputs
107      .CO    (CryOut[3]),
108      .SumOut(iAUOut[34:0]));
110   // -----------------------------------
111   // Create carry signals
112   // -----------------------------------
114   assign CryOut[0] = iAUOut[8] ^ (InAEx[8] ^ InBEx[8]);
115   assign CryOut[1] = iAUOut[17] ^ (InAEx[17] ^ InBEx[17]);
116   assign CryOut[2] = iAUOut[26] ^ (InAEx[26] ^ InBEx[26]);
117
118   assign COut = CryOut[3];
120   // -----------------------------------
121   // Flag calculations
122   // -----------------------------------
123
124   assign EarlyGE[0]  = (SignedSIMD & ~(ADataEx[7]  ^ BDataEx[7]));
125   assign EarlyGE[1]  = (SignedSIMD & ~(ADataEx[15] ^ BDataEx[15]));
126   assign EarlyGE[2]  = (SignedSIMD & ~(ADataEx[23] ^ BDataEx[23]));
127   assign EarlyGE[3]  = (SignedSIMD & ~(ADataEx[31] ^ BDataEx[31]));
128
129   // Final GE bit calculation with late carry signals
130   assign GE[0]       = EarlyGE[0] ^ CryOut[0];
131   assign GE[1]       = EarlyGE[1] ^ CryOut[1];
132   assign GE[2]       = EarlyGE[2] ^ CryOut[2];
133   assign GE[3]       = EarlyGE[3] ^ CryOut[3];
135   // -----------------------------------
136   // Saturation conditions
137   // -----------------------------------
139   // Part of the Sat calculation independent of the adder results
140   assign EarlySat[0]=(~SignedSat&AuInvB)|(SignedSat&(ADataEx[7]^BDataEx[7]));
141   assign EarlySat[1]=(~SignedSat&AuInvB)|(SignedSat&(ADataEx[15]^BDataEx[15]));
142   assign EarlySat[2]=(~SignedSat&AuInvT)|(SignedSat&(ADataEx[23]^BDataEx[23]));
143   assign EarlySat[3]=(~SignedSat&AuInvT)|(SignedSat&(ADataEx[31]^BDataEx[31]));
144
145   // Carry signals available late
146   assign iExt[0]      = EarlySat[0] ^ CryOut[0];
147   assign iExt[1]      = EarlySat[1] ^ CryOut[1];
148   assign iExt[2]      = EarlySat[2] ^ CryOut[2];
149   assign iExt[3]      = EarlySat[3] ^ CryOut[3];
150
151   // Calculate overflow
152   assign Sat[0]      = (iAUOut[7]  & SignedSat) ^ iExt[0];
153   assign Sat[1]      = (iAUOut[16] & SignedSat) ^ iExt[1];
154   assign Sat[2]      = (iAUOut[25] & SignedSat) ^ iExt[2];
155   assign Sat[3]      = (iAUOut[34] & SignedSat) ^ iExt[3];
156
157   assign AUOut={iAUOut[34:27],iAUOut[25:18],iAUOut[16:9],iAUOut[7:0]};
158   assign Ext=iExt;
160 endmodule
