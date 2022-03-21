

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of master_hiss is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Synchro 80 -> 240 MHz
  signal txv_immstop_on240         : std_logic;
  signal hiss_enable_n_on240       : std_logic;
  signal recep_enable_on240        : std_logic;
  signal trans_enable_on240        : std_logic;
  signal sync_found_on240          : std_logic;
  signal force_hiss_pad_on240      : std_logic;
  signal tx_abmode_on240           : std_logic;
  signal rd_time_out_on240         : std_logic;
  signal clkswitch_time_out_on240  : std_logic;
  signal apb_access_on240          : std_logic;
  signal wr_nrd_on240              : std_logic;
  signal wrdata_on240              : std_logic_vector(15 downto 0);
  signal add_on240                 : std_logic_vector( 5 downto 0);
  signal clk_switch_req_tog_on240  : std_logic;
  signal preamble_detect_req_on240 : std_logic;
  -- Synchro 240 -> 80 MHz
  signal memo_i_reg_on240         : std_logic_vector(11 downto 0);
  signal memo_q_reg_on240         : std_logic_vector(11 downto 0);
  signal cca_tog_on240            : std_logic;
  signal acc_end_tog_on240        : std_logic;
  signal rx_val_tog_on240         : std_logic;
  signal next_data_req_tog_on240  : std_logic;
  signal switch_ant_tog_on240     : std_logic;
  signal clk_switched_tog_on240   : std_logic;
  signal parity_err_tog_on240     : std_logic;
  signal parity_err_cca_tog_on240 : std_logic;
  signal prot_err_on240           : std_logic;  -- long pulse (gamma cycles)
  -- Interface SM <-> decode_add
  signal clk_switch_req_on240      : std_logic;
  signal clk_switched_on240        : std_logic;
  signal back_from_deep_sleep      : std_logic;  
  -- Interface SM <-> serializer/deserializer
  signal glitch_found              : std_logic;
  signal seria_valid               : std_logic;
  signal get_reg_cca_conf          : std_logic;
  signal i_or_reg                  : std_logic;
  signal q_or_reg                  : std_logic;
  signal start_rx_data             : std_logic;
  signal get_reg_pulse             : std_logic;
  signal cca_info_pulse            : std_logic;
  signal rd_reg_pulse              : std_logic;
  signal wr_reg_pulse              : std_logic;
  signal rf_rxi_reg                : std_logic;
  signal rf_rxq_reg                : std_logic;
  signal rx_abmode_on240           : std_logic;
  -- Muxed Input Data
  signal tx_i                      : std_logic_vector(11 downto 0);
  signal tx_q                      : std_logic_vector(11 downto 0);
  signal tx_val_tog                : std_logic;
  -- Interface seria <-> buffer_for_seria
  signal start_seria               : std_logic;
  signal bufi                      : std_logic_vector(11 downto 0);
  signal bufq                      : std_logic_vector(11 downto 0);
  signal buf_tog                   : std_logic;
  signal next_data_req_tog_on80    : std_logic;
  -- Data synchronized at 240 MHz
  signal start_seria_on240         : std_logic;
  signal bufi_on240                : std_logic_vector(11 downto 0);
  signal bufq_on240                : std_logic_vector(11 downto 0);
  -- Interface deseria <-> dec_data
  signal rx_i_on80                 : std_logic_vector(11 downto 0);  -- before skipping
  signal rx_q_on80                 : std_logic_vector(11 downto 0);
  signal rx_val_tog_on80           : std_logic;
  signal transmit_possible         : std_logic;
  signal rd_access_stop            : std_logic;

  
  

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  -----------------------------------------------------------------------------
  -- *** SYNCHRONIZATION ***
  ----------------------------------------------------------------------------
  -- Synchro 80 -> 240 MHz
  sync_80to240_1: sync_80to240
    port map (
      -- Clocks & Reset
      hiss_clk                    => hiss_clk,
      reset_n                     => hiss_reset_n,
      -- Control Signals
      rd_reg_pulse_on240_i        => rd_access_stop,
      wr_reg_pulse_on240_i        => wr_reg_pulse,
      -- 80 MHz signals Inputs (from Radio Controller or BuP)
      txv_immstop_i               => txv_immstop_i, -- from BuP
      hiss_enable_n_on80_i        => hiss_enable_n_i,
      force_hiss_pad_on80_i       => force_hiss_pad_i,
      tx_abmode_on80_i            => tx_abmode_i,
      rx_abmode_on80_i            => rx_abmode_i,
      rd_time_out_on80_i          => rd_time_out_i,
      clkswitch_time_out_on80_i   => clkswitch_time_out_i,
      apb_access_on80_i           => apb_access_i,
      wr_nrd_on80_i               => wr_nrd_i,
      wrdata_on80_i               => wrdata_i,
      add_on80_i                  => add_i,
      preamble_detect_req_on80_i  => cca_search_i,
      recep_enable_on80_i         => recep_enable_i,
      trans_enable_on80_i         => trans_enable_i,
      start_seria_on80_i          => start_seria,
      sync_found_on80_i           => sync_found_i,
      buf_tog_on80_i              => buf_tog,
      bufi_on80_i                 => bufi,
      bufq_on80_i                 => bufq,
      -- 240 MHz Synchronized Outputs (to HiSS interface)
      txv_immstop_on240_o         => txv_immstop_on240,
      hiss_enable_n_on240_o       => hiss_enable_n_on240,
      force_hiss_pad_on240_o      => force_hiss_pad_on240,
      tx_abmode_on240_o           => tx_abmode_on240,
      rx_abmode_on240_o           => rx_abmode_on240,
      rd_time_out_on240_o         => rd_time_out_on240,
      clkswitch_time_out_on240_o  => clkswitch_time_out_on240,
      apb_access_on240_o          => apb_access_on240,
      wr_nrd_on240_o              => wr_nrd_on240,
      wrdata_on240_o              => wrdata_on240,
      add_on240_o                 => add_on240,
      preamble_detect_req_on240_o => preamble_detect_req_on240,
      recep_enable_on240_o        => recep_enable_on240,
      trans_enable_on240_o        => trans_enable_on240,
      start_seria_on240_o         => start_seria_on240,
      sync_found_on240_o          => sync_found_on240,
      bufi_on240_o                => bufi_on240,
      bufq_on240_o                => bufq_on240);

  

  -----------------------------------------------------------------------------
  -- *** HiSS BLOCKS ***
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Decode_add Instantiation - 240 MHz Block
  -----------------------------------------------------------------------------
  decode_add_1: decode_add
    port map (
      clk                    => hiss_clk,
      reset_n                => hiss_reset_n,
      hiss_enable_n_i        => hiss_enable_n_on240,  -- 240 MHz hiss_enable
      apb_access_i           => apb_access_on240,
      wr_nrd_i               => wr_nrd_on240,
      add_i                  => add_on240,
      wrdata_i               => wrdata_on240,
      clk_switched_i         => clk_switched_on240,
      --
      clk_switch_req_tog_o   => clk_switch_req_tog_on240,
      clk_switch_req_o       => clk_switch_req_on240,
      clk_div_o              => clk_div_o,
      back_from_deep_sleep_o => back_from_deep_sleep);

  -----------------------------------------------------------------------------
  -- State Machines Instantiation
  -----------------------------------------------------------------------------
  master_hiss_sm_1: master_hiss_sm
    port map (
      -- Clocks & Reset
      rfh_fastclk            => rfh_fastclk,
      hiss_clk               => hiss_clk,
      reset_n                => hiss_reset_n,
      -- Interface with Wild_RF
      rf_rxi_i               => rf_rxi_i,
      rf_rxq_i               => rf_rxq_i,
      --
      rf_txi_o               => rf_txi_o,
      rf_txq_o               => rf_txq_o,
      rf_tx_enable_o         => rf_txen_o,
      rf_rx_rec_o            => rf_rxen_o,
      rf_en_o                => rf_en_o,
      -- Interface with serializer-deserializer
      seria_valid_i          => seria_valid,
      start_seria_i          => start_seria_on240,
      get_reg_cca_conf_i     => get_reg_cca_conf,
      parity_err_tog_i       => parity_err_tog_on240,
      parity_err_cca_tog_i   => parity_err_cca_tog_on240,
      i_i                    => i_or_reg,
      q_i                    => q_or_reg,
      --
      start_rx_data_o        => start_rx_data,
      get_reg_pulse_o        => get_reg_pulse,
      cca_info_pulse_o       => cca_info_pulse,
      wr_reg_pulse_o         => wr_reg_pulse,
      rd_reg_pulse_o         => rd_reg_pulse,
      transmit_possible_o    => transmit_possible,
      rf_rxi_reg_o           => rf_rxi_reg,
      rf_rxq_reg_o           => rf_rxq_reg,
      -- Interface for BuP
      txv_immstop_i          => txv_immstop_on240,
      -- Interface with Radio Controller sm
      rf_en_force_i          => rf_en_force_i,
      hiss_enable_n_i        => hiss_enable_n_on240,
      force_hiss_pad_i       => force_hiss_pad_on240,
      clk_switch_req_i       => clk_switch_req_on240,
      back_from_deep_sleep_i => back_from_deep_sleep,
      preamble_detect_req_i  => preamble_detect_req_on240,
      apb_access_i           => apb_access_on240,
      wr_nrd_i               => wr_nrd_on240,
      rd_time_out_i          => rd_time_out_on240,
      clkswitch_time_out_i   => clkswitch_time_out_on240,
      reception_enable_i     => recep_enable_on240,
      transmission_enable_i  => trans_enable_on240,
      sync_found_i           => sync_found_on240,
      --
      rd_access_stop_o       => rd_access_stop,
      switch_ant_tog_o       => switch_ant_tog_on240,
      acc_end_tog_o          => acc_end_tog_on240,
      glitch_found_o         => glitch_found,
      prot_err_o             => prot_err_on240,
      clk_switched_o         => clk_switched_on240,
      clk_switched_tog_o     => clk_switched_tog_on240);


  -- To clock controller block:
  clk_switched_tog_o <= clk_switched_tog_on240;

   
  -----------------------------------------------------------------------------
  -- Buffer for Serialization Instantiation (60 MHz Block)
  -----------------------------------------------------------------------------
  -- mux input tx data  : A mode or B mode
  tx_val_tog <= tx_val_tog_a_i when tx_abmode_i = '0' else tx_val_tog_b_i;
  tx_i       <= sxt(tx_ai_i,12) when tx_abmode_i = '0'
                else sxt(tx_b_i(1) & tx_b_i(1) ,12); 
  tx_q       <= sxt(tx_aq_i,12) when tx_abmode_i = '0'
                else sxt(tx_b_i(0) & tx_b_i(0),12);
                        
  buffer_for_seria_1: buffer_for_seria
    generic map (
      buf_size_g  => 2,
      fifo_content_g => 1,
      empty_at_end_g => 1,
      in_size_g    => 12)
    port map (
      -- Clocks & Reset
      sampling_clk      => pclk,
      reset_n           => reset_n,
      -- Interface with muxed tx path
      data_i_i          => tx_i,
      data_q_i          => tx_q,
      data_val_tog_i    => tx_val_tog,
      -- Interface with Radio Controller  60 MHz
      immstop_i         => txv_immstop_i,
      hiss_enable_n_i   => hiss_enable_n_i,
      path_enable_i     => trans_enable_i,
      stream_enable_i   => trans_enable_i,
     -- Interface master_seria
      next_d_req_tog_i  => next_data_req_tog_on80,
      --
      start_seria_o     => start_seria,
      buf_tog_o         => buf_tog,
      bufi_o            => bufi,
      bufq_o            => bufq);
  
  -----------------------------------------------------------------------------
  -- Serializer Instantiation (240 MHz Block)
  -----------------------------------------------------------------------------
  master_seria_1: master_seria
    port map (
       -- Clocks & Reset
      hiss_clk            => hiss_clk,
      reset_n             => hiss_reset_n,
      -- Interface with Buffer_for_deseria
      bufi_i              => bufi_on240,
      bufq_i              => bufq_on240,
      tx_abmode_i         => tx_abmode_on240,
      trans_enable_i      => start_seria_on240,
      txv_immstop_i       => txv_immstop_on240,
      --
      next_data_req_tog_o => next_data_req_tog_on240,
      -- Interface with APB_interface 80 MHz
      wrdata_i            => wrdata_on240,
      add_i               => add_on240,
      -- Interface with SM 240 MHz
      transmit_possible_i => transmit_possible,
      rd_reg_pulse_i      => rd_reg_pulse,
      wr_reg_pulse_i      => wr_reg_pulse,
      --
      seria_valid_o       => seria_valid,
      reg_or_i_o          => i_or_reg,
      reg_or_q_o          => q_or_reg);

  -----------------------------------------------------------------------------
  -- Deserializer Instantiation
  -----------------------------------------------------------------------------
  master_deseria_1: master_deseria
    port map (
      -- Clocks & Reset
      hiss_clk             => hiss_clk,
      reset_n              => hiss_reset_n,
      -- Interface with BB (synchronized inside SM)
      rf_rxi_i             => rf_rxi_reg,
      rf_rxq_i             => rf_rxq_reg,
      -- Interface with SM
      start_rx_data_i      => start_rx_data,
      get_reg_pulse_i      => get_reg_pulse,
      cca_info_pulse_i     => cca_info_pulse,
      abmode_i             => rx_abmode_on240,
      get_reg_cca_conf_o   => get_reg_cca_conf,
      -- Controls
      memo_i_reg_o         => memo_i_reg_on240,
      memo_q_reg_o         => memo_q_reg_on240,
      rx_val_tog_o         => rx_val_tog_on240,
      --  Interface with Radio Controller sm
      hiss_enable_n_i      => hiss_enable_n_on240,
      --
      parity_err_tog_o     => parity_err_tog_on240,
      parity_err_cca_tog_o => parity_err_cca_tog_on240,
      cca_tog_o            => cca_tog_on240);


  -----------------------------------------------------------------------------
  -- Sync 240 to 80
  -----------------------------------------------------------------------------
  sync_240to80_1: sync_240to80
    generic map (
      clk44_possible_g => clk44_possible_g)  -- when 1 - the radioctrl can work with a
    port map (
      -- Clocks & Reset
      pclk                       => pclk,              -- [in]  240 MHz clock
      reset_n                    => reset_n,           -- [in]
      -- Signals
      -- Registers from deserializer : CCA / RDATA or RX data
      memo_i_reg_on240_i         => memo_i_reg_on240,   -- [in]
      memo_q_reg_on240_i         => memo_q_reg_on240,   -- [in]
      cca_tog_on240_i            => cca_tog_on240,      -- [in]
      acc_end_tog_on240_i        => acc_end_tog_on240,  -- [in]
      rx_val_tog_on240_i         => rx_val_tog_on240,   -- [in]
      -- Controls Signals
      next_data_req_tog_on240_i  => next_data_req_tog_on240,   -- [in]
      switch_ant_tog_on240_i     => switch_ant_tog_on240,      -- [in]
      clk_switch_req_tog_on240_i => clk_switch_req_tog_on240,  -- [in]
      clk_switched_tog_on240_i   => clk_switched_tog_on240,    -- [in]
      parity_err_tog_on240_i     => parity_err_tog_on240,      -- [in]
      parity_err_cca_tog_on240_i => parity_err_cca_tog_on240,  -- [in]
      prot_err_on240_i           => prot_err_on240,            -- [in]  long pulse (gamma cycles)
      -- *** Outputs ****
      -- Data out
      rx_i_on80_o                => rx_i_on80,          -- [out]
      rx_q_on80_o                => rx_q_on80,          -- [out]
      rx_val_tog_on80_o          => rx_val_tog_on80,    -- [out]
      -- CCA info
      cca_info_on80_o            => cca_info_o,       -- [out]
      cca_add_info_on80_o        => cca_add_info_o,   -- [out]
      cca_on80_o                 => cca_o,        -- [out]
      -- RDDATA
      prdata_on80_o              => rddata_o,     -- [out]
      acc_end_on80_o             => acc_end_o,    -- [out]
      -- Controls Signals
      next_data_req_tog_on80_o   => next_data_req_tog_on80,    -- [out]
      switch_ant_tog_on80_o      => switch_ant_tog_o,          -- [out]
      clk_switch_req_on80_o      => clk_switch_req_o,          -- [out] 
      clk_switched_on80_o        => clk_switched_80_o,         -- [out] pulse when clk switched
      parity_err_tog_on80_o      => parity_err_tog_o,          -- [out]
      parity_err_cca_tog_on80_o  => parity_err_cca_tog_o,      -- [out]
      prot_err_on80_o            => prot_err_o);  -- [out] pulse

  -----------------------------------------------------------------------------
  -- Decode Data ( get sample skip and cs inserted inside data)
  -----------------------------------------------------------------------------
  master_dec_data_1: master_dec_data
    generic map (
      rx_a_size_g => rx_a_size_g           -- size of data input of tx_filter A
      )                                    -- size of data input of tx_filter B
    port map (
      sampling_clk    => pclk,             -- [in]
      reset_n         => reset_n,          -- [in]
      --
      rx_i_i          => rx_i_on80,        -- [in]
      rx_q_i          => rx_q_on80,        -- [in]
      rx_val_tog_i    => rx_val_tog_on80,  -- [in]  high = data is valid
      recep_enable_i  => recep_enable_i,   -- [in]
      rx_abmode_i     => rx_abmode_i,      -- [in]
      --
      rx_i_o          => rx_i_o,           -- [out]
      rx_q_o          => rx_q_o,           -- [out]
      rx_val_tog_o    => rx_val_tog_o,     -- [out] high = data is valid
      clk_2skip_tog_o => clk_2skip_tog_o,  -- [out]
      cs_error_o      => cs_error_o,       -- [out]
      cs_o            => cs_o,             -- [out]
      cs_valid_o      => cs_valid_o);      -- [out]

  
  hiss_diagport_o <= (others => '0');
  
end RTL;
