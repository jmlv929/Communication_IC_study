 always @(posedge sysclk or negedge rst_x)
   if(!rst_x)
     state <= IDLE;
   else if (enable == 1'b1)
     state <= next_state;
   else
     state <= IDLE;
 
 always @(state or tx_data_ready or i_sck or d_sck)
 begin
   clear_tx_data_ready = 1'b0;
   shift_enable = 1'b0;
   tx_shift_reg_load = 1'b0;
   i_ss = 1'b1;
   sck_enable = 1'b0;
   load_rx_data_reg = 1'b0;
   next_state = IDLE;
   case (state)
     IDLE :if (tx_data_ready == 1'b1 & i_sck == 1'b1 & d_sck == 1'b0)
       begin
         clear_tx_data_ready = 1'b1;
         next_state = LOAD_SHIFT_REG;
       end
       else
         next_state = IDLE;
     LOAD_SHIFT_REG : begin
       tx_shift_reg_load = 1'b1;
       if (d_sck == 1'b0)begin
         i_ss = 1'b0;
         if (i_sck == 1'b1)
           next_state = D7;
         else
           next_state = LOAD_SHIFT_REG;
       end
       else
         next_state = LOAD_SHIFT_REG;
     end
     D7 :begin
       i_ss = 1'b0;
       sck_enable = 1'b1;
       if (i_sck == 1'b1 & d_sck == 1'b0)begin
         shift_enable = 1'b1;
         next_state = D6;
       end
       else
         next_state = D7;
     end
     D6 : begin
       i_ss = 1'b0;
       sck_enable = 1'b1;
       if (i_sck == 1'b1 & d_sck == 1'b0)begin
         shift_enable = 1'b1;
         next_state = D5;
       end
       else
           next_state = D6;
     end
     D5 :begin
       i_ss = 1'b0;
       sck_enable = 1'b1;
       if (i_sck == 1'b1 & d_sck == 1'b0)begin
         shift_enable = 1'b1;
         next_state = D4;
       end
       else
         next_state = D5;
     end
     D4 :begin
       i_ss = 1'b0;
       sck_enable = 1'b1;
       if (i_sck == 1'b1 & d_sck == 1'b0)begin
         shift_enable = 1'b1;
         next_state = D3;
       end
       else
         next_state = D4;
     end
     D3 :begin
       i_ss = 1'b0;
       sck_enable = 1'b1;
       if (i_sck == 1'b1 & d_sck == 1'b0)begin
         shift_enable = 1'b1;
         next_state = D2;
       end
       else
         next_state = D3;
     end
     D2 :begin
       i_ss = 1'b0;
       sck_enable = 1'b1;
       if (i_sck == 1'b1 & d_sck == 1'b0)begin
         shift_enable = 1'b1;
         next_state = D1;
       end
       else
         next_state = D2;
     end
     D1 :begin
       i_ss = 1'b0;
       sck_enable = 1'b1;
       if (i_sck == 1'b1 & d_sck == 1'b0)begin
         shift_enable = 1'b1;
         next_state = D0;
       end
       else
         next_state = D1;
     end
     D0 : begin
       i_ss = 1'b0;
       sck_enable = 1'b1;
       if (i_sck == 1'b1 & d_sck == 1'b0)begin
         shift_enable = 1'b1;
         next_state = FINAL_CYCLE;
       end
       else
         next_state = D0;
     end
     FINAL_CYCLE :if (d_sck == 1'b1)begin
         i_ss = 1'b0;
         next_state = FINAL_CYCLE;
       end
       else begin
         load_rx_data_reg = 1'b1;
         i_ss = 1'b1;
         if (tx_data_ready == 1'b1 & i_sck == 1'b1)begin
             clear_tx_data_ready = 1'b1;
             next_state = LOAD_SHIFT_REG;
         end
         else
           next_state = IDLE;
       end
   endcase
 end
 

localparam[3:0]  IDLE=0,D7=1,D6=2,D5=3,D4=4,D3=5,D2=6,D1=7,D0=8,FINAL_CYCLE=9,LOAD_SHIFT_REG=10;
