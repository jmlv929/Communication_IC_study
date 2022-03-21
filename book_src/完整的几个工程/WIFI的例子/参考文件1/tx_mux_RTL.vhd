

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of tx_mux is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type MUX_STATE_T is (mux_begin_state,
                       mux_preamble_state,
                       mux_data_state,
                       mux_end_state);

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- number of null data sent at the begining of a preamble, + 1 because
  -- ready_cnt counts one time before the beginning of the tx.
  constant NB_NULL_BEGIN_CT : std_logic_vector(7 downto 0) := "00000011";

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Signals for the mux state machine.
  signal mux_state_cur      : MUX_STATE_T;
  signal mux_state_next     : MUX_STATE_T;
  -- Signals to save 'start of burst' when sending NB_NULL_BEGIN_CT null data.
  signal start_burst_sav    : std_logic;
  signal start_burst_sav_rs : std_logic;
  -- Signals to count null data sent at the beginning and the end of tx.
  signal null_cnt           : std_logic_vector(7 downto 0);
  signal null_cnt_rs        : std_logic_vector(7 downto 0);
  -- Signals for a 20 MHz counter. Replace the data_ready_i from the tx_filter.
  signal ready_cnt          : std_logic_vector(1 downto 0);
  signal ready_cnt_rs       : std_logic_vector(1 downto 0);
  -- Signals toggling with each output data for the tx filter.
  signal filter_sampleready     : std_logic;
  signal filter_sampleready_rs  : std_logic;
  -- Signal of synchronisation for the tx filter.
  signal start_burst_ff1        : std_logic;
  signal start_burst_ff2        : std_logic;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  
  --------------------------------------------
  -- Mux state machine
  --------------------------------------------
  
  -- Combinational process for the state machine.
  mux_fsm_comb_p : process (end_preamble_i, marker_i, mux_state_cur,
                            null_cnt_rs, ready_cnt_rs, start_burst_sav_rs)
  begin
    mux_state_next <= mux_state_cur;

    case mux_state_cur is

      -- Go to preamble state when NB_NULL_BEGIN_CT null carriers sent.
      when mux_begin_state =>
        if start_burst_sav_rs = '1' and ready_cnt_rs = "00"
                                    and null_cnt_rs = "00000000" then
          mux_state_next  <= mux_preamble_state;
        end if;

      -- Go to data state when 'end of preamble' received.
      when mux_preamble_state =>
        if end_preamble_i = '1' then
          mux_state_next <= mux_data_state;
        end if;

      -- Go to end state when 'end of burst' marker received.
      when mux_data_state =>
        if ready_cnt_rs = "00" and marker_i = '1' then
          mux_state_next <= mux_end_state;
        end if;

      -- End transmission after dac on/off delay.
      when mux_end_state =>
        if ready_cnt_rs = "00" and null_cnt_rs = "00000000" then
          mux_state_next <= mux_begin_state;
        end if;

      when others => null;
    end case;
  end process mux_fsm_comb_p;

  -- Sequential process for the state machine.
  mux_fsm_seq_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      mux_state_cur <= mux_begin_state;
    elsif clk'event and clk = '1' then
      if enable_i = '0' then
        mux_state_cur <= mux_begin_state;
      else
        mux_state_cur <= mux_state_next;
      end if;
    end if;
  end process mux_fsm_seq_p;


  --------------------------------------------
  -- tx_mux controls
  --------------------------------------------
  
  mux_p : process (data_in_i, data_in_q, tx_enddel_i,
                   filter_sampleready_rs, marker_i, mux_state_cur, null_cnt_rs,
                   preamble_in_i, preamble_in_q, ready_cnt_rs, start_burst_i,
                   start_burst_sav_rs)
  begin
    -- Save start_burst_i.
    start_burst_sav     <= start_burst_sav_rs or start_burst_i;
    null_cnt            <= null_cnt_rs;
    pream_ready_o       <= '0';
    data_ready_o        <= '0';
    data_valid_o        <= '0';
    out_i               <= (others => '0');
    out_q               <= (others => '0');
    tx_start_end_conf_o <= '0';
    ready_cnt           <= ready_cnt_rs;
    filter_sampleready  <= filter_sampleready_rs;

    case mux_state_cur is

      when mux_begin_state =>
        filter_sampleready <= '0';
        -- Start of tx received.
        if start_burst_sav_rs = '1' then
          ready_cnt    <= ready_cnt_rs + 1;
          data_valid_o <= '1';
          if ready_cnt_rs = "00" then
            -- Count down NB_NULL_CNT_CT null data.
            if null_cnt_rs = "00000000" then
              start_burst_sav <= '0';
              filter_sampleready <= not(filter_sampleready_rs);-- To toggle when going to mux_preamble_state,             
            else                                               -- so the first preamble data will not be missed.
              null_cnt <= null_cnt_rs - 1;
            end if;
          end if;
        else
          ready_cnt <= (others => '0');
        end if;

      when mux_preamble_state =>
        ready_cnt <= ready_cnt_rs + 1;
        if ready_cnt_rs = "00" then
          filter_sampleready <= not(filter_sampleready_rs);
        end if;
        
        tx_start_end_conf_o <= '1';
        -- Send preamble data on the outputs.
        out_i        <= preamble_in_i;
        out_q        <= preamble_in_q;
        data_valid_o <= '1';
        -- Send data_ready to preamble_gen block.
        if ready_cnt_rs = "00" then
          pream_ready_o <= '1';
        end if;

      when mux_data_state =>
        ready_cnt <= ready_cnt_rs + 1;
        if ready_cnt_rs = "00" and marker_i = '0' then
          filter_sampleready <= not(filter_sampleready_rs);
        end if;

        tx_start_end_conf_o <= '1';
        data_valid_o        <= '1';
        -- Send TX data on the outputs.
        out_i               <= data_in_i;
        out_q               <= data_in_q;
        -- Send data_ready_o at 20 MHz.
        if ready_cnt_rs = "00" then
          data_ready_o <= '1';
          -- Prepare counter for end state.
          if marker_i = '1' then
            null_cnt   <= tx_enddel_i;
          end if;
        end if;

      when mux_end_state =>
        ready_cnt <= ready_cnt_rs + 1;
        filter_sampleready  <= '0';
        tx_start_end_conf_o <= '1';
        data_valid_o        <= '1';
        if ready_cnt_rs = "00" then
          -- Send tx_enddel_i null data.
          if null_cnt_rs = "00000000" then
            -- Prepare counter for begin state.
            null_cnt <= NB_NULL_BEGIN_CT;
          else
            null_cnt <= null_cnt_rs - 1;
          end if;
        end if;

      when others => null;
    end case;
  end process mux_p;

  
  --------------------------------------------
  -- Registers
  --------------------------------------------
  registers : process (clk, reset_n)
  begin
    if reset_n = '0' then
      start_burst_sav_rs    <= '0';
      null_cnt_rs           <= NB_NULL_BEGIN_CT;
      filter_sampleready_rs <= '0';
      ready_cnt_rs          <= (others => '0');
      start_burst_ff1       <= '0';
      start_burst_ff2       <= '0';
    elsif clk'event and clk = '1' then
      if enable_i = '0' then
        start_burst_sav_rs    <= '0';
        null_cnt_rs           <= NB_NULL_BEGIN_CT;
        filter_sampleready_rs <= '0';
        ready_cnt_rs          <= (others => '0');
        start_burst_ff1       <= '0';
        start_burst_ff2       <= '0';
      else
        start_burst_ff1       <= start_burst_i;
        start_burst_ff2       <= start_burst_ff1;
        start_burst_sav_rs    <= start_burst_sav;
        null_cnt_rs           <= null_cnt;
        filter_sampleready_rs <= filter_sampleready;
        ready_cnt_rs          <= ready_cnt;
      end if;
    end if;
  end process registers;

  -- Assign output ports.
  res_intfil_o         <= start_burst_ff1 or start_burst_ff2;
  filter_sampleready_o <= filter_sampleready_rs;
  

end RTL;
