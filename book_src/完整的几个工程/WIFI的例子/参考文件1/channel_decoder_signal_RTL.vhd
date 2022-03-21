

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of channel_decoder_signal is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal data            : std_logic;   
  signal signal_field    : std_logic_vector(SIGNAL_FIELD_LENGTH_CT-1 downto 0);
  signal data_valid      : std_logic;
  signal enable_datapath : std_logic;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  signal_control_1 : signal_control
    port map (
      -- Clock & Reset Interface
      reset_n        => reset_n,          -- Async Reset
      clk            => clk,              -- Clock
      sync_reset_n   => sync_reset_n,     -- Software reset
      -- Symbol Strobe
      enable_i       => enable_i,         -- Enable signal for FSM
      enable_o       => enable_datapath,  -- Enable signal for Datapath
      data_valid_i   => data_valid_i,     -- Data Valid signal for input
      data_valid_o   => data_valid, -- Data Valid signal for following block
      -- Data Interface
      start_signal_field_i => start_field_i,   -- resets
      end_field_i          => end_field_i      -- marks end of field
      );


  signal_datapath_1 : signal_datapath
    port map (
      -- Clock & Reset Interface
      reset_n        => reset_n,         -- Async Reset
      clk            => clk,             -- Clock
      sync_reset_n   => sync_reset_n,    -- Software reset
      -- Symbol Strobe
      enable_i       => enable_datapath, -- Enable signal from FSM
      -- Data Interface
      data_i         => data,            -- data from Viterbi 
      signal_field_o => signal_field     -- signal field
      );


  --------------------------------------
  -- Register input data process
  --------------------------------------
  register_input_data_p : process (clk, reset_n)
  begin 
    if reset_n = '0' then               -- asynchronous reset (active low)
      data <= '0';  
    elsif clk'event and clk = '1' then  -- rising clock edge
      if enable_i = '1' and data_valid_i = '1' then
        data <= data_i;
      end if;    
    end if;
  end process register_input_data_p;


  --------------------------------------
  -- Register signalfield valid process
  --------------------------------------
  register_signalfield_valid_p : process (clk, reset_n)
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
      data_valid_o <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if enable_i = '1' then
        data_valid_o <= data_valid;
      end if;    
    end if;
  end process register_signalfield_valid_p;

  --------------------------------------
  -- Register output ports process
  --------------------------------------
  register_output_ports_p : process (clk, reset_n)
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
      signal_field_o       <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if enable_i = '1' and data_valid = '1' then
        signal_field_o       <= signal_field;
      end if;
    end if;
  end process register_output_ports_p;


end RTL;
