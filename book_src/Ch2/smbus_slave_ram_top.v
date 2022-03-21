001 //DATE:   2009.9.27
002 //AUTHOR: liqinghua
003
004 //`include "timescale.v"
005 //`include "AMBA_defines.v"
006
007 `define ADDR_WIDTH 18
008
009 `define SMBUS_DATA_ADDR  0
010 `define SMBUS_CFG_ADDR   1
011 `define SMBUS_STAT_ADDR  2
012 `define SMBUS_UPPER_ADDR 10
013
014 module smbus_slave_ram_top
015 #(
016   parameter FRAME_NUM  =100,
017   parameter SMBUS_WIDTH=13
018   )
019 (
020 input    HCLK,
021 input    HRESETn,
022 input    clk_8M,
023
024 input [SMBUS_WIDTH-1:0]  RAMAD,
025
026 output[31:0]     RAMRD,
027 input [31:0]     RAMWD,
028 input            RAMCS,
029 input [ 3:0]     RAMWE,
030
031 output     [3:0] bus_wr_or_rd     ,
032
033 input            scl_p_port_in    ,
034 input            sda_p_port_in    ,
035 input            scl_s_port_in    ,
036 input            sda_s_port_in    ,
037
038 output           scl_p_port_out   ,
039 output           sda_p_port_out   ,
040 output           scl_s_port_out   ,
041 output           sda_s_port_out   ,
042
043 output           vic_int
044 );
045 localparam MODE_WIDTH=8;
046 localparam STAT_WIDTH=(8+6+1);
047
048 /// ram planning .....
049 wire rst_x;
050 assign rst_x=HRESETn;
051
052 reg [15:0] bus_cfg;
053 reg [ 7:0] bus_mask;
054 reg  mac_reg_or_mem_data;
055 reg  mac_bus_dir_control;
056
057 wire [31:0] ram_mosi_data;
058 wire [MODE_WIDTH-1:0] ram_mosi_mode;
059
060 wire [31:0] ahb_smbus_wr_data;
061 wire [MODE_WIDTH-1:0] ahb_smbus_wr_mode;
062
063 wire [31:0] ahb_smbus_rd_data;
064 wire [STAT_WIDTH-1:0] ahb_smbus_rd_stat;
065
066 wire      syn_rst;
067 reg [6:0] RAM_RW_NUM;
068 reg  auto_mr;
069 reg  tx_mr;
070 reg[3:0]auto_mr_mode;
071 reg[6:0]s_id;
072 wire[31:0]all_mr_mode;
073
074 reg  ack_set;
075 reg  ack_or_nack;
076
077 wire  ctr_mode;
078 wire  [3:0] mr_mode;
079 wire  [4:0] sm_state;
080
081 wire  [6:0] mosi_addr;
082 wire        mosi_rd;
083 wire  [31:0]mosi_data;
084 wire  [MODE_WIDTH-1:0] mosi_mode;
085
086 wire  [6:0] miso_addr;
087 wire        miso_wr;
088 wire  [31:0]miso_data;
089 wire  [STAT_WIDTH-1:0] miso_stat;
090 wire        miso_ok;
091
092 wire [7:0] mr_data_out;
093 wire [5:0] mr_same_flag;
094 wire       mr_data_ok;
095
096
097 wire  [14:0] timestamp;
098
099 wire  halfbyte_int;
100 wire  byte_int;
101 wire  frame_int;
102 wire  sync_int;
103
104 wire [3:0] port_in={scl_p_port_in,sda_p_port_in,scl_s_port_in,sda_s_port_in};
105 wire [3:0] port_out;
106 assign scl_p_port_out=port_out[3];
107 assign sda_p_port_out=port_out[2];
108 assign scl_s_port_out=port_out[1];
109 assign sda_s_port_out=port_out[0];
110
111 wire [3:0] port_in_core;
112 wire [3:0] port_out_core;
113
114  bus_reshuffle U_bus_reshuffle_in(
115     .cfg  (bus_cfg[7:0]  )
116    ,.mask (bus_mask[3:0] )
117
118    ,.in   (port_in[3:0]  )
119    ,.out  (port_in_core[3:0])
120  );
121
122  bus_reshuffle U_bus_reshuffle_out(
123     .cfg  (bus_cfg[15:8] )
124    ,.mask (bus_mask[7:4] )
125
126    ,.in   (port_out_core[3:0])
127    ,.out  (port_out[3:0] )
128  );
129 smbus_slave
130 #(
131    .FRAME_NUM(FRAME_NUM),
132    .ID (1)
133   )
134 u_smbus_slave
135 (
136    . clk_8M              (clk_8M               )
137   ,. rst_x               (rst_x                )
138
139   ,. syn_rst             (syn_rst              )
140
141   ,. scl_p_port_in       (port_in_core[3]      )
142   ,. sda_p_port_in       (port_in_core[2]      )
143   ,. scl_s_port_in       (port_in_core[1]      )
144   ,. sda_s_port_in       (port_in_core[0]      )
145
146   ,. scl_p_port_out      (port_out_core[3]     )
147   ,. sda_p_port_out      (port_out_core[2]     )
148   ,. scl_s_port_out      (port_out_core[1]     )
149   ,. sda_s_port_out      (port_out_core[0]     )
150   ,. RAM_RW_NUM          (RAM_RW_NUM           )
151
152   ,. bus_wr_or_rd        (bus_wr_or_rd         )
153
154   ,. ack_set             (ack_set              )
155   ,. ack_or_nack         (ack_or_nack          )
156
157   ,. sm_state            (sm_state             )
158
159   ,. ctr_mode            (ctr_mode             )
160   ,. mr_mode             (mr_mode              )
161   ,. auto_mr             (auto_mr              )
162   ,. auto_mr_mode        (auto_mr_mode         )
163   ,. all_mr_mode         (all_mr_mode          )
164
165   ,. mosi_addr           (mosi_addr            )
166   ,. mosi_rd             (mosi_rd              )
167   ,. mosi_data           (mosi_data            )
168   ,. mosi_mode           (mosi_mode            )
169
170   ,. miso_addr           (miso_addr            )
171   ,. miso_wr             (miso_wr              )
172   ,. miso_data           (miso_data            )
173   ,. s_id                (s_id                 )
174
175   ,. timestamp           (timestamp            )
176   ,. smbus_state_error   (smbus_state_error    )
177
178   ,. halfbyte_int        (halfbyte_int         )
179   ,. slave_sync_ok_int   (slave_sync_ok_int    )
180   ,. byte_int            (byte_int             )
181   ,. frame_int           (frame_int            )
182   ,. sync_int            (sync_int             )
183
184 );
185
186 localparam INT_NUM = 6;
187 wire [INT_NUM-1:0] int_source={smbus_state_error,slave_sync_ok_int,halfbyte_int,byte_int,frame_int,sync_int};//sync_int
188
189 reg [INT_NUM-1:0] int_mask;
190 reg [INT_NUM-1:0] int_clr;
191 wire [INT_NUM-1:0] int_reg;
192 wire [INT_NUM-1:0] int_mask_reg;
193
194 simple_vic #(.INT_NUM(INT_NUM),.INT_WIDTH(3)) U_simple_vic (
195    .clk            (HCLK            )
196   ,.rst_x          (HRESETn         )
197
198   ,.int_source     (int_source      )
199   ,.int_mask       (int_mask        )
200   ,.int_clr        (int_clr         )
201
202   ,.vic_int        (vic_int         )
203   ,.int_reg        (int_reg         )
204   ,.int_mask_reg   (int_mask_reg    )
205 );
206
207 wire [SMBUS_WIDTH-1:0] addr_reg;
208 assign addr_reg=RAMAD;
209
210 /*
211 reg [SMBUS_WIDTH-1:0] addr_reg;
212 always @(posedge HCLK or negedge rst_x)
213   if(!rst_x)
214     addr_reg <='h0 ;
215   else
216     addr_reg <=RAMAD ;
217 */
218
219 reg disable_signal;
220 reg reset_signal;
221 reg reset_signal_d0;
222
223 always @(posedge HCLK or negedge rst_x)
224   if(!rst_x)
225     reset_signal_d0 <=1'b0;
226   else
227     reset_signal_d0 <=reset_signal;
228
229 assign syn_rst=(reset_signal&~reset_signal_d0)|disable_signal; // with 1 pulse
230
231 reg [31:0] reg_mosi_data;
232 reg [MODE_WIDTH-1:0] reg_mosi_mode;
233
234 reg [30:0] bch_dec_in;
235 wire [20:0] bch_dec_out;
236 wire [20:0] bch_dec_msk;
237 wire bch_dec_err;
238
239 reg [20:0] bch_enc_in;
240 wire[ 9:0] bch_enc_ecc;
241
242 bch_encoder #(
243   .P_D_WIDTH(21)
244 ) U_bch_encoder(
245     .data_org_in (bch_enc_in ),
246     .data_ecc_out(bch_enc_ecc)
247 );
248
249 `ifdef NO_USE_BCH
250 assign bch_dec_msk=0;
251 assign bch_dec_err=0;
252 `else
253 bch_decoder #(
254   .P_D_WIDTH(21)
255 )U_bch_decoder(
256     .clk(HCLK),
257     .en (HRESETn),
258     .d_i       (bch_dec_in[20: 0]),
259     .ecc_i     (bch_dec_in[30:21]), // TBD
260     .msk_o     (bch_dec_msk[20:0]), // TBD
261     .err_det_o (bch_dec_err      )
262 );
263 `endif
264
265 assign bch_dec_out=bch_dec_msk[20:0] ^ bch_dec_in[20:0];
266
267 always @(posedge HCLK or negedge rst_x)
268   if(!rst_x)
269   begin
270     auto_mr<=0;
271     auto_mr_mode<=0;
272     tx_mr<=0;
273     bus_cfg<=0;
274     bus_mask<=8'hff;
275
276     int_clr<='d0;
277     int_mask<=8'h0f;
278
279     reset_signal<=0;
280     disable_signal<=1'b0;
281     ack_or_nack<=1;
282     ack_set<=0;
283     s_id<=7'b1;
284     mac_reg_or_mem_data<=0;
285     mac_bus_dir_control<=0;
286
287     bch_enc_in<=0;
288     bch_dec_in<=0;
289
290     reg_mosi_data<=0;
291     reg_mosi_mode<=0;
292
293     RAM_RW_NUM<=7'd110;
294
295   end
296   else if(|RAMWE& (RAMAD[12]==0))
297   begin
298     case(RAMAD[11:2])
299       10'h00: begin
300         if(RAMWE[0]) tx_mr<=RAMWD[0];
301         if(RAMWE[0]) auto_mr<=RAMWD[1];
302         if(RAMWE[0]) auto_mr_mode[3:0]<=RAMWD[7:4];
303         if(RAMWE[1]) mac_reg_or_mem_data<=RAMWD[8];
304         if(RAMWE[2]) mac_bus_dir_control<=RAMWD[16];
305         if(RAMWE[3]) reset_signal<=RAMWD[24];
306         if(RAMWE[3]) disable_signal<=RAMWD[31];
307       end
308
309       10'h01:begin
310         if(RAMWE[0]) ack_set<=RAMWD[0];
311         if(RAMWE[1]) ack_or_nack<=RAMWD[8];
312       end
313
314       10'h02:begin
315         bch_dec_in<=RAMWD;
316       end
317
318       10'h03:begin
319         bch_enc_in<=RAMWD;
320       end
321
322       10'h4:begin
323         reg_mosi_mode<=RAMWD;
324       end
325
326       10'h05:begin
327         if(RAMWE[0]) reg_mosi_data[ 7: 0]<=RAMWD[ 7: 0];
328         if(RAMWE[1]) reg_mosi_data[15: 8]<=RAMWD[15: 8];
329         if(RAMWE[2]) reg_mosi_data[23:16]<=RAMWD[23:16];
330         if(RAMWE[3]) reg_mosi_data[31:24]<=RAMWD[31:24];
331       end
332
333       10'h09:begin
334         if(RAMWE[0]) int_mask<=RAMWD[7:0];
335       end
336
337       10'h0f:begin
338         if(RAMWE[0]) int_clr<=RAMWD[INT_NUM-1:0];
339       end
340
341       10'h0c:begin
342         if(RAMWE[0]) RAM_RW_NUM<=RAMWD[6:0];
343       end
344
345       10'h15:begin
346         if(RAMWE[0]) s_id<=RAMWD[6:0];
347         if(RAMWE[1]) bus_cfg[ 7:0] <=RAMWD[15:8];
348         if(RAMWE[2]) bus_cfg[15:8] <=RAMWD[23:16];
349         if(RAMWE[3]) bus_mask[7:0] <=RAMWD[31:24];
350       end
351       //10'h06 miso_rd
352     endcase
353
354   end
355   else
356   begin
357     int_clr<='d0;
358   end
359
360 reg [31:0] ram_rd_data;
361 assign RAMRD=ram_rd_data;
362
363 reg [6:0] cmp_ok_cnt;
364 reg [6:0] last_err_byte;
365
366 always @( * )
367 begin
368   ram_rd_data=32'd0;
369   if(addr_reg[12]==0)
370   begin
371     case(addr_reg[11:2])
372       10'h0:begin
373         ram_rd_data[ 0]=tx_mr;
374         ram_rd_data[ 1]=auto_mr;
375         ram_rd_data[7:4]=auto_mr_mode;
376         ram_rd_data[ 8]=mac_reg_or_mem_data;
377         ram_rd_data[16]=mac_bus_dir_control;
378         ram_rd_data[24]=reset_signal ;
379         ram_rd_data[31]=disable_signal;
380       end
381
382       10'h1:begin
383         ram_rd_data[0]=ack_set;
384         ram_rd_data[8]=ack_or_nack;
385       end
386
387       10'h2:begin
388         ram_rd_data[30:0] = bch_dec_in;
389       end
390
391       10'h3:begin
392         ram_rd_data[20:0] = bch_enc_in;
393         ram_rd_data[30:21]= bch_enc_ecc;
394         ram_rd_data[31]   = (^bch_enc_in)^(bch_enc_ecc);
395       end
396
397       10'h4:begin
398         ram_rd_data=reg_mosi_mode;
399       end
400
401       10'h5:begin
402         ram_rd_data=reg_mosi_data;
403       end
404
405       10'd6:begin
406         ram_rd_data=miso_data;
407       end
408
409       10'd7:begin
410         ram_rd_data[INT_NUM-1:0]=int_reg;
411         ram_rd_data[11: 7]=sm_state;
412         ram_rd_data[15:12]=mr_mode;
413         ram_rd_data[30:16]=timestamp;
414
415         ram_rd_data[31]=ctr_mode;
416       end
417
418       10'h8:begin
419         ram_rd_data[ 7: 0]=mosi_addr;
420         ram_rd_data[15: 8]=miso_addr;
421       end
422
423       10'h9:begin
424         ram_rd_data[INT_NUM-1:0]=int_mask_reg;
425         ram_rd_data[15: 8]=int_mask;
426         ram_rd_data[INT_NUM+15:16]=int_reg;
427       end
428
429       10'ha:begin
430         ram_rd_data[20:0]=bch_dec_out[20:0];
431         ram_rd_data[31]=bch_dec_err;
432       end
433
434       10'h0c:begin // RAM_RW_NUM
435         ram_rd_data[ 6: 0]=RAM_RW_NUM;
436         ram_rd_data[14: 8]=last_err_byte;
437         ram_rd_data[22:16]=cmp_ok_cnt;
438         ram_rd_data[31:24]=mr_data_out;
439       end
440
441       10'h0d:begin // mac_mask
442       end
443
444       10'hf:begin
445         ram_rd_data[INT_NUM-1:0]=int_clr;
446         ram_rd_data[15: 8]=int_mask;
447         ram_rd_data[INT_NUM+15:16]=int_reg;
448         ram_rd_data[31:24]=int_mask_reg;
449       end
450
451
452       10'h13:begin
453         ram_rd_data=all_mr_mode;
454       end
455
456       10'h15:begin
457         ram_rd_data[6: 0]=s_id;
458         ram_rd_data[23: 8]=bus_cfg;
459         ram_rd_data[31:24]=bus_mask;
460       end
461
462     endcase
463   end
464   else
465   begin
466     if(addr_reg[11:10]==2'b10&addr_reg[9]==0)
467     begin
468       ram_rd_data=ahb_smbus_wr_mode;
469     end
470
471     if(addr_reg[11:10]==2'b11&addr_reg[9]==0)
472     begin
473       ram_rd_data=ahb_smbus_wr_data;
474     end
475
476     if(addr_reg[11:10]==2'b10&addr_reg[9]==1)
477     begin
478       ram_rd_data=ahb_smbus_rd_stat;
479     end
480
481     if(addr_reg[11:10]==2'b11&addr_reg[9]==1)
482     begin
483       ram_rd_data=ahb_smbus_rd_data;
484     end
485
486   end
487
488 end
489
490 //assign RAMRD[31:0]=smbus_rd_rd[31:0];
491
492 assign mosi_data = tx_mr ? ( mac_reg_or_mem_data ? {4{reg_mosi_data[7:0]}} : {4{ram_mosi_data[7:0]}} ): ( mac_reg_or_mem_data ? reg_mosi_data : ram_mosi_data ) ;
493 assign mosi_mode = (mac_bus_dir_control) ? reg_mosi_mode : ram_mosi_mode ;
494
495 /// U_smbus_wr_data_ram
496 wire smbus_data_wr_data_we=|RAMWE&(RAMAD[11:10]==2'b11)&(RAMAD[12]==1)&(RAMAD[9]==0);
497
498 true_dpram
499 #(. DATA_WIDTH(32),. ADDR_WIDTH(7))
500 U_smbus_data_wr_data_ram
501 (
502      . data_a    (RAMWD           )
503     ,. data_b    (0               )
504     ,. addr_a    (RAMAD[8:2]      )
505     ,. addr_b    (mosi_addr       )
506     ,. we_a      (smbus_data_wr_data_we)
507     ,. we_b      (1'b0            )
508     ,. clk_a     (HCLK            )
509     ,. clk_b     (clk_8M          )
510     ,. q_a       (ahb_smbus_wr_data)
511     ,. q_b       (ram_mosi_data)
512  );
513
514 /// U_smbus_wr_data_ram
515 wire smbus_data_wr_mode_we=|RAMWE&(RAMAD[11:10]==2'b10)&(RAMAD[12]==1)&(RAMAD[9]==0);
516
517 true_dpram
518 #(. DATA_WIDTH(MODE_WIDTH),. ADDR_WIDTH(7))
519 U_smbus_data_wr_mode_ram
520 (
521      . data_a    (RAMWD           )
522     ,. data_b    (0               )
523     ,. addr_a    (RAMAD[8:2]      )
524     ,. addr_b    (mosi_addr       )
525     ,. we_a      (smbus_data_wr_mode_we)
526     ,. we_b      (1'b0            )
527     ,. clk_a     (HCLK            )
528     ,. clk_b     (clk_8M          )
529     ,. q_a       (ahb_smbus_wr_mode)
530     ,. q_b       (ram_mosi_mode)
531  );
532
533 /// U_smbus_rd_data_ram
534 wire ahb_smbus_rd_data_we=|RAMWE&(RAMAD[11:10]==2'b11)&(RAMAD[12]==1)&(RAMAD[9]==1);
535
536 true_dpram
537 #(. DATA_WIDTH(32),. ADDR_WIDTH(7))
538 U_smbus_rd_data_ram
539 (
540    . data_a    (RAMWD           )
541   ,. data_b    (miso_data       )
542   ,. addr_a    (RAMAD[8:2]      )
543   ,. addr_b    (miso_addr       )
544   ,. we_a      (ahb_smbus_rd_data_we)
545   ,. we_b      (miso_wr         )
546   ,. clk_a     (HCLK            )
547   ,. clk_b     (clk_8M          )
548   ,. q_a       (ahb_smbus_rd_data)
549   ,. q_b       ()
550 );
551
552 /// U_smbus_rd_state_ram
553 wire ahb_smbus_rd_stat_we=|RAMWE&(RAMAD[11:10]==2'b10)&(RAMAD[12]==1)&(RAMAD[9]==1);
554 wire check_finish;
555 true_dpram
556 #(. DATA_WIDTH(STAT_WIDTH),. ADDR_WIDTH(7))
557 U_smbus_rd_stat_ram
558 (
559    . data_a    (RAMWD           )
560   ,. data_b    (miso_stat       )
561   ,. addr_a    (RAMAD[8:2]      )
562   ,. addr_b    (miso_addr       )
563   ,. we_a      (ahb_smbus_rd_stat_we)
564   ,. we_b      (check_finish    )
565   ,. clk_a     (HCLK            )
566   ,. clk_b     (clk_8M          )
567   ,. q_a       (ahb_smbus_rd_stat)
568   ,. q_b       ()
569 );
570
571
572 assign miso_stat={mr_data_ok,mr_same_flag,mr_data_out};
573
574 cmp_quad_data #(.DATA_WIDTH(8)) U_cmp_quad_data(
575    .clk          (clk_8M          )
576   ,.rst_x        (rst_x           )
577   ,.check_flag   (miso_wr         )
578   ,.mr_mode      (mr_mode         )
579
580   ,.data_in0     (miso_data[ 7: 0])
581   ,.data_in1     (miso_data[15: 8])
582   ,.data_in2     (miso_data[23:16])
583   ,.data_in3     (miso_data[31:24])
584
585   ,.mr_data_out  (mr_data_out     )
586   ,.same_flag    (mr_same_flag    )
587   ,.check_finish (check_finish    )
588   ,.data_ok      (mr_data_ok      )
589 );
590
591 always @(posedge clk_8M or negedge rst_x)
592   if(!rst_x)
593   begin
594     cmp_ok_cnt<=0;
595     last_err_byte<=0;
596   end
597   else if(miso_addr==0)
598   begin
599     cmp_ok_cnt<=0;
600     last_err_byte<=0;
601   end
602   else if(check_finish)
603   begin
604     if(miso_addr<=RAM_RW_NUM)
605     begin
606       if(mr_data_ok)
607         cmp_ok_cnt<=cmp_ok_cnt+1;
608       else
609         last_err_byte<=miso_addr;
610     end
611   end
612
613 endmodule
614