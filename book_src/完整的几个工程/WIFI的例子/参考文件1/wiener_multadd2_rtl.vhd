

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of wiener_multadd2 is


  -- data output from multipliers, divided by 64
  signal mult1_scaled : std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-2 downto 0);
  signal mult2_scaled : std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-2 downto 0);

begin

  --------------------------------------------
  -- Combinational computation
  --------------------------------------------
  data_comb : process (data1_i, data2_i, chanwien_c0_i, chanwien_c1_i)
    variable mult1_v      : std_logic_vector(FFT_WIDTH_CT+WIENER_COEFF_WIDTH_CT-1 downto 0);
    variable mult2_v      : std_logic_vector(FFT_WIDTH_CT+WIENER_COEFF_WIDTH_CT-1 downto 0);
    variable mult1_shr_v  : std_logic_vector(FFT_WIDTH_CT+WIENER_COEFF_WIDTH_CT-1 downto 0);
    variable mult2_shr_v  : std_logic_vector(FFT_WIDTH_CT+WIENER_COEFF_WIDTH_CT-1 downto 0);
  begin

    mult1_v      := signed(data1_i) * signed(chanwien_c0_i);
    mult2_v      := signed(data2_i) * signed(chanwien_c1_i);
    
    mult1_shr_v  := std_logic_vector(SHR(signed(mult1_v),conv_unsigned(WIENER_FIRSTROUND_WIDTH_CT+1,mult1_v'length)));
    mult2_shr_v  := std_logic_vector(SHR(signed(mult2_v),conv_unsigned(WIENER_FIRSTROUND_WIDTH_CT+1,mult2_v'length)));

    mult1_scaled <= mult1_shr_v(WIENER_FIRSTADD_WIDTH_CT-2 downto 0);
    mult2_scaled <= mult2_shr_v(WIENER_FIRSTADD_WIDTH_CT-2 downto 0);
  end process data_comb;

  --------------------------------------------
  -- Registered output
  --------------------------------------------
  data_reg : process (clk, reset_n)
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
      add_o <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if module_enable_i = '1' then
        if en_add_reg_i = '1' then
          add_o <= SXT(mult1_scaled, WIENER_FIRSTADD_WIDTH_CT) + 
                   SXT(mult2_scaled, WIENER_FIRSTADD_WIDTH_CT);
        end if;
      end if;
    end if;
  end process data_reg;

end rtl;
