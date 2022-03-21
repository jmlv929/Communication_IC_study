if bit(15)/=bit(14)		
  bit15为符号位，bit14为有效数据
elsif bit(14)/=bit(13)		
  bit15..bit14为符号位，bit13为有效数据
elsif bit(9)/=bit(8)		
  bit15..bit9为符号位，bit8为有效数据
else
  不再判断

dat_i_xor7 <= Pid_txiqbuf_data(15) xor Pid_txiqbuf_data(14);
dat_i_xor6 <= Pid_txiqbuf_data(14) xor Pid_txiqbuf_data(13);
dat_i_xor5 <= Pid_txiqbuf_data(13) xor Pid_txiqbuf_data(12);
dat_i_xor4 <= Pid_txiqbuf_data(12) xor Pid_txiqbuf_data(11);
dat_i_xor3 <= Pid_txiqbuf_data(11) xor Pid_txiqbuf_data(10);
dat_i_xor2 <= Pid_txiqbuf_data(10) xor Pid_txiqbuf_data(9);
dat_i_xor1 <= Pid_txiqbuf_data(9)  xor Pid_txiqbuf_data(8);
----15-12 c1mpress
process(sys_rst,clk_wr)
begin
if (sys_rst = '1') then
    txiqbuf_data_i_t <= x"0000";
  elsif rising_edge(clk_wr) then
    if(dat_i_xor7='1') then
      txiqbuf_data_i_t <= "0000" & "111" & Pid_txiqbuf_data(15 downto 7);
     elsif(dat_i_xor6='1') then
         txiqbuf_data_i_t <= "0000" & "110" & Pid_txiqbuf_data(14 downto 6);
    elsif(dat_i_xor5='1') then
         txiqbuf_data_i_t <= "0000" & "101" & Pid_txiqbuf_data(13 downto 5);
    elsif(dat_i_xor4='1') then
         txiqbuf_data_i_t <= "0000" & "100" & Pid_txiqbuf_data(12 downto 4);
    elsif(dat_i_xor3='1') then
         txiqbuf_data_i_t <= "0000" & "011" & Pid_txiqbuf_data(11 downto 3);
    elsif(dat_i_xor2='1') then
         txiqbuf_data_i_t <= "0000" & "010" & Pid_txiqbuf_data(10 downto 2);
    elsif(dat_i_xor1='1') then
         txiqbuf_data_i_t <= "0000" & "001" & Pid_txiqbuf_data(9 downto 1);
    else --dat_i_xor0='1' or dat_i_xor0='0' 
         txiqbuf_data_i_t <= "0000" & "000" & Pid_txiqbuf_data(8 downto 0);
    end if;
  end if;
end process;

process(clk)
begin
  if rising_edge(clk) then
    if accu_calc_real(37 downto 32)="000000" or accu_calc_real(37 downto 32)="111111" then
      mmse_hfil_real_16 <= accu_calc_real(32 downto 17);
    else
      if accu_calc_real(37)='1' then
        mmse_hfil_real_16 <= x"8000";
      else
        mmse_hfil_real_16 <= x"7fff"; 
      end if;
    end if;
  end if;
end process;


--  scale 16
process(clk)
begin
  if rising_edge(clk) then
    if detect_part2s_max(31 downto 16)=x"0000" then
      detect_part2s_max_scale_t1 <= '1';
      detect_part2s_max_d1       <= detect_part2s_max(15 downto 0) ;
    else
      detect_part2s_max_scale_t1 <= '0';
      detect_part2s_max_d1       <= detect_part2s_max(31 downto 16) ;
    end if;
  end if;
end process;
-- scale 8
process(clk)
begin
  if rising_edge(clk) then
    detect_part2s_max_scale_t2(1) <= detect_part2s_max_scale_t1;
    if detect_part2s_max_d1(15 downto 8)=x"00" then
      detect_part2s_max_scale_t2(0) <= '1';
      detect_part2s_max_d2<= detect_part2s_max_d1(7 downto 0) ;
    else
      detect_part2s_max_scale_t2(0) <= '0';
      detect_part2s_max_d2<= detect_part2s_max_d1(15 downto 8) ;
    end if;
  end if;
end process;

-- scale 4
process(clk)
begin
  if rising_edge(clk) then
    detect_part2s_max_scale_t3(2 downto 1) <= detect_part2s_max_scale_t2;
    if detect_part2s_max_d2(7 downto 4)="0000" then
      detect_part2s_max_scale_t3(0) <= '1';
      detect_part2s_max_d3<= detect_part2s_max_d2(3 downto 0) ;
    else
      detect_part2s_max_scale_t3(0) <= '0';
      detect_part2s_max_d3<= detect_part2s_max_d2(7 downto 4) ;
    end if;
  end if;
end process;

-- scale 2
process(clk)
begin
  if rising_edge(clk) then
    detect_part2s_max_scale_t4(3 downto 1) <= detect_part2s_max_scale_t3;
    if detect_part2s_max_d3(3 downto 2)="00" then
      detect_part2s_max_scale_t4(0) <= '1';
      detect_part2s_max_d4<= detect_part2s_max_d3(1 downto 0) ;
    else
      detect_part2s_max_scale_t4(0) <= '0';
      detect_part2s_max_d4<= detect_part2s_max_d3(3 downto 2) ;
    end if;
  end if;
end process;

-- scale 1
process(clk)
begin
  if rising_edge(clk) then
    detect_part2s_max_scale_t5(4 downto 1) <= detect_part2s_max_scale_t4;
    if detect_part2s_max_d4(1)='0' then
      detect_part2s_max_scale_t5(0) <= '1';
    else
      detect_part2s_max_scale_t5(0) <= '0';
    end if;
  end if;
end process;

	for i=1:16
		if data(15)=0,	data<<1
	end
  
  Alpha_data(0)=
	If	Alpha_data(m)>datacomp
		Alpha_data(m+1) = Alpha_data(m) + dataoff2
	Else
		Alpha_data(m+1) = Alpha_data(m) + dataoff1

    
 4 process(clk)
 5 begin
 6   if rising_edge(clk) then
 7     theta(17 downto 15) <= theta_in(17 downto 15) ;
 8     if theta_in(15)='0' then
 9       theta(14 downto 0) <= theta_in(14 downto 0);
10     elsif theta_in(14 downto 0) = "000000000000000" then
11       theta(14 downto 0) <= "111111111111111" ;
12     else
13       theta(14 downto 0) <= 0 - theta_in(14 downto 0);
14     end if;
15   end if;
16 end process;
17 
22 process(clk)
23 begin
24   if rising_edge(clk) then
25     exp_table_addr <= theta(14 downto 7);
26   end if;
27 end process;    
28 
29 -- lookup table
30 inst_rx_che_exp_table: rx_che_exp_table
31 port map(
32   clk       => clk    ,
33   exp_table_addr      => exp_table_addr   ,
34   exp_table_realdata  => exp_table_rdata  ,
35   exp_table_imagdata  => exp_table_idata  ,
36   exp_table_realdiff  => exp_table_rdiff  ,
37   exp_table_imagdiff  => exp_table_idiff 
38 );
39 
40 -- exp mult
41 -- diff value, delay 3 clk
42 process(clk)
43 begin
44   if rising_edge(clk) then
45     exp_diff_data_t1 <= theta;
46     exp_diff_data_t2 <= exp_diff_data_t1;
47     exp_diff_data    <= exp_diff_data_t2;
48   end if;
49 end process;
50 
51 -- base data delay, 1 clock
52 process(clk)
53 begin
54   if rising_edge(clk) then
55     exp_base_rdata <= exp_table_rdata ; 
56     exp_base_idata <= exp_table_idata ;
57   end if;
58 end process;
59 
60 -- real calc, pout=c_in-a_in*b_in
61 inst_real_dsp :rx_che_exp_dspma
62 port map(
63   clk    => clk   ,
64   a_in(7)=> '0'   ,
65   a_in(6 downto 0) => exp_diff_data   ,
66   b_in   => exp_table_rdiff ,
67   c_in   => exp_base_rdata  ,
68   sign_in=> '1'   ,
69   p_out  => exp_calc_rdata 
70 );
71 
72 -- imag calc, pout=c_in+a_in*b_in
73 inst_imag_dsp :rx_che_exp_dspma
74 port map(
75   clk    => clk   ,
76   a_in(7)=> '0'   ,
77   a_in(6 downto 0) => exp_diff_data   ,
78   b_in   => exp_table_idiff ,
79   c_in   => exp_base_idata  ,
80   sign_in=> '0'   ,
81   p_out  => exp_calc_idata 
82 );
83 

97 -- sign delay
98 sign_data_delay: for i in 0 to 2 generate
99   begin
100     SRL16E_inst : SRL16E
101     generic map (
102       INIT => X"0000")
103       port map (
104         Q   => exp_sign_t(i)    ,   -- SRL data output
105         A0  => '1'    ,   -- Select[0] input
106         A1  => '0'    ,   -- Select[1] input
107         A2  => '1'    ,   -- Select[2] input
108         A3  => '0'    ,   -- Select[3] input
109         CE  => '1'    ,   -- Clock enable input
110         CLK => clk    ,   -- Clock input
111         D   => theta(i+15)-- SRL data input
112       );
113     end generate;
114     
115   process(clk)
116   begin
117     if rising_edge(clk) then
118       exp_sign <= exp_sign_t ;
119     end if;
120   end process;
121   
122   -- data
123   process(clk)
124   begin
125     if rising_edge(clk) then
126       case exp_sign is  
127       when "000" =>
128         exponent_real <= exp_calc_rdata(22 downto 7);
129         exponent_imag <= 0 - exp_calc_idata(22 downto 7);
130       when "001" =>
131         exponent_real <= exp_calc_idata(22 downto 7);
132         exponent_imag <= 0 - exp_calc_rdata(22 downto 7);
133       when "010" =>
134         exponent_real <= 0 - exp_calc_idata(22 downto 7);
135         exponent_imag <= 0 - exp_calc_rdata(22 downto 7);
136       when "011" =>
137         exponent_real <= 0 - exp_calc_rdata(22 downto 7);
138         exponent_imag <= 0 - exp_calc_idata(22 downto 7);
139       when "100" =>
140         exponent_real <= 0 - exp_calc_rdata(22 downto 7);
141         exponent_imag <= exp_calc_idata(22 downto 7);
142       when "101" =>
143         exponent_real <= 0 - exp_calc_idata(22 downto 7);
144         exponent_imag <= exp_calc_rdata(22 downto 7);
145       when "110" =>
146         exponent_real <= exp_calc_idata(22 downto 7);
147         exponent_imag <= exp_calc_rdata(22 downto 7);
148       when "111" =>
149         exponent_real <= exp_calc_rdata(22 downto 7);
150         exponent_imag <= exp_calc_idata(22 downto 7);
151       when others =>
152         exponent_real <= exp_calc_rdata(22 downto 7);
153         exponent_imag <= 0 - exp_calc_idata(22 downto 7);
154       end case;
155     end if;
156   end process;
157   
158   -- output
159   process(clk)
160   begin
161     if rising_edge(clk) then
162       exp_real_data <= exponent_real ;
163       exp_imag_data <= exponent_imag ;
164     end if;
165   end process;

 1 Xn1Cinit <= "010" & x"a690d92";
 2 Xn2Cinit(0) <= Cinit(5) xor Cinit(6) xor Cinit(13) xor Cinit(14) xor 
 3          Cinit(20) xor Cinit(22) xor Cinit(25) xor Cinit(26) xor Cinit(
 4          29) xor Cinit(30);    
 5 Xn2Cinit(1) <= Cinit(0) xor Cinit(1) xor Cinit(2) xor Cinit(3) xor 
 6          Cinit(6) xor Cinit(7) xor Cinit(14) xor Cinit(15) xor Cinit(
 7          21) xor Cinit(23) xor Cinit(26) xor Cinit(27) xor Cinit(30);
 8 Xn2Cinit(2) <= Cinit(0) xor Cinit(4) xor Cinit(7) xor Cinit(8) xor 
 9          Cinit(15) xor Cinit(16) xor Cinit(22) xor Cinit(24) xor Cinit(
10          27) xor Cinit(28);   
11 Xn2Cinit(3) <= Cinit(1) xor Cinit(5) xor Cinit(8) xor Cinit(9) xor 
12          Cinit(16) xor Cinit(17) xor Cinit(23) xor Cinit(25) xor Cinit(
13          28) xor Cinit(29);           
14 Xn2Cinit(4) <= Cinit(2) xor Cinit(6) xor Cinit(9) xor Cinit(10) xor 
15          Cinit(17) xor Cinit(18) xor Cinit(24) xor Cinit(26) xor Cinit(
16          29) xor Cinit(30);                  
17 Xn2Cinit(5) <= Cinit(0) xor Cinit(1) xor Cinit(2) xor Cinit(7) xor 
18          Cinit(10) xor Cinit(11) xor Cinit(18) xor Cinit(19) xor Cinit(
19          25) xor Cinit(27) xor Cinit(30);                 
20 Xn2Cinit(6) <= Cinit(0) xor Cinit(8) xor Cinit(11) xor Cinit(12) xor 
21          Cinit(19) xor Cinit(20) xor Cinit(26) xor Cinit(28);        
22 Xn2Cinit(7) <= Cinit(1) xor Cinit(9) xor Cinit(12) xor Cinit(13) xor 
23          Cinit(20) xor Cinit(21) xor Cinit(27) xor Cinit(29);          
24 Xn2Cinit(8) <= Cinit(2) xor Cinit(10) xor Cinit(13) xor Cinit(14) xor 
25          Cinit(21) xor Cinit(22) xor Cinit(28) xor Cinit(30);          
26 Xn2Cinit(9) <= Cinit(0) xor Cinit(1) xor Cinit(2) xor Cinit(11) xor 
27          Cinit(14) xor Cinit(15) xor Cinit(22) xor Cinit(23) xor Cinit(
28          29);           
29 Xn2Cinit(10) <= Cinit(1) xor Cinit(2) xor Cinit(3) xor Cinit(12) xor 
30          Cinit(15) xor Cinit(16) xor Cinit(23) xor Cinit(24) xor Cinit(
31          30);         
32 Xn2Cinit(11) <= Cinit(0) xor Cinit(1) xor Cinit(4) xor Cinit(13) xor 
33          Cinit(16) xor Cinit(17) xor Cinit(24) xor Cinit(25);          
34 Xn2Cinit(12) <= Cinit(1) xor Cinit(2) xor Cinit(5) xor Cinit(14) xor 
35          Cinit(17) xor Cinit(18) xor Cinit(25) xor Cinit(26);          
36 Xn2Cinit(13) <= Cinit(2) xor Cinit(3) xor Cinit(6) xor Cinit(15) xor 
37          Cinit(18) xor Cinit(19) xor Cinit(26) xor Cinit(27);          
38 Xn2Cinit(14) <= Cinit(3) xor Cinit(4) xor Cinit(7) xor Cinit(16) xor 
39          Cinit(19) xor Cinit(20) xor Cinit(27) xor Cinit(28);          
40 Xn2Cinit(15) <= Cinit(4) xor Cinit(5) xor Cinit(8) xor Cinit(17) xor 
41          Cinit(20) xor Cinit(21) xor Cinit(28) xor Cinit(29);          
42 Xn2Cinit(16) <= Cinit(5) xor Cinit(6) xor Cinit(9) xor Cinit(18) xor 
43          Cinit(21) xor Cinit(22) xor Cinit(29) xor Cinit(30);         
44 Xn2Cinit(17) <= Cinit(0) xor Cinit(1) xor Cinit(2) xor Cinit(3) xor 
45          Cinit(6) xor Cinit(7) xor Cinit(10) xor Cinit(19) xor Cinit(
46          22) xor Cinit(23) xor Cinit(30);       
47 Xn2Cinit(18) <= Cinit(0) xor Cinit(4) xor Cinit(7) xor Cinit(8) xor 
48          Cinit(11) xor Cinit(20) xor Cinit(23) xor Cinit(24);    
49 Xn2Cinit(19) <= Cinit(1) xor Cinit(5) xor Cinit(8) xor Cinit(9) xor 
50          Cinit(12) xor Cinit(21) xor Cinit(24) xor Cinit(25);  
51 Xn2Cinit(20) <= Cinit(2) xor Cinit(6) xor Cinit(9) xor Cinit(10) xor 
52          Cinit(13) xor Cinit(22) xor Cinit(25) xor Cinit(26);    
53 Xn2Cinit(21) <= Cinit(3) xor Cinit(7) xor Cinit(10) xor Cinit(11) xor 
54          Cinit(14) xor Cinit(23) xor Cinit(26) xor Cinit(27);  
55 Xn2Cinit(22) <= Cinit(4) xor Cinit(8) xor Cinit(11) xor Cinit(12) xor 
56          Cinit(15) xor Cinit(24) xor Cinit(27) xor Cinit(28);    
57 Xn2Cinit(23) <= Cinit(5) xor Cinit(9) xor Cinit(12) xor Cinit(13) xor 
58          Cinit(16) xor Cinit(25) xor Cinit(28) xor Cinit(29);  
59 Xn2Cinit(24) <= Cinit(6) xor Cinit(10) xor Cinit(13) xor Cinit(14) xor 
60          Cinit(17) xor Cinit(26) xor Cinit(29) xor Cinit(30);         
61 Xn2Cinit(25) <= Cinit(0) xor Cinit(1) xor Cinit(2) xor Cinit(3) xor 
62          Cinit(7) xor Cinit(11) xor Cinit(14) xor Cinit(15) xor Cinit(
63          18) xor Cinit(27) xor Cinit(30);       
64 Xn2Cinit(26) <= Cinit(0) xor Cinit(4) xor Cinit(8) xor Cinit(12) xor 
65          Cinit(15) xor Cinit(16) xor Cinit(19) xor Cinit(28);    
66 Xn2Cinit(27) <= Cinit(1) xor Cinit(5) xor Cinit(9) xor Cinit(13) xor 
67          Cinit(16) xor Cinit(17) xor Cinit(20) xor Cinit(29);  
68 Xn2Cinit(28) <= Cinit(2) xor Cinit(6) xor Cinit(10) xor Cinit(14) xor 
69          Cinit(17) xor Cinit(18) xor Cinit(21) xor Cinit(30);  
70 Xn2Cinit(29) <= Cinit(0) xor Cinit(1) xor Cinit(2) xor Cinit(7) xor 
71          Cinit(11) xor Cinit(15) xor Cinit(18) xor Cinit(19) xor Cinit(
72          22);       
73 Xn2Cinit(30) <= Cinit(1) xor Cinit(2) xor Cinit(3) xor Cinit(8) xor 
74          Cinit(12) xor Cinit(16) xor Cinit(19) xor Cinit(20) xor Cinit(
75          23);
