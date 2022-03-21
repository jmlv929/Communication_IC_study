

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of control_filter is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- Division by 3 = 2^-2 + 2^-4 + 2^-6 + 2^-8 + 2^-10
  constant DIV3_CT  : std_logic_vector(10 downto 0) := "00101010101";
  -- Counter limit of DC offset pre-estimation valid (-3 due to FFs delay)
  constant DC_PRE_ESTIM_LIMIT_CT : integer := 39-3;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Tx resync
  signal tx_filter_in_i_resync      : std_logic_vector(size_in_tx_g-1 downto 0);
  signal tx_filter_in_q_resync      : std_logic_vector(size_in_tx_g-1 downto 0);
  -- Start of burst resync
  signal start_of_burst_resync      : std_logic;
  -- Tx sampling to core filter
  signal tx_filter_in_i_samp        : std_logic_vector(size_in_tx_g-1 downto 0);
  signal tx_filter_in_q_samp        : std_logic_vector(size_in_tx_g-1 downto 0);
  -- Rx resync
  signal rx_filter_in_i_resync      : std_logic_vector(size_in_rx_g-1 downto 0);
  signal rx_filter_in_q_resync      : std_logic_vector(size_in_rx_g-1 downto 0);
  -- Rx input register adjusted to core filter
  signal rx_filter_i_reg1_adjust    : std_logic_vector(size_core_in_g-1 downto 0);
  signal rx_filter_q_reg1_adjust    : std_logic_vector(size_core_in_g-1 downto 0);
  -- Sample ready
  -- Tx
  signal sample_ready_toggle_resync : std_logic;
  signal tx_data_toggle_ff1         : std_logic;
  signal tx_data_toggle_ff2         : std_logic;
  signal tx_data_pulse              : std_logic;
  -- Rx
  signal sample_data_rx             : std_logic;
  signal sample_data_shift          : std_logic_vector(2 downto 0);
  signal sample_ready_rx            : std_logic;
  signal sample_toggle_rx           : std_logic;

  -- Clear buffer during transition Tx -> Rx or Rx -> Tx
  signal tx_rx_select_resync        : std_logic;
  signal tx_rx_select_ff1           : std_logic;
  signal clear_buffer               : std_logic;
  
  -- Normalization by coefficient : txnorm for Tx, 0.3333.. for Rx
  signal filter_norm_i              : std_logic_vector((size_core_out_g+12)-1 downto 0); 
  signal filter_norm_q              : std_logic_vector((size_core_out_g+12)-1 downto 0); 
  signal final_coef                 : std_logic_vector(10 downto 0);                     
    
  -- DC Offset pre-estimation counter
  signal dc_pre_estim_count         : std_logic_vector(5 downto 0);
  signal dc_pre_estim_limit         : std_logic_vector(5 downto 0);
  signal d_dc_pre_estim_valid_int   : std_logic;
  signal dc_pre_estim_valid_int     : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- Constant std logic conversion
  dc_pre_estim_limit <= conv_std_logic_vector(DC_PRE_ESTIM_LIMIT_CT,
                        dc_pre_estim_limit'length);

  -- DC Offset pre-estimation data valid output
  dc_pre_estim_valid <= dc_pre_estim_valid_int;

  -- Tx activation output (allow to stop DC pre-estimation)
  tx_active <= tx_rx_select_resync;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------     NO SYNCHRONOUS RESET     ------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  NO_SYNC_RESET_GEN : if use_sync_reset_g = 0 generate
  
  -----------------------------------------------------------------------------
  -- TX data resynchronization
  -----------------------------------------------------------------------------
  tx_data_resync_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      start_of_burst_resync      <= '0';
      sample_ready_toggle_resync <= '0';
      tx_filter_in_i_resync      <= (others => '0');
      tx_filter_in_q_resync      <= (others => '0');
    elsif clk'event and clk = '1' then
      start_of_burst_resync      <= start_of_burst_i;
      sample_ready_toggle_resync <= sample_ready_tx_i;
      tx_filter_in_i_resync      <= tx_filter_in_i;
      tx_filter_in_q_resync      <= tx_filter_in_q;
    end if;
  end process tx_data_resync_p;
  

  -----------------------------------------------------------------------------
  -- Sample ready output to Rx path
  -----------------------------------------------------------------------------
  sample_ready_rx_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      sample_ready_rx  <= '0';
      sample_toggle_rx <= '0';
    elsif clk'event and clk = '1' then
      if tx_rx_select = '1' then
        sample_ready_rx  <= '0';
        sample_toggle_rx <= '0';
      else
        if sample_data_rx = '1' then
          -- for toggle
          sample_toggle_rx <= not sample_toggle_rx;
          -- for pulse
          sample_ready_rx <= '1';
        else
          sample_ready_rx <= '0';
        end if;
      end if;
    end if;
  end process sample_ready_rx_p;
  
  sample_ready_rx_o  <= sample_ready_rx;
  sample_toggle_rx_o <= sample_toggle_rx;
  
  
  -----------------------------------------------------------------------------
  -- Pulse generation for control delay line in Tx
  -----------------------------------------------------------------------------
  tx_data_pulse_gen_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      tx_data_toggle_ff1 <= '0';
      tx_data_toggle_ff2 <= '0';
    elsif clk'event and clk = '1' then
      tx_data_toggle_ff1 <= sample_ready_toggle_resync;
      tx_data_toggle_ff2 <= tx_data_toggle_ff1;
    end if;
  end process tx_data_pulse_gen_p;
  
  tx_data_pulse <= tx_data_toggle_ff1 xor tx_data_toggle_ff2;

  -----------------------------------------------------------------------------
  -- RX data resynchronization
  -----------------------------------------------------------------------------
  rx_data_resync_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      rx_filter_in_i_resync <= (others => '0');
      rx_filter_in_q_resync <= (others => '0');
    elsif clk'event and clk = '1' then
      rx_filter_in_i_resync <= rx_filter_in_i;
      rx_filter_in_q_resync <= rx_filter_in_q;
    end if;
  end process rx_data_resync_p;
    

  -----------------------------------------------------------------------------
  -- Mux data into core for Tx : data .. 0 .. 0 .. data .. 0 .. 0 .. data...
  -----------------------------------------------------------------------------
  tx_filter_in_i_samp <= tx_filter_in_i_resync when tx_data_pulse = '1' else
                         (others => '0');
  
  tx_filter_in_q_samp <= tx_filter_in_q_resync when tx_data_pulse = '1' else
                         (others => '0');
  
  -----------------------------------------------------------------------------
  -- Pulse generation on tx_rx_select :
  -- clear the core during transition Tx -> Rx or Rx -> Tx
  -----------------------------------------------------------------------------
  pulse_clear_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      tx_rx_select_resync <= '0';
      tx_rx_select_ff1    <= '0';
    elsif clk'event and clk = '1' then
      tx_rx_select_resync <= tx_rx_select;  -- resynchronisation to local clock
      tx_rx_select_ff1    <= tx_rx_select_resync;
    end if;
  end process pulse_clear_p;

  -----------------------------------------------------------------------------
  -- Selection Tx/Rx for the Core front-end filter inputs
  -----------------------------------------------------------------------------
  -- Adjust length of data for Rx
  ADJUST_G : for i in (size_core_in_g-1) downto 0 generate
  
    IF1_G : if i < size_core_in_g - size_in_rx_g generate
      
      rx_filter_i_reg1_adjust(i) <= '0';
      rx_filter_q_reg1_adjust(i) <= '0';

    end generate IF1_G;
    
    IF2_G : if i >= size_core_in_g - size_in_rx_g generate
      
      rx_filter_i_reg1_adjust(i) <= rx_filter_in_i_resync(i-(size_core_in_g - size_in_rx_g));
      rx_filter_q_reg1_adjust(i) <= rx_filter_in_q_resync(i-(size_core_in_g - size_in_rx_g));
    
    end generate IF2_G;
  
  end generate ADJUST_G;
  
  
  -------------------
  -- I & Q input core
  -------------------
  data2core_i <= rx_filter_i_reg1_adjust when tx_rx_select_resync = '0' else 
                 tx_filter_in_i_samp;

  data2core_q <= rx_filter_q_reg1_adjust when tx_rx_select_resync = '0' else 
                 tx_filter_in_q_samp;

  
  -----------------------------------------------------------------------------
  -- Filter normalization
  -----------------------------------------------------------------------------
  final_coef <= "000" & txnorm_i when tx_rx_select_resync = '1' else DIV3_CT;
      
  -- Normalization
  filter_norm_i <= signed(data_filtered_i) * unsigned(final_coef);
  filter_norm_q <= signed(data_filtered_q) * unsigned(final_coef);

  -----------------------------------------------------------------------------
  -- Rx Decimation
  -----------------------------------------------------------------------------
  decim_rx_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      sample_data_shift <= "001";
    elsif clk'event and clk = '1' then
      if tx_rx_select_resync = '0' then
        sample_data_shift(2) <= sample_data_shift(0);
        sample_data_shift(1 downto 0) <= sample_data_shift(2 downto 1);
      else
        sample_data_shift <= "001";
      end if;
    end if;
  end process decim_rx_p;
 
  sample_data_rx <= sample_data_shift(0);

  -----------------------------------------------------------------------------
  -- Output assignment
  -----------------------------------------------------------------------------
  -- RX
  rx_out_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      rx_filter_out_i <= (others => '0');
      rx_filter_out_q <= (others => '0');
    elsif clk'event and clk = '1' then
      if tx_rx_select_resync = '0' then
        if sample_data_rx = '1' then
          -- Rounding of the Rx normalization
          rx_filter_out_i <= sat_round_signed_slv(filter_norm_i, 3,
                                            size_core_out_g+9-size_out_rx_g);
          rx_filter_out_q <= sat_round_signed_slv(filter_norm_q, 3, 
                                            size_core_out_g+9-size_out_rx_g);
        end if;
      else
        rx_filter_out_i <= (others => '0');
        rx_filter_out_q <= (others => '0');
      end if;
    end if;
  end process rx_out_p;
  
  
  -- TX
  tx_out_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      tx_filter_out_i <= (others => '0');
      tx_filter_out_q <= (others => '0');
    elsif clk'event and clk = '1' then

      if tx_rx_select_resync = '1' then

        -- Filter by pass
        if filtbyp_tx_i = '1' then
          tx_filter_out_i <= tx_filter_in_i(size_in_tx_g-1 downto 
                                                  size_in_tx_g-size_out_tx_g);
          tx_filter_out_q <= tx_filter_in_q(size_in_tx_g-1 downto
                                                  size_in_tx_g-size_out_tx_g);
        else
--------------------------------------------------------------------------------
-- function sat_round_signed_slv : saturate and round a signed number
-- remove nb_to_rem MSB of sat_signed_slv and saturate the signal if needed by
-- "01111..." (positive numbers) or "1000....." (negative numbers)
--------------------------------------------------------------------------------
          -- TxI outputs saturation
          tx_filter_out_i <= sat_round_signed_slv(filter_norm_i, 
                                         6, size_core_out_g+6 -size_out_tx_g);
          -- TxQ outputs saturation
          tx_filter_out_q <= sat_round_signed_slv(filter_norm_q, 
                                         6, size_core_out_g+6 -size_out_tx_g);
        end if;
      else
        tx_filter_out_i <= (others => '0');
        tx_filter_out_q <= (others => '0');
      end if;
    end if;
  end process tx_out_p;

  -- DC Offset pre-estimation counter seq
  dc_count_seq_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      dc_pre_estim_count <= (others => '0');
      dc_pre_estim_valid_int <= '0';
    elsif clk'event and clk = '1' then
      if tx_rx_select_resync = '0' then
        dc_pre_estim_valid_int <= d_dc_pre_estim_valid_int;
        -- Counter: if reach dc_pre_estim_limit, dc pre-estimation is ready
        if dc_pre_estim_count < dc_pre_estim_limit then
            dc_pre_estim_count <= dc_pre_estim_count + 1;
        end if;
      end if;
    end if;
  end process dc_count_seq_p;
  
  -- DC Offset pre-estimation counter comb
  dc_count_comb_p : process (dc_pre_estim_count, dc_pre_estim_limit, dc_pre_estim_valid_int)
  begin
    d_dc_pre_estim_valid_int <= dc_pre_estim_valid_int;
    -- Counter: if reach dc_pre_estim_limit, dc pre-estimation is ready
    if dc_pre_estim_count < dc_pre_estim_limit then
      d_dc_pre_estim_valid_int <= '0';
    else
      d_dc_pre_estim_valid_int <= '1';
    end if;
  end process dc_count_comb_p;


  -- Unused output
  -- The clear of the core must be done by the reset controller via the reset_n
  -- input pin. The conditions of reset must be the same as synchronous reset
  -- when it is active (Reset FFs when transition Tx->Rx or Rx->Tx and 
  -- start of a Tx burst).
  clear_core <= '0';

  end generate NO_SYNC_RESET_GEN;


  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  ------------------------     SYNCHRONOUS RESET     --------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  SYNC_RESET_GEN : if use_sync_reset_g = 1 generate

  -----------------------------------------------------------------------------
  -- TX data resynchronization
  -----------------------------------------------------------------------------
  tx_data_resync_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      start_of_burst_resync      <= '0';
      sample_ready_toggle_resync <= '0';
      tx_filter_in_i_resync      <= (others => '0');
      tx_filter_in_q_resync      <= (others => '0');
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        start_of_burst_resync      <= '0';
        sample_ready_toggle_resync <= '0';
        tx_filter_in_i_resync      <= (others => '0');
        tx_filter_in_q_resync      <= (others => '0');
      else
        start_of_burst_resync      <= start_of_burst_i;
        sample_ready_toggle_resync <= sample_ready_tx_i;
        tx_filter_in_i_resync      <= tx_filter_in_i;
        tx_filter_in_q_resync      <= tx_filter_in_q;
      end if;
    end if;
  end process tx_data_resync_p;
  

  -----------------------------------------------------------------------------
  -- Sample ready output to Rx path
  -----------------------------------------------------------------------------
  sample_ready_rx_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      sample_ready_rx  <= '0';
      sample_toggle_rx <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        sample_ready_rx  <= '0';
        sample_toggle_rx <= '0';
      else
        if tx_rx_select = '1' then
          sample_ready_rx  <= '0';
          sample_toggle_rx <= '0';
        else
          if sample_data_rx = '1' then
            -- for toggle
            sample_toggle_rx <= not sample_toggle_rx;
            -- for pulse
            sample_ready_rx <= '1';
          else
            sample_ready_rx <= '0';
          end if;
        end if;
      end if;
    end if;
  end process sample_ready_rx_p;
  
  sample_ready_rx_o  <= sample_ready_rx;
  sample_toggle_rx_o <= sample_toggle_rx;
  
  
  -----------------------------------------------------------------------------
  -- Pulse generation for control delay line in Tx
  -----------------------------------------------------------------------------
  tx_data_pulse_gen_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      tx_data_toggle_ff1 <= '0';
      tx_data_toggle_ff2 <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        tx_data_toggle_ff1 <= '0';
        tx_data_toggle_ff2 <= '0';
      else
        tx_data_toggle_ff1 <= sample_ready_toggle_resync;
        tx_data_toggle_ff2 <= tx_data_toggle_ff1;
      end if;
    end if;
  end process tx_data_pulse_gen_p;
  
  tx_data_pulse <= tx_data_toggle_ff1 xor tx_data_toggle_ff2;

  -----------------------------------------------------------------------------
  -- RX data resynchronization
  -----------------------------------------------------------------------------
  rx_data_resync_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      rx_filter_in_i_resync <= (others => '0');
      rx_filter_in_q_resync <= (others => '0');
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        rx_filter_in_i_resync <= (others => '0');
        rx_filter_in_q_resync <= (others => '0');
      else
        rx_filter_in_i_resync <= rx_filter_in_i;
        rx_filter_in_q_resync <= rx_filter_in_q;
      end if;
    end if;
  end process rx_data_resync_p;
    

  -----------------------------------------------------------------------------
  -- Mux data into core for Tx : data .. 0 .. 0 .. data .. 0 .. 0 .. data...
  -----------------------------------------------------------------------------
  tx_filter_in_i_samp <= tx_filter_in_i_resync when tx_data_pulse = '1' else
                         (others => '0');
  
  tx_filter_in_q_samp <= tx_filter_in_q_resync when tx_data_pulse = '1' else
                         (others => '0');
  
  -----------------------------------------------------------------------------
  -- Pulse generation on tx_rx_select :
  -- clear the core during transition Tx -> Rx or Rx -> Tx
  -----------------------------------------------------------------------------
  pulse_clear_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      tx_rx_select_resync <= '0';
      tx_rx_select_ff1    <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        tx_rx_select_resync <= '0';
        tx_rx_select_ff1    <= '0';
      else
        tx_rx_select_resync <= tx_rx_select;  -- resynchronisation to local clock
        tx_rx_select_ff1    <= tx_rx_select_resync;
      end if;
    end if;
  end process pulse_clear_p;

  -- Reset FFs when transition Tx->Rx or Rx->Tx
  clear_buffer <= tx_rx_select_resync xor tx_rx_select_ff1;

  -- Clear core during clear_buffer or sync_reset_n active or start of burst
  clear_core <= clear_buffer or not sync_reset_n or start_of_burst_resync;
  
  -----------------------------------------------------------------------------
  -- Selection Tx/Rx for the Core front-end filter inputs
  -----------------------------------------------------------------------------
  -- Adjust length of data for Rx
  ADJUST_G : for i in (size_core_in_g-1) downto 0 generate
  
    IF1_G : if i < size_core_in_g - size_in_rx_g generate
      
      rx_filter_i_reg1_adjust(i) <= '0';
      rx_filter_q_reg1_adjust(i) <= '0';

    end generate IF1_G;
    
    IF2_G : if i >= size_core_in_g - size_in_rx_g generate
      
      rx_filter_i_reg1_adjust(i) <= rx_filter_in_i_resync(i-(size_core_in_g - size_in_rx_g));
      rx_filter_q_reg1_adjust(i) <= rx_filter_in_q_resync(i-(size_core_in_g - size_in_rx_g));
    
    end generate IF2_G;
  
  end generate ADJUST_G;
  
  
  -------------------
  -- I & Q input core
  -------------------
  data2core_i <= rx_filter_i_reg1_adjust when tx_rx_select_resync = '0' else 
                 tx_filter_in_i_samp;

  data2core_q <= rx_filter_q_reg1_adjust when tx_rx_select_resync = '0' else 
                 tx_filter_in_q_samp;

  
  -----------------------------------------------------------------------------
  -- Filter normalization
  -----------------------------------------------------------------------------
  final_coef <= "000" & txnorm_i when tx_rx_select_resync = '1' else DIV3_CT;
      
  -- Normalization
  filter_norm_i <= signed(data_filtered_i) * unsigned(final_coef);
  filter_norm_q <= signed(data_filtered_q) * unsigned(final_coef);

  -----------------------------------------------------------------------------
  -- Rx Decimation
  -----------------------------------------------------------------------------
  decim_rx_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      sample_data_shift <= "001";
    elsif clk'event and clk = '1' then

      if sync_reset_n = '0' then
        sample_data_shift <= "001";
      else
        if tx_rx_select_resync = '0' then
          sample_data_shift(2) <= sample_data_shift(0);
          sample_data_shift(1 downto 0) <= sample_data_shift(2 downto 1);
        else
          sample_data_shift <= "001";
        end if;
      end if;
    end if;
  end process decim_rx_p;
 
  sample_data_rx <= sample_data_shift(0);

  -----------------------------------------------------------------------------
  -- Output assignment
  -----------------------------------------------------------------------------
  -- RX
  rx_out_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      rx_filter_out_i <= (others => '0');
      rx_filter_out_q <= (others => '0');
    elsif clk'event and clk = '1' then

      if sync_reset_n = '0' then
        rx_filter_out_i <= (others => '0');
        rx_filter_out_q <= (others => '0');
      else
        if tx_rx_select_resync = '0' then
          
          if sample_data_rx = '1' then
            
            -- Rounding of the Rx normalization
            rx_filter_out_i <= sat_round_signed_slv(filter_norm_i, 3,
                                              size_core_out_g+9-size_out_rx_g);
            rx_filter_out_q <= sat_round_signed_slv(filter_norm_q, 3, 
                                              size_core_out_g+9-size_out_rx_g);
          end if;
        else
          rx_filter_out_i <= (others => '0');
          rx_filter_out_q <= (others => '0');
        end if;
      end if;
    end if;
  end process rx_out_p;
  
  
  -- TX
  tx_out_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      tx_filter_out_i <= (others => '0');
      tx_filter_out_q <= (others => '0');
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        tx_filter_out_i <= (others => '0');
        tx_filter_out_q <= (others => '0');
      else
        if tx_rx_select_resync = '1' then

          -- Filter by pass
          if filtbyp_tx_i = '1' then
          
            tx_filter_out_i <= tx_filter_in_i(size_in_tx_g-1 downto 
                                                    size_in_tx_g-size_out_tx_g);
            tx_filter_out_q <= tx_filter_in_q(size_in_tx_g-1 downto
                                                    size_in_tx_g-size_out_tx_g);

          else
          
--------------------------------------------------------------------------------
-- function sat_round_signed_slv : saturate and round a signed number
-- remove nb_to_rem MSB of sat_signed_slv and saturate the signal if needed by
-- "01111..." (positive numbers) or "1000....." (negative numbers)
--------------------------------------------------------------------------------

            -- TxI outputs saturation
            tx_filter_out_i <= sat_round_signed_slv(filter_norm_i, 
                                           6, size_core_out_g+6 -size_out_tx_g);

            -- TxQ outputs saturation
            tx_filter_out_q <= sat_round_signed_slv(filter_norm_q, 
                                           6, size_core_out_g+6 -size_out_tx_g);

          end if;
        else
          tx_filter_out_i <= (others => '0');
          tx_filter_out_q <= (others => '0');
        end if;
      end if;
    end if;
  end process tx_out_p;

  -- DC Offset pre-estimation counter seq
  dc_count_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      dc_pre_estim_count     <= (others => '0');
      dc_pre_estim_valid_int <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        dc_pre_estim_count     <= (others => '0');
        dc_pre_estim_valid_int <= '0';
      else
        if tx_rx_select_resync = '0' then
          dc_pre_estim_valid_int <= d_dc_pre_estim_valid_int;
          -- Counter: if reach dc_pre_estim_limit, dc pre-estimation is ready
          if dc_pre_estim_count < dc_pre_estim_limit then
              dc_pre_estim_count <= dc_pre_estim_count + 1;
          end if;
        end if;
      end if;
    end if;
  end process dc_count_p;

  
  -- DC Offset pre-estimation counter comb
  dc_count_comb_p : process (dc_pre_estim_count, dc_pre_estim_limit, dc_pre_estim_valid_int)
  begin
    d_dc_pre_estim_valid_int <= dc_pre_estim_valid_int;
    -- Counter: if reach dc_pre_estim_limit, dc pre-estimation is ready
    if dc_pre_estim_count < dc_pre_estim_limit then
      d_dc_pre_estim_valid_int <= '0';
    else
      d_dc_pre_estim_valid_int <= '1';
    end if;
  end process dc_count_comb_p;


  end generate SYNC_RESET_GEN;



end RTL;
