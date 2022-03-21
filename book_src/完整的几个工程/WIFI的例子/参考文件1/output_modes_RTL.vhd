

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of output_modes is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type   FSM_STATE_TYPE is (idle,            -- wait for the 1st symbol
                            symbol );        -- symbol is transmitted
  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant CNT_MAX63_CT : std_logic_vector (5 downto 0) := "111111"; --63d
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- SM
  signal out_modes_cur_state  : FSM_STATE_TYPE; 
  signal out_modes_next_state : FSM_STATE_TYPE; 
  -- Counter
  signal cnt64                : std_logic_vector(5 downto 0); -- 0 -> 63d
  -- Control Signals
  signal start_of_burst       : std_logic;
  signal start_of_symbol      : std_logic;
  signal data_valid           : std_logic;
  signal data_ready           : std_logic;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- States Machines
  -----------------------------------------------------------------------------
  om_sm_p : process (data_valid_i, out_modes_cur_state)
  begin  -- process fsm_p
    case out_modes_cur_state is

      -- wait for T1 (1st symbol)
      when idle =>
        if data_valid_i = '1' then
          out_modes_next_state <= symbol;
        else
          out_modes_next_state <= idle;
        end if;

      -- symbol is transmitted: count 64 then next symbol
      when symbol =>
          out_modes_next_state <= symbol; -- stay in symbol state until the end of rx
          
      when others =>
        out_modes_next_state <= idle;        
    end case;
  end process om_sm_p;

  -- sequential part
  om_sm_seq_p : process (clk, reset_n)
  begin  -- process reg_p
    if reset_n = '0' then                 -- asynchronous reset (active low)
      out_modes_cur_state <= idle;
    elsif clk'event and clk = '1' then  -- rising clock edge
      if init_i = '1' then
        out_modes_cur_state <= idle;
      else
        out_modes_cur_state <= out_modes_next_state;
      end if;
    end if;
  end process om_sm_seq_p;

  -----------------------------------------------------------------------------
  -- Counter
  -----------------------------------------------------------------------------
  om_count_p : process (clk, reset_n)
  begin  -- process reg_p
    if reset_n = '0' then                 -- asynchronous reset (active low)
      cnt64    <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
        if init_i = '1' then
          cnt64    <= (others => '0');
        elsif data_ready = '1' and data_valid = '1' then
        -- 1 data has been transfered to freq_corr
          cnt64 <= cnt64 + '1';  -- when 63 -> 0 automatically          
        end if;
    end if;
  end process om_count_p;

  -----------------------------------------------------------------------------
  -- Control Signals
  -----------------------------------------------------------------------------
  om_ctrl_p : process (clk, reset_n)
  begin  -- process reg_out
    if reset_n = '0' then               -- asynchronous reset (active low)
      data_valid         <= '0';
      start_of_burst     <= '0';
      start_of_symbol    <= '0';
      i_o                <= (others => '0');
      q_o                <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      start_of_burst  <= '0';
      
      if init_i = '1' then
        -- init signals
        data_valid        <= '0';
        start_of_symbol   <= '0';
        
      elsif out_modes_cur_state = idle and out_modes_next_state = symbol then
       -- start_of_burst = '1' when leaving idle state
        start_of_burst    <= '1';

      elsif data_ready_i = '1' then
        start_of_symbol   <= '0';       
        if data_ready = '1' and data_valid = '1' and cnt64 = CNT_MAX63_CT then
        -- start_of_symbol = '1' when the 64 symbols have been sent
          start_of_symbol      <= '1';
          data_valid           <= '0'; -- new symbol is arriving
        else
          data_valid           <= data_valid_i;
        end if;
      end if;

      -- Register Data
      if data_valid_i = '1' and data_ready = '1' then
        i_o                <= i_i;
        q_o                <= q_i;               
      end if;
    end if;
  end process om_ctrl_p;

  -----------------------------------------------------------------------------
  -- Output Linking
  -----------------------------------------------------------------------------

  start_of_symbol_o <= start_of_symbol;
  start_of_burst_o  <= start_of_burst;
  data_valid_o      <= data_valid;
  

  -- not data should be got from ring_buffer when start_of_symbol.
  data_ready <= '0'
                  when start_of_symbol = '1'
                    or out_modes_cur_state = idle
             else data_ready_i;

  data_ready_o <= data_ready;

end RTL;
