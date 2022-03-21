

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of rx_equ_outstage0 is

  constant MAX_INTERNAL_CT  : integer  := MAX_SOFTBIT_CT * 4 - 1; --59
  -- one more bit to be able to contain -(-512)
  -- a second more bit to be able to do one SHL
  constant INT_LENGTH_CT    : integer  := MANTLEN_CT + 2; 

  signal soft_x0_d     : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_x0_tmp   : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y0_d     : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y0_tmp   : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);

begin

  -------------------------------------------------------------------
  ---                    STAGE 0 
  -------------------------------------------------------------------
  --------------------------------------
  -- SoftX0 compression (barrel shifter)
  --------------------------------------
  soft_x0_p: process (cormanr_i, cormani_i, secondexp_i, reducerasures_i)
    variable abs_soft_x_shift_v : std_logic_vector(INT_LENGTH_CT downto 0);
    variable abs_soft_y_shift_v : std_logic_vector(INT_LENGTH_CT downto 0);
    variable sign_x_v           : std_logic; 
    variable sign_y_v           : std_logic; 
    variable count_v            : std_logic_vector(SHIFT_SOFT_WIDTH_CT -1 downto 0);
  
  begin
    sign_x_v := cormanr_i(MANTLEN_CT) ;
    sign_y_v := cormani_i(MANTLEN_CT) ;

    -- get absolute value
    abs_soft_x_shift_v := SXT(cormanr_i, abs_soft_x_shift_v'length);
    abs_soft_y_shift_v := SXT(cormani_i, abs_soft_y_shift_v'length);
    if sign_x_v = '1' then
      abs_soft_x_shift_v := not(abs_soft_x_shift_v) + '1';
    end if;
    if sign_y_v = '1' then
      abs_soft_y_shift_v := not(abs_soft_y_shift_v) + '1';
    end if;
    
    count_v            := secondexp_i;
    abs_soft_x_shift_v := SHR(SHL(abs_soft_x_shift_v, "1"), count_v);
    abs_soft_y_shift_v := SHR(SHL(abs_soft_y_shift_v, "1"), count_v);
    
    -- saturate
    if abs_soft_x_shift_v > MAX_INTERNAL_CT  then
      abs_soft_x_shift_v := conv_std_logic_vector(MAX_INTERNAL_CT,abs_soft_x_shift_v'length);
    end if;
    if abs_soft_y_shift_v > MAX_INTERNAL_CT then
      abs_soft_y_shift_v := conv_std_logic_vector(MAX_INTERNAL_CT,abs_soft_y_shift_v'length);
    end if;

    -- last shift and round 
    abs_soft_x_shift_v := abs_soft_x_shift_v + reducerasures_i + '1';
    abs_soft_y_shift_v := abs_soft_y_shift_v + reducerasures_i + '1';
    abs_soft_x_shift_v := SHR(abs_soft_x_shift_v, "10");
    abs_soft_y_shift_v := SHR(abs_soft_y_shift_v, "10");

    -- come back to the original sign
    if sign_x_v = '1' then -- negative
      abs_soft_x_shift_v := not(abs_soft_x_shift_v) + '1';
    end if;
    if sign_y_v = '1' then -- negative
      abs_soft_y_shift_v := not(abs_soft_y_shift_v) + '1';
    end if;

    soft_x0_d <= abs_soft_x_shift_v(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y0_d <= abs_soft_y_shift_v(SOFTBIT_WIDTH_CT-1 downto 0);
  end process soft_x0_p;


  ------------------------------------------
  -- Sequential part stage 0
  ------------------------------------------
  seq_p: process( reset_n, clk )
    begin
    if reset_n = '0' then
      cormanr_o         <= (others =>'0');
      cormani_o         <= (others =>'0');
      hpowman_o         <= (others =>'0');
      secondexp_o       <= (others =>'0');
      soft_x0_tmp       <= (others =>'0');
      soft_y0_tmp       <= (others =>'0');
      data_valid_o      <= '0';
      start_of_symbol_o <= '0';
      start_of_burst_o  <= '0';
      qam_mode_o        <= BPSK_CT;
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then 
        data_valid_o       <= '0';
        start_of_symbol_o  <= '0';
        start_of_burst_o   <= '0';
        qam_mode_o         <= BPSK_CT;
      elsif module_enable_i = '1' then 
        if data_valid_i  = '1' then
          cormanr_o    <= cormanr_i;
          cormani_o    <= cormani_i;
          hpowman_o    <= hpowman_i;
          secondexp_o  <= secondexp_i;
          qam_mode_o   <= qam_mode_i;
          soft_x0_tmp  <= soft_x0_d;
          soft_y0_tmp  <= soft_y0_d;
          data_valid_o <= '1';
        else
          data_valid_o <= '0';
        end if;

        if start_of_symbol_i = '1' then
          start_of_symbol_o <= '1';
        else
          start_of_symbol_o <= '0';
        end if;
      
        if start_of_burst_i = '1' then
          start_of_burst_o <= '1';
        else
          start_of_burst_o <= '0';
        end if;

      end if;
    end if;
  end process seq_p;

  -- dummy assignment
  soft_x0_o  <= soft_x0_tmp;
  soft_y0_o  <= soft_y0_tmp;

end rtl;
