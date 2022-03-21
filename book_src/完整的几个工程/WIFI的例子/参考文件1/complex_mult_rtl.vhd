
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of complex_mult is


begin

complexmult_p: process (clk, reset_n)
  variable rr_v : std_logic_vector(NBit_input1_g+NBit_input2_g-1 downto 0);
  variable ii_v : std_logic_vector(NBit_input1_g+NBit_input2_g-1 downto 0);
  variable ri_v : std_logic_vector(NBit_input1_g+NBit_input2_g-1 downto 0);
  variable ir_v : std_logic_vector(NBit_input1_g+NBit_input2_g-1 downto 0);

begin
  if reset_n = '0' then                 -- asynchronous reset (active low)
    real_o <= (others => '0');
    imag_o <= (others => '0');
    rr_v   := (others => '0');
    ii_v   := (others => '0');
    ri_v   := (others => '0');
    ir_v   := (others => '0');
  elsif clk'event and clk = '1' then    -- rising clock edge
    rr_v := signed(real_1_i)*signed(real_2_i);
    ii_v := signed(imag_1_i)*signed(imag_2_i);
    ri_v := signed(real_1_i)*signed(imag_2_i);
    ir_v := signed(imag_1_i)*signed(real_2_i);
    real_o <= SXT(rr_v,real_o'length) - SXT(ii_v,real_o'length);
    imag_o <= SXT(ri_v,imag_o'length) + SXT(ir_v,imag_o'length);
   
  end if;
end process complexmult_p;



end rtl;
