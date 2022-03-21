

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of wie_mem is

  signal wie_coeff_data_valid      : std_logic;
  signal wie_coeff_data_ready      : std_logic;
  signal wie_coeff_rd_ptr          : std_logic_vector(5 downto 0);
  signal wie_coeff_wr_ptr          : std_logic_vector(5 downto 0);
  signal wie_coeff_wr_ptr_enable   : std_logic;
  signal i_wie_coeff_table         : WIE_COEFF_ARRAY_T;
  signal q_wie_coeff_table         : WIE_COEFF_ARRAY_T;
  signal pilot_ready_flag          : std_logic;
  signal start_of_symbol_flag      : std_logic;
  signal pilot_ready_o_s           : std_logic;
begin

  data_ready_o  <= '1';
  pilot_ready_o <= pilot_ready_o_s;
  
  --------------------------------------------
  -- This process stores the 52 wiener filter coeffs.
  -- The coeffs are indexed from 0 to 51 for carriers
  -- -26 to 26 (DC is not provided).
  --
  -- -26  -21       -7    -1 1     7      21   26
  --  |----|--------|-----|--|-----|------|----|
  --  0    5        19    25 26   32      46   51
  --
  -- There are 48 data coeffs and 4 pilots coeffs.
  --------------------------------------------
  store_wiener_coeff_p : process(reset_n, clk)
  begin
    if (reset_n = '0') then
      wie_coeff_wr_ptr        <= (others => '0');
      i_wie_coeff_table       <= (others => (others => '0'));
      q_wie_coeff_table       <= (others => (others => '0'));
      wie_coeff_wr_ptr_enable <= '0';
      pilot_ready_o_s         <= '0';
      start_of_symbol_o       <= '0';
      pilot_ready_flag        <= '0';
    elsif (clk'event and clk = '1') then
      if sync_reset_n = '0' then
        wie_coeff_wr_ptr_enable <= '0';
        pilot_ready_o_s         <= '0';
        start_of_symbol_o       <= '0';
        pilot_ready_flag        <= '0';
      else
        pilot_ready_o_s   <= '0';
        start_of_symbol_o <= '0';
        if (start_of_burst_i = '1') then
          pilot_ready_flag <= '0';
        end if;
        -- enable address counter on start symbol
        if (start_of_symbol_i = '1') then
          start_of_symbol_o       <= '1';
          wie_coeff_wr_ptr        <= (others => '0');
          if pilot_ready_flag = '0' then
            wie_coeff_wr_ptr_enable <= '1';
          end if;
        end if;
        if (wie_coeff_wr_ptr_enable = '1') and (data_valid_i = '1') then
          -- store coeffs
          i_wie_coeff_table(conv_integer(wie_coeff_wr_ptr)) <= i_i;
          q_wie_coeff_table(conv_integer(wie_coeff_wr_ptr)) <= q_i;
          -- increment write pointer
          wie_coeff_wr_ptr <= wie_coeff_wr_ptr + '1';
          -- stop address counter when the 48 + 4 coeffs have been stored
          if (wie_coeff_wr_ptr = conv_std_logic_vector(51,6)) then
            wie_coeff_wr_ptr_enable <= '0';
            wie_coeff_wr_ptr        <= (others => '0');
          end if;
          -- when last pilot coeff has been written (carrier 21),
          -- the pilot_tracking is triggered
          -- This is only performed for the first symbol of a burst,
          -- i.e. for the signal field.
          if (wie_coeff_wr_ptr = conv_std_logic_vector(46,6)) and
             (pilot_ready_flag = '0') then
            pilot_ready_o_s  <= '1';
            pilot_ready_flag <= '1';
          end if;
        end if;
      end if;
    end if;
  end process store_wiener_coeff_p;
  
  --------------------------------------------
  -- This process send the wiener coeffs to the
  -- equalizer.
  --------------------------------------------
  read_wiener_coeff_p : process(reset_n, clk)
  begin
    if (reset_n = '0') then
      wie_coeff_rd_ptr     <= (others => '0');
      i_o                  <= (others => '0');
      q_o                  <= (others => '0');
      data_valid_o         <= '0';
      wie_coeff_data_valid <= '0';
      start_of_symbol_flag <= '0';
    elsif (clk'event and clk = '1') then
      if sync_reset_n = '0' then
        wie_coeff_rd_ptr     <= (others => '0');
        data_valid_o         <= '0';
        wie_coeff_data_valid <= '0';
        start_of_symbol_flag <= '0';
      else
        
        data_valid_o <= wie_coeff_data_valid;

        if ((start_of_symbol_flag = '1') and (wie_coeff_data_valid = '0') and
           (pilot_ready_flag = '1')) or (pilot_ready_o_s = '1')then
          wie_coeff_rd_ptr     <= conv_std_logic_vector(0, 6);
          wie_coeff_data_valid <= '1';
          start_of_symbol_flag <= '0';
        end if;
        if (start_of_symbol_i = '1') then
          start_of_symbol_flag <= '1';
        end if;
        if (data_ready_i = '1') and (wie_coeff_data_valid = '1') and
           (pilot_ready_flag = '1') then
          i_o      <= i_wie_coeff_table(conv_integer(wie_coeff_rd_ptr));
          q_o      <= q_wie_coeff_table(conv_integer(wie_coeff_rd_ptr));
        
          case conv_integer(wie_coeff_rd_ptr) is
            -- skip pilot -21
            when 4 =>
              wie_coeff_rd_ptr     <= conv_std_logic_vector(6, 6);
            -- skip pilot -7
            when 18 =>
              wie_coeff_rd_ptr     <= conv_std_logic_vector(20, 6);
            -- skip pilot 7
            when 31 =>
              wie_coeff_rd_ptr     <= conv_std_logic_vector(33, 6);
            -- skip pilot 21
            when 45 =>
              wie_coeff_rd_ptr     <= conv_std_logic_vector(47, 6);
            -- last coeff
            when 51 =>
              wie_coeff_rd_ptr     <= conv_std_logic_vector(0, 6);
              wie_coeff_data_valid <= '0';
            when others =>
              if (wie_coeff_data_valid <= '1') then
                wie_coeff_rd_ptr     <= wie_coeff_rd_ptr + '1';
              end if;
          end case;
        end if;
      end if;
    end if;
  end process read_wiener_coeff_p;

  --data_valid_o <= wie_coeff_data_valid;

  eq_m21_i_o        <= i_wie_coeff_table(5); 
  eq_m21_q_o        <= q_wie_coeff_table(5); 
  eq_m7_i_o         <= i_wie_coeff_table(19); 
  eq_m7_q_o         <= q_wie_coeff_table(19); 
  eq_p7_i_o         <= i_wie_coeff_table(32); 
  eq_p7_q_o         <= q_wie_coeff_table(32); 
  eq_p21_i_o        <= i_wie_coeff_table(46); 
  eq_p21_q_o        <= q_wie_coeff_table(46); 

end rtl;
