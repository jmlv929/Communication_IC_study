
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of rx_equ_outstage2 is

  constant MAX_INTERNAL_CT  : integer  := MAX_SOFTBIT_CT * 4 - 1; --59
  -- one more bit to be able to contain -(-512)
  -- a second more bit to be able to do one SHL
  constant INT_LENGTH_CT    : integer  := MANTLEN_CT + 2; 

  signal cormanr_d     : std_logic_vector(MANTLEN_CT         downto 0);
  signal cormani_d     : std_logic_vector(MANTLEN_CT         downto 0);
  signal soft_x2_d     : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_x2_tmp   : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y2_d     : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y2_tmp   : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);

begin

  -------------------------------------------------------------------
  ---                    STAGE 2 
  -------------------------------------------------------------------

  --------------------------------------
  -- CorMan calculation
  --------------------------------------

  corman_p : process (cormanr_i, cormani_i, hpowman_i, qam_mode_i)
    variable hpowman_ext  : std_logic_vector(hpowman_i'high+7 downto 0);
    variable mult_v       : std_logic_vector(hpowman_i'high-1 downto 0);
    variable mult_temp1_v : std_logic_vector(hpowman_i'high+7 downto 0);
    variable mult_temp2_v : std_logic_vector(hpowman_i'high downto 0);
    -- cormani and cormanr extended length
    variable cormani_v    : std_logic_vector(MANTLEN_CT + 1 downto 0);
    variable cormanr_v    : std_logic_vector(MANTLEN_CT + 1 downto 0);
  begin
    -- zero extention
    hpowman_ext := EXT(hpowman_i, hpowman_ext'length);
    -- mult_v := conv_unsigned (SHR ( (SHR ( (hpowman_int * conv_unsigned(scaling2_c,8)) ,"111")  +1), "01"),hpowman_int'high + 1 );
    -- hpowman_i is multiplied by a scaling factor which is 79
    -- mult_temp1_v = hpowman_i * 79 
    --              = hpowman_i * (1+2+4+8+64);
    -- The multiplication is decomposed in shifts and additions.
    mult_temp1_v := (hpowman_ext + 
                     (hpowman_ext(hpowman_ext'high-1 downto 0) & '0')) +
                    ((hpowman_ext(hpowman_ext'high-2 downto 0) & "00") +
                     (hpowman_ext(hpowman_ext'high-3 downto 0) & "000")) +
                    (hpowman_ext(hpowman_ext'high-6 downto 0) & "000000");
                    
    -- divide by 128 and add 1
    mult_temp2_v := mult_temp1_v(mult_temp1_v'high downto 7) + '1';
    -- divide by 2
    mult_v := mult_temp2_v(mult_temp2_v'high downto 1);
    
    if (qam_mode_i = QAM64_CT) then
      -- if positive, convert to negative
      if (cormani_i(cormani_i'high)) = '0' then
        cormani_v := not(SXT(cormani_i, cormani_v'length)) + '1';
      else
        cormani_v := SXT(cormani_i, cormani_v'length);
      end if;
      -- if positive, convert to negative
      if (cormanr_i(cormanr_i'high)) = '0' then
        cormanr_v := not(SXT(cormanr_i, cormanr_v'length)) + '1';
      else
        cormanr_v := SXT(cormanr_i, cormanr_v'length);
      end if;
      -- cormani_v = mult_v - abs(cormani_i)
      cormani_v := SXT(mult_v,cormani_v'length) + cormani_v;
      -- cormanr_v = mult_v - abs(cormanr_i)
      cormanr_v := SXT(mult_v,cormanr_v'length) + cormanr_v;
    else
      cormani_v := (others => '0');
      cormanr_v := (others => '0');
    end if;

    -- check overflow
    -- if cormani_v > 1023 we saturate to 1023
    if (cormani_v(11 downto 10) = "01") then
       cormani_d  <= conv_std_logic_vector(MAX_MANTISSE_CT, MANTLEN_CT + 1);
    -- if cormani_v < -1024 we saturate to -1024
    elsif (cormani_v(11 downto 10) = "10") then
       cormani_d  <= conv_std_logic_vector(MIN_MANTISSE_CT, MANTLEN_CT + 1);
    else --regular case, just skip the useless msb's
       cormani_d <= cormani_v(MANTLEN_CT downto 0);
    end if;

    -- check overflow
    -- if cormanr_v > 1023 we saturate to 1023
    if (cormanr_v(11 downto 10) = "01") then
       cormanr_d  <= conv_std_logic_vector(MAX_MANTISSE_CT, MANTLEN_CT + 1);
    -- if cormanr_v < -1024 we saturate to -1024
    elsif (cormanr_v(11 downto 10) = "10") then
       cormanr_d  <= conv_std_logic_vector(MIN_MANTISSE_CT, MANTLEN_CT + 1);
    else --regular case, just skip the useless msb
       cormanr_d <= cormanr_v(MANTLEN_CT downto 0);
    end if;
  end process corman_p;
   
   
  --------------------------------------
  -- SoftX2 compression (barrel shifter)
  --------------------------------------
  soft_x2_p: process (cormanr_d, cormani_d, secondexp_i, reducerasures_i)
    variable abs_soft_x_shift_v : std_logic_vector(INT_LENGTH_CT downto 0);
    variable abs_soft_y_shift_v : std_logic_vector(INT_LENGTH_CT downto 0);
    variable sign_x_v           : std_logic; 
    variable sign_y_v           : std_logic; 
    variable count_v            : std_logic_vector(SHIFT_SOFT_WIDTH_CT -1 downto 0);
  begin
    sign_x_v := cormanr_d(MANTLEN_CT);
    sign_y_v := cormani_d(MANTLEN_CT);

    -- get absolute value
    abs_soft_x_shift_v := SXT(cormanr_d,abs_soft_x_shift_v'length);
    abs_soft_y_shift_v := SXT(cormani_d,abs_soft_y_shift_v'length);
    if sign_x_v ='1' then
      abs_soft_x_shift_v := not(abs_soft_x_shift_v) + '1';
    end if;
    if sign_y_v ='1' then
      abs_soft_y_shift_v := not(abs_soft_y_shift_v) + '1';
    end if;

    count_v            := secondexp_i;
    abs_soft_x_shift_v := SHR(SHL(abs_soft_x_shift_v, "1"), count_v);
    abs_soft_y_shift_v := SHR(SHL(abs_soft_y_shift_v, "1"), count_v);
    
    -- saturate to MANTLEN_CT
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

    soft_x2_d <= abs_soft_x_shift_v(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y2_d <= abs_soft_y_shift_v(SOFTBIT_WIDTH_CT-1 downto 0);

  end process soft_x2_p;



  ------------------------------------------
  -- Sequential part stage 2
  ------------------------------------------
  seq_p: process( reset_n, clk )
  begin
    if reset_n='0' then
      soft_x0_o         <= (others =>'0');
      soft_x1_o         <= (others =>'0');
      soft_y0_o         <= (others =>'0');
      soft_y1_o         <= (others =>'0');
      soft_x2_tmp       <= (others =>'0');
      soft_y2_tmp       <= (others =>'0');
      data_valid_o      <= '0';
      start_of_symbol_o <= '0';
      start_of_burst_o  <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then 
        data_valid_o       <= '0';
        start_of_symbol_o  <='0';
        start_of_burst_o   <='0';
      elsif module_enable_i = '1' then 
        if data_valid_i = '1' then
          soft_x0_o    <= soft_x0_i;
          soft_y0_o    <= soft_y0_i;
          soft_y1_o    <= soft_y1_i;
          soft_x1_o    <= soft_x1_i;
          soft_y2_tmp  <= soft_y2_d;
          soft_x2_tmp  <= soft_x2_d;
          data_valid_o <= '1';
        else
          data_valid_o  <= '0';
        end if;

        if start_of_symbol_i  = '1' then
          start_of_symbol_o  <='1';
        else
          start_of_symbol_o  <='0';
        end if;

        if start_of_burst_i  = '1' then
          start_of_burst_o  <='1';
        else
          start_of_burst_o  <='0';
        end if;

      end if;
    end if;
  end process seq_p;


-- dummy assignment
  soft_x2_o  <= soft_x2_tmp;
  soft_y2_o  <= soft_y2_tmp;

end rtl;
