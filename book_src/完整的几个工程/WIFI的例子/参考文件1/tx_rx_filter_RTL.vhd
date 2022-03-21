

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of tx_rx_filter is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
 
  -- I & Q before Core front-end filter
  signal core_input_i : std_logic_vector(size_core_in_g-1 downto 0);
  signal core_input_q : std_logic_vector(size_core_in_g-1 downto 0);
  
  -- I & Q after Core front-end filter
  signal core_output_i : std_logic_vector(size_core_out_g-1 downto 0);
  signal core_output_q : std_logic_vector(size_core_out_g-1 downto 0);
  
  -- Clear core during transition Tx -> Rx or Rx -> Tx or sync_reset_n active
  signal clear_core    : std_logic;
  
  -- Dc Offset pre-estimation valid (seq)
  signal dc_pre_estim_valid_int : std_logic;
  signal tx_active              : std_logic;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- Control filter instanciation
  -----------------------------------------------------------------------------
  control_filter_1 : control_filter
  generic map ( 
    size_in_tx_g     => size_in_tx_g,      -- I & Q size for Tx input
    size_out_tx_g    => size_out_tx_g,     -- I & Q size for Tx output
    size_in_rx_g     => size_in_rx_g,      -- I & Q size for Tx input
    size_out_rx_g    => size_out_rx_g,     -- I & Q size for Rx output
    size_core_in_g   => size_core_in_g,    -- size for Core front-end input
    size_core_out_g  => size_core_out_g,   -- size for Core front-end output
--    use_sync_reset_g => use_sync_reset_g   -- use of synchronous reset
    use_sync_reset_g => use_sync_reset_g   -- use of synchronous reset
    )
  port map(
    -- Clock and reset
    clk                => clk,
    reset_n            => reset_n,
    sync_reset_n       => sync_reset_n,
    -- Tx/Rx selection
    tx_rx_select       => tx_rx_select,
    -- Filter bypass
    filtbyp_tx_i       => filtbyp_tx_i,
    -- Rx
    -- From dc_offset : 60 MS/s
    rx_filter_in_i     => rx_filter_in_i,
    rx_filter_in_q     => rx_filter_in_q,
    -- To Rx path : 20 MS/s
    rx_filter_out_i    => rx_filter_out_i,
    rx_filter_out_q    => rx_filter_out_q,
    -- Tx
    -- From Tx path : 20 MS/s
    tx_filter_in_i     => tx_filter_in_i,
    tx_filter_in_q     => tx_filter_in_q,
    -- To iq_compensation : 60 MS/s
    tx_filter_out_i    => tx_filter_out_i,
    tx_filter_out_q    => tx_filter_out_q,
    -- Sampling ready command
    start_of_burst_i   => start_of_burst_i,
    sample_ready_tx_i  => sample_ready_tx_i,
    --
    sample_ready_rx_o  => sample_ready_rx_o,
    sample_toggle_rx_o => sample_toggle_rx_o,
    -- Normalization factor
    txnorm_i           => txnorm_i,
    -- Core interface
    data_filtered_i    => core_output_i,
    data_filtered_q    => core_output_q,
    --
    data2core_i        => core_input_i,
    data2core_q        => core_input_q,
    --
    clear_core         => clear_core,
    tx_active          => tx_active,
    -- DC Offset pre-estimation
    dc_pre_estim_valid => dc_pre_estim_valid_int
    );

  -- DC Offset pre-estimation ouput valid
  dc_pre_estim_valid <= dc_pre_estim_valid_int;

  -----------------------------------------------------------------------------
  -- Core filter instanciations I & Q
  -----------------------------------------------------------------------------
  -----------
  -- I
  -----------
  core_filter_i_1 : core_filter
  generic map ( 
    size_in_g        => size_core_in_g,   -- size for Core front-end input
    size_out_g       => size_core_out_g,  -- size for Core front-end output
--    use_sync_reset_g => use_sync_reset_g  -- use of synchronous reset
    use_sync_reset_g => use_sync_reset_g  -- use of synchronous reset
    )
  port map(
    clk                => clk,
    reset_n            => reset_n,
    -- Filter
    clear_buffer       => clear_core,
    fil_buf_i          => core_input_i,
    add_stage_o        => core_output_i,
    -- DC Offset pre-estimation
    tx_active          => tx_active,
    sel_dc_mode        => sel_dc_mode,
    dc_pre_estim_valid => dc_pre_estim_valid_int,
    dc_pre_estim       => dc_pre_estim_i,
    dc_pre_estim_4_agc => dc_pre_estim_4_agc_i
    );
  
  -----------
  -- Q
  -----------
  core_filter_q_1 : core_filter
  generic map ( 
    size_in_g        => size_core_in_g,   -- size for Core front-end input
    size_out_g       => size_core_out_g,  -- size for Core front-end output
--    use_sync_reset_g => use_sync_reset_g  -- use of synchronous reset
    use_sync_reset_g => use_sync_reset_g  -- use of synchronous reset
    )
  port map(
    clk                => clk,
    reset_n            => reset_n,
    -- Filter
    clear_buffer       => clear_core,
    fil_buf_i          => core_input_q,
    add_stage_o        => core_output_q,
    -- DC Offset pre-estimation
    tx_active          => tx_active,
    sel_dc_mode        => sel_dc_mode,
    dc_pre_estim_valid => dc_pre_estim_valid_int,
    dc_pre_estim       => dc_pre_estim_q,
    dc_pre_estim_4_agc => dc_pre_estim_4_agc_q
    );
  

end RTL;
