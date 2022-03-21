

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of modem802_11a2_core is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant FSIZE_OUT_TX_CT : integer := 8;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------

  -- Registers
  -- MDMaPRBSCNTL
  signal prbs_inv               : std_logic;
  signal prbs_sel               : std_logic_vector(1 downto 0);
  signal prbs_init              : std_logic_vector(22 downto 0);
  -- MDMaTXCNTL0
  signal add_short_pre          : std_logic_vector(1 downto 0);
  signal tx_phase               : std_logic_vector(5 downto 0);
  signal tx_ampl                : std_logic_vector(8 downto 0);
  signal dac_powerdown_dyn      : std_logic;
  signal tx_enddel              : std_logic_vector(7 downto 0);
  signal scrmode                : std_logic;
  signal scrinitval             : std_logic_vector(6 downto 0);
  -- MDMaTXCNTL1
  signal tx_scrambler           : std_logic_vector(6 downto 0);
  -- MDMaRXCNTL0
  signal adc_powerdown_dyn      : std_logic;
  signal wf_window              : std_logic_vector(1 downto 0);
  signal reducerasures          : std_logic_vector(1 downto 0);
  signal res_dco_disb           : std_logic;
  signal iq_mm_estrst           : std_logic;
  signal iqmm_reset_done        : std_logic;
  signal iq_mm_est              : std_logic;
  signal rx_iqmm_g_step         : std_logic_vector(7 downto 0);
  signal rx_iqmm_ph_step        : std_logic_vector(7 downto 0);
  -- MDMaINITSYNCCNTL
  signal detect_thr_carrier     : std_logic_vector(3 downto 0);
  signal initsync_timoffst      : std_logic_vector(2 downto 0);
  signal initsync_autothr1      : std_logic_vector(5 downto 0);
  signal initsync_autothr0      : std_logic_vector(5 downto 0);
  -- MDMaTIMEDOMSTAT
  signal freq_off_est           : std_logic_vector(19 downto 0);
  signal ybnb                   : std_logic_vector(6 downto 0);
  -- MDMaEQCNTL1
  signal satmaxncar_54          : std_logic_vector(5 downto 0);
  signal satmaxncar_48          : std_logic_vector(5 downto 0);
  signal satmaxncar_36          : std_logic_vector(5 downto 0);
  signal satmaxncar_24          : std_logic_vector(5 downto 0);
  signal histoffset_54          : std_logic_vector(1 downto 0);
  signal histoffset_48          : std_logic_vector(1 downto 0);
  signal histoffset_36          : std_logic_vector(1 downto 0);
  signal histoffset_24          : std_logic_vector(1 downto 0);
  -- MDMaEQCNTL2
  signal satmaxncar_18          : std_logic_vector(5 downto 0);
  signal satmaxncar_12          : std_logic_vector(5 downto 0);
  signal satmaxncar_09          : std_logic_vector(5 downto 0);
  signal satmaxncar_06          : std_logic_vector(5 downto 0);
  signal histoffset_18          : std_logic_vector(1 downto 0);
  signal histoffset_12          : std_logic_vector(1 downto 0);
  signal histoffset_09          : std_logic_vector(1 downto 0);
  signal histoffset_06          : std_logic_vector(1 downto 0);
  -- MDMaRXCNTL1
  signal length_limit           : std_logic_vector(11 downto 0);
  signal rx_length_chk_en       : std_logic;
  -- MDMaIQCALIBCNTL
  signal calmode                : std_logic;
  -- MDMaRXIQPRESET
  signal rx_iq_ph_preset        : std_logic_vector(15 downto 0);
  signal rx_iq_g_preset         : std_logic_vector(15 downto 0);
  -- MDMaRXIQEST
  signal rx_iq_ph_est           : std_logic_vector(15 downto 0);
  signal rx_iq_g_est            : std_logic_vector(15 downto 0);
  -- Synchronous reset
  signal rx_dpath_reset_n      : std_logic; -- enable block - need to be synchronized

  -- Data after iqcomp
  signal rx_i_iqcp              : std_logic_vector(10 downto 0);
  signal rx_q_iqcp              : std_logic_vector(10 downto 0);
  signal rx_iqcp_data_valid     : std_logic;
  
  ---------------------------------------
  -- FFT
  ---------------------------------------
  signal fft_data_ready          : std_logic;
  signal fft_start_of_burst      : std_logic;
  signal fft_start_of_symbol     : std_logic;
  signal fft_data_valid          : std_logic;
  signal ifft_tx_data_ready      : std_logic;
  signal ifft_tx_start_of_signal : std_logic;
  signal ifft_tx_end_burst       : std_logic;
  signal x_out                   : FFT_ARRAY_T;
  signal y_out                   : FFT_ARRAY_T;
  signal fft_sync_reset_n        : std_logic;

  ---------------------------------------
  -- Rx top
  ---------------------------------------
  signal td_start_of_symbol : std_logic;
  signal td_start_of_burst  : std_logic;
  signal td_data_valid      : std_logic;
  signal td_i               : std_logic_vector(10 downto 0);
  signal td_q               : std_logic_vector(10 downto 0);
  signal fd_data_ready      : std_logic;
  signal rx_packet_end      : std_logic;
  signal cp2_detected       : std_logic;
  
  ---------------------------------------
  -- Tx top
  ---------------------------------------
  signal tx_start_signal       : std_logic;
  signal tx_end_burst          : std_logic;
  signal mapper_data_valid     : std_logic;
  signal fft_serial_data_ready : std_logic;
  signal mapper_data_i_ext     : std_logic_vector(10 downto 0);
  signal mapper_data_q_ext     : std_logic_vector(10 downto 0);
  signal mapper_data_i         : std_logic_vector(7 downto 0);
  signal mapper_data_q         : std_logic_vector(7 downto 0);
  -- Force a_txonoff_req if reception not finished
  signal a_txonoff_req_int     : std_logic;
  
  ---------------------------------------
  -- State machine
  ---------------------------------------
  signal tx_active            : std_logic;
  signal tx_sync_reset_n      : std_logic;
  signal phy_txstartend_conf  : std_logic;
  signal phy_rxstartend_ind   : std_logic;

  ---------------------------------------
  -- Resynchronization between Core and Frontend/Radio Controller
  ---------------------------------------
  -- frontend/RC -> core
  signal filter_valid_rx_ff1_resync    : std_logic;
  signal filter_valid_rx_ff2_resync    : std_logic;
  signal rx_filtered_data_i_ff1_resync : std_logic_vector(10 downto 0);
  signal rx_filtered_data_i_ff2_resync : std_logic_vector(10 downto 0);
  signal rx_filtered_data_q_ff1_resync : std_logic_vector(10 downto 0);
  signal rx_filtered_data_q_ff2_resync : std_logic_vector(10 downto 0);
  -- core -> frontend/RC
  signal filter_start_of_burst_int     : std_logic;
  signal filter_valid_tx_int           : std_logic;
  signal tx_data2filter_i_int          : std_logic_vector( 9 downto 0);
  signal tx_data2filter_q_int          : std_logic_vector( 9 downto 0);

  ---------------------------------------
  -- Signals for residual dc offset block
  ---------------------------------------
  signal residual_dc_offset_valid     : std_logic;
  signal residual_dc_offset_data_i    : std_logic_vector(10 downto 0);
  signal residual_dc_offset_data_q    : std_logic_vector(10 downto 0);

  ---------------------------------------
  -- Signals for gain and phase mismatch estimates to compensation block
  ---------------------------------------
  signal g_est                   : std_logic_vector(8 downto 0);
  signal ph_est                  : std_logic_vector(5 downto 0);
  signal ampl                    : std_logic_vector(8 downto 0);
  signal phase_i                 : std_logic_vector(5 downto 0);
  signal enable_iq_estim         : std_logic;
  signal rx_iq_mm_est_en         : std_logic;
  signal disable_output_iq_estim : std_logic;
  -- Avoid delta delays during simulation
  signal tx_rxn_i             : std_logic; -- High for TX mode.
  signal tx_start_of_signal_i : std_logic; -- 'start of signal' marker.
  signal tx_end_of_burst_i    : std_logic; -- 'end of burst' marker.
  signal tx_data_valid_i      : std_logic; -- High when input data is valid.
  signal tx_data_ready_i      : std_logic; -- Next block ready for data.
  signal rx_start_of_burst_i  : std_logic;
  signal rx_start_of_symbol_i : std_logic;
  signal rx_data_valid_i      : std_logic;
  signal rx_data_ready_i      : std_logic;
  signal tx_x_i               : std_logic_vector(10 downto 0);
  signal tx_y_i               : std_logic_vector(10 downto 0);
  signal rx_x_i               : std_logic_vector(10 downto 0);
  signal rx_y_i               : std_logic_vector(10 downto 0);
 
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  -- unused output
  rxv_rssi_o <= (others => '0');
  
  -- outputs links
  phy_txstartend_conf_o <= phy_txstartend_conf;
  phy_rxstartend_ind_o  <= phy_rxstartend_ind;
  tx_active_o           <= tx_active;
  cp2_detected_o        <= cp2_detected;
  -- Force a_txonoff_req output to '0' if the reception is not finished
  a_txonoff_req_o       <= a_txonoff_req_int and not a_rxactive_conf_i;

  -----------------------------------------------------------------------------
  -- Gating condition
  -----------------------------------------------------------------------------
  modema2_gating_p : process(clk, reset_n)
  begin
    if reset_n = '0' then
      rx_gating <= '1';
      tx_gating <= '1';
    elsif clk'event and clk = '1' then

      -- Gating condition for Rx path
      if cca_busy_i = '1' or phy_rxstartend_ind = '1' then
        rx_gating <= '0';
      else
        rx_gating <= '1';
      end if;

      -- Gating condition for Tx path
      if txv_datarate_i(3) = '1' and
        (phy_txstartend_conf = '1' or phy_txstartend_req_i  = '1') then
        tx_gating <= '0';
      else
        tx_gating <= '1';
      end if;

    end if;
  end process modema2_gating_p;
  
  -----------------------------------------------------------------------------
  -- FFT
  -----------------------------------------------------------------------------
  mapper_data_i_ext <= mapper_data_i(7) &
                       mapper_data_i & "00";
  mapper_data_q_ext <= mapper_data_q(7) &
                       mapper_data_q & "00";


  tx_rxn_i             <= tx_active;
  tx_start_of_signal_i <= tx_start_signal;
  tx_end_of_burst_i    <= tx_end_burst; 
  tx_data_valid_i      <= mapper_data_valid;
  tx_data_ready_i      <= fft_serial_data_ready;
  rx_start_of_burst_i  <= td_start_of_burst;
  rx_start_of_symbol_i <= td_start_of_symbol;
  rx_data_valid_i      <= td_data_valid;
  rx_data_ready_i      <= fd_data_ready;
  tx_x_i               <= mapper_data_i_ext;
  tx_y_i               <= mapper_data_q_ext;
  rx_x_i               <= td_i;
  rx_y_i               <= td_q;

  -- FFT synchronous reset (controlled by Tx and Rx path)
  fft_sync_reset_n     <= (tx_sync_reset_n or not tx_rxn_i) and
                          (rx_dpath_reset_n or tx_rxn_i);
  
  fft_shell_1: fft_shell
    generic map (
      data_size_g   => 11,
      cordic_bits_g => 10,
      ifft_norm_g   => 0)
    port map (
      --------------------------------------
      -- Clocks & Reset
      --------------------------------------
      masterclk            => fft_gclk,
      reset_n              => reset_n,
      sync_reset_n         => fft_sync_reset_n,
      --------------------------------------
      -- Controls
      --------------------------------------
      tx_rxn_i             => tx_rxn_i, -- High for TX mode.
      --------------------------------------
      -- Controls for TX mode
      --------------------------------------
      -- signals from/to preceeding module
      tx_start_of_signal_i => tx_start_of_signal_i,
      tx_end_of_burst_i    => tx_end_of_burst_i,
      tx_data_valid_i      => tx_data_valid_i,
      tx_data_ready_i      => tx_data_ready_i,
      --
      tx_data_ready_o      => ifft_tx_data_ready,
      tx_start_of_signal_o => ifft_tx_start_of_signal,
      tx_end_of_burst_o    => ifft_tx_end_burst,
      --------------------------------------
      -- Controls for RX mode
      --------------------------------------
      -- signals fmodem802_11a2_pkgrom/to preceeding module
      -- receive mode
      rx_start_of_burst_i  => rx_start_of_burst_i,
      rx_start_of_symbol_i => rx_start_of_symbol_i,
      rx_data_valid_i      => rx_data_valid_i,
      rx_data_ready_o      => fft_data_ready,
      -- signals from/to subsequent module
      -- receive mode
      rx_data_ready_i      => rx_data_ready_i, 
      rx_data_valid_o      => fft_data_valid,
      rx_start_of_burst_o  => fft_start_of_burst,
      rx_start_of_symbol_o => fft_start_of_symbol,
      --------------------------------------
      -- Data
      --------------------------------------
      -- TX data in.
      tx_x_i               => tx_x_i,
      tx_y_i               => tx_y_i,
      -- RX data in.
      rx_x_i               => rx_x_i,
      rx_y_i               => rx_y_i,
      --
      x_0_o             => x_out(0),
      y_0_o             => y_out(0),
      x_1_o             => x_out(1),
      y_1_o             => y_out(1),
      x_2_o             => x_out(2),
      y_2_o             => y_out(2),
      x_3_o             => x_out(3),
      y_3_o             => y_out(3),
      x_4_o             => x_out(4),
      y_4_o             => y_out(4),
      x_5_o             => x_out(5),
      y_5_o             => y_out(5),
      x_6_o             => x_out(6),
      y_6_o             => y_out(6),
      x_7_o             => x_out(7),
      y_7_o             => y_out(7),
      x_8_o             => x_out(8),
      y_8_o             => y_out(8),
      x_9_o             => x_out(9),
      y_9_o             => y_out(9),
      x_10_o            => x_out(10),
      y_10_o            => y_out(10),
      x_11_o            => x_out(11),
      y_11_o            => y_out(11),
      x_12_o            => x_out(12),
      y_12_o            => y_out(12),
      x_13_o            => x_out(13),
      y_13_o            => y_out(13),
      x_14_o            => x_out(14),
      y_14_o            => y_out(14),
      x_15_o            => x_out(15),
      y_15_o            => y_out(15),
      x_16_o            => x_out(16),
      y_16_o            => y_out(16),
      x_17_o            => x_out(17),
      y_17_o            => y_out(17),
      x_18_o            => x_out(18),
      y_18_o            => y_out(18),
      x_19_o            => x_out(19),
      y_19_o            => y_out(19),
      x_20_o            => x_out(20),
      y_20_o            => y_out(20),
      x_21_o            => x_out(21),
      y_21_o            => y_out(21),
      x_22_o            => x_out(22),
      y_22_o            => y_out(22),
      x_23_o            => x_out(23),
      y_23_o            => y_out(23),
      x_24_o            => x_out(24),
      y_24_o            => y_out(24),
      x_25_o            => x_out(25),
      y_25_o            => y_out(25),
      x_26_o            => x_out(26),
      y_26_o            => y_out(26),
      x_27_o            => x_out(27),
      y_27_o            => y_out(27),
      x_28_o            => x_out(28),
      y_28_o            => y_out(28),
      x_29_o            => x_out(29),
      y_29_o            => y_out(29),
      x_30_o            => x_out(30),
      y_30_o            => y_out(30),
      x_31_o            => x_out(31),
      y_31_o            => y_out(31),
      x_32_o            => x_out(32),
      y_32_o            => y_out(32),
      x_33_o            => x_out(33),
      y_33_o            => y_out(33),
      x_34_o            => x_out(34),
      y_34_o            => y_out(34),
      x_35_o            => x_out(35),
      y_35_o            => y_out(35),
      x_36_o            => x_out(36),
      y_36_o            => y_out(36),
      x_37_o            => x_out(37),
      y_37_o            => y_out(37),
      x_38_o            => x_out(38),
      y_38_o            => y_out(38),
      x_39_o            => x_out(39),
      y_39_o            => y_out(39),
      x_40_o            => x_out(40),
      y_40_o            => y_out(40),
      x_41_o            => x_out(41),
      y_41_o            => y_out(41),
      x_42_o            => x_out(42),
      y_42_o            => y_out(42),
      x_43_o            => x_out(43),
      y_43_o            => y_out(43),
      x_44_o            => x_out(44),
      y_44_o            => y_out(44),
      x_45_o            => x_out(45),
      y_45_o            => y_out(45),
      x_46_o            => x_out(46),
      y_46_o            => y_out(46),
      x_47_o            => x_out(47),
      y_47_o            => y_out(47),
      x_48_o            => x_out(48),
      y_48_o            => y_out(48),
      x_49_o            => x_out(49),
      y_49_o            => y_out(49),
      x_50_o            => x_out(50),
      y_50_o            => y_out(50),
      x_51_o            => x_out(51),
      y_51_o            => y_out(51),
      x_52_o            => x_out(52),
      y_52_o            => y_out(52),
      x_53_o            => x_out(53),
      y_53_o            => y_out(53),
      x_54_o            => x_out(54),
      y_54_o            => y_out(54),
      x_55_o            => x_out(55),
      y_55_o            => y_out(55),
      x_56_o            => x_out(56),
      y_56_o            => y_out(56),
      x_57_o            => x_out(57),
      y_57_o            => y_out(57),
      x_58_o            => x_out(58),
      y_58_o            => y_out(58),
      x_59_o            => x_out(59),
      y_59_o            => y_out(59),
      x_60_o            => x_out(60),
      y_60_o            => y_out(60),
      x_61_o            => x_out(61),
      y_61_o            => y_out(61),
      x_62_o            => x_out(62),
      y_62_o            => y_out(62),
      x_63_o            => x_out(63),
      y_63_o            => y_out(63)
    );


  ------------------------------------------
  -- FFs on tx outputs
  ------------------------------------------
  sync_tx_data_p: process (tx_path_a_gclk, reset_n)
  begin  -- process sync_rx_data_p
    if reset_n = '0' then               
      filter_start_of_burst_o <= '0';
      filter_valid_tx_o       <= '0';
      tx_data2filter_i        <= (others => '0');
      tx_data2filter_q        <= (others => '0');
    elsif tx_path_a_gclk'event and tx_path_a_gclk = '1' then
      filter_start_of_burst_o <= filter_start_of_burst_int;
      filter_valid_tx_o       <= filter_valid_tx_int;
      tx_data2filter_i        <= tx_data2filter_i_int;
      tx_data2filter_q        <= tx_data2filter_q_int;
    end if;
  end process sync_tx_data_p;


  -----------------------------------------------------------------------------
  -- Transmitter
  -----------------------------------------------------------------------------
  tx_top_a2_1 : tx_top_a2
  generic map (
    fsize_in_g => 10
    )
  port map (
    --------------------------------
    -- Clock & reset
    --------------------------------    
    clk                      => clk,
    gclk                     => tx_path_a_gclk,
    reset_n                  => reset_n,

    --------------------------------
    -- Wild bup interface
    --------------------------------    
    phy_txstartend_req_i     => phy_txstartend_req_i,
    phy_txstartend_conf_o    => phy_txstartend_conf,
    txv_immstop_i            => txv_immstop_i,
    phy_data_req_i           => phy_data_req_i,
    phy_data_conf_o          => phy_data_conf_o,
    bup_txdata_i             => bup_txdata_i,
    txv_rate_i               => txv_datarate_i,
    txv_length_i             => txv_length_i,
    txv_service_i            => txv_service_i,
    txv_txpwr_level_i        => txpwr_level_i,
    
    --------------------------------
    -- RF control FSM interface
    --------------------------------    
    a_txonoff_req_o          => a_txonoff_req_int,
    a_txbbonoff_req_o        => a_txbbonoff_req_o,
    a_txonoff_conf_i         => a_txonoff_conf_i,
    a_txpga_o                => a_txpga_o,
    dac_on_o                 => dac_on_o,
    tx_active_o              => tx_active,
    sync_reset_n_o           => tx_sync_reset_n,
    dac_powerdown_dyn_i      => dac_powerdown_dyn,
    
    --------------------------------------
    -- IFFT interface
    --------------------------------------
    tx_start_signal_o        => tx_start_signal,
    tx_end_burst_o           => tx_end_burst,
    mapper_data_valid_o      => mapper_data_valid,
    fft_serial_data_ready_o  => fft_serial_data_ready,
    mapper_data_i_o          => mapper_data_i,
    mapper_data_q_o          => mapper_data_q,
    --
    ifft_data_i_i            => x_out, 
    ifft_data_q_i            => y_out, 
    ifft_tx_start_of_signal_i => ifft_tx_start_of_signal,
    ifft_tx_end_burst_i       => ifft_tx_end_burst,
    ifft_data_ready_i         => ifft_tx_data_ready,
    
    --------------------------------------
    -- TX filter interface
    --------------------------------------
    data2filter_i_o          => tx_data2filter_i_int,
    data2filter_q_o          => tx_data2filter_q_int,
    filter_start_of_burst_o  => filter_start_of_burst_int,
    filter_sampleready_o     => filter_valid_tx_int,
 
    --------------------------------------
    -- Parameters from registers
    --------------------------------------  
    prbs_inv_i               => prbs_inv,
    prbs_sel_i               => prbs_sel,
    prbs_init_i              => prbs_init,
    add_short_pre_i          => add_short_pre,
    tx_enddel_i              => tx_enddel,
    scrmode_i                => scrmode,
    scrinitval_i             => scrinitval,
    tx_scrambler_o           => tx_scrambler,
    
    --------------------------------------
    -- Diag port
    --------------------------------------
    tx_top_diag              => modem_diag3
    );

  ------------------------------------------
  -- Re-Sync rx data
  ------------------------------------------
  resync_rx_data_p: process (rx_path_a_gclk, reset_n)
  begin  -- process resync_rx_data_p
    if reset_n = '0' then               
      filter_valid_rx_ff1_resync    <= '0';
      filter_valid_rx_ff2_resync    <= '0';
      rx_filtered_data_i_ff1_resync <= (others => '0');
      rx_filtered_data_i_ff2_resync <= (others => '0');
      rx_filtered_data_q_ff1_resync <= (others => '0');
      rx_filtered_data_q_ff2_resync <= (others => '0');
    elsif rx_path_a_gclk'event and rx_path_a_gclk = '1' then 
      filter_valid_rx_ff1_resync    <= filter_valid_rx_i;
      filter_valid_rx_ff2_resync    <= filter_valid_rx_ff1_resync;
      rx_filtered_data_i_ff1_resync <= rx_filtered_data_i;
      rx_filtered_data_i_ff2_resync <= rx_filtered_data_i_ff1_resync;
      rx_filtered_data_q_ff1_resync <= rx_filtered_data_q;
      rx_filtered_data_q_ff2_resync <= rx_filtered_data_q_ff1_resync;
    end if;
  end process resync_rx_data_p;

  -------------------------------------------------
  -- Residual dc offset
  -------------------------------------------------
  residual_dc_offset_1 : residual_dc_offset
    port map (
      clk           => rx_path_a_gclk,
      reset_n       => reset_n,
      sync_reset_n  => rx_dpath_reset_n,
      -- Controls
      dcoffset_disb => res_dco_disb,
      cp2_detected  => cp2_detected,
      data_valid_i  => filter_valid_rx_ff2_resync,
      data_valid_o  => residual_dc_offset_valid,
      -- Data in
      i_i           => rx_filtered_data_i_ff2_resync,
      q_i           => rx_filtered_data_q_ff2_resync,
      -- Compensates out
      i_o           => residual_dc_offset_data_i,
      q_o           => residual_dc_offset_data_q
      );
  
  -------------------------------------------------
  -- RX IQ mismatch compensation
  -------------------------------------------------
  rx_iq_compensation_1 : iq_compensation
    generic map (
      iq_i_width_g  => 11,
      iq_o_width_g  => 11,
      phase_width_g => 6,
      ampl_width_g  => 9,
      toggle_in_g   => 1,
      toggle_out_g  => 0
      )
    port map (
      clk          => rx_path_a_gclk,
      reset_n      => reset_n,
      sync_reset_n => rx_dpath_reset_n,
      -- Controls
      phase_i      => ph_est, -- from iq_estimation
      ampl_i       => g_est,  -- from iq_estimation
      data_valid_i => residual_dc_offset_valid,
      data_valid_o => rx_iqcp_data_valid,
      -- Data in
      i_in         => residual_dc_offset_data_i,
      q_in         => residual_dc_offset_data_q,
      -- Compensates out
      i_out        => rx_i_iqcp,
      q_out        => rx_q_iqcp
      );


  -------------------------------------------------
  -- RX IQ phase and amplitude mismatch estimation
  -------------------------------------------------
  rx_iq_estimation_1 : iq_estimation
    generic map (
      iq_i_width_g   => 11,
      gain_width_g   => 9,
      phase_width_g  => 6,
      preset_width_g => 16
      )
    port map (
      clk             => rx_path_a_gclk,
      reset_n         => reset_n,
      -- Controls
      rx_iqmm_est     => iq_mm_est,
      rx_iqmm_est_en  => rx_iq_mm_est_en,
      rx_iqmm_out_dis => disable_output_iq_estim,
      rx_iqmm_reset   => iq_mm_estrst,
      rx_packet_end   => rx_packet_end,
      rx_iqmm_g_pset  => rx_iq_g_preset,
      rx_iqmm_ph_pset => rx_iq_ph_preset,
      rx_iqmm_g_step  => rx_iqmm_g_step,
      rx_iqmm_ph_step => rx_iqmm_ph_step,
      --
      iqmm_reset_done => iqmm_reset_done,
      -- Data in
      data_valid_in   => rx_iqcp_data_valid,
      i_in            => rx_i_iqcp,
      q_in            => rx_q_iqcp,
      -- Estimates out
      rx_iqmm_g_est   => g_est, 
      rx_iqmm_ph_est  => ph_est,
      gain_accum      => rx_iq_g_est,
      phase_accum     => rx_iq_ph_est
      );

  -- IQ mismatch enable
  rx_iq_mm_est_en <= iq_mm_est and enable_iq_estim;
  

  --------------------------------------
  -- RX top
  --------------------------------------
  rx_top_1: rx_top

  port map(
    ---------------------------------------
    -- Clock & reset
    ---------------------------------------
    clk           => clk,
    gclk          => rx_path_a_gclk,
    reset_n       => reset_n,
    mdma_sm_rst_n => mdma_sm_rst_n,

    ---------------------------------------
    -- FFT
    ---------------------------------------
    fft_data_ready_i      => fft_data_ready,
    fft_start_of_burst_i  => fft_start_of_burst,
    fft_start_of_symbol_i => fft_start_of_symbol,
    fft_data_valid_i      => fft_data_valid,
    fft_i_i               => x_out,
    fft_q_i               => y_out,
    td_start_of_symbol_o  => td_start_of_symbol,
    td_start_of_burst_o   => td_start_of_burst,
    td_data_valid_o       => td_data_valid,
    fd_data_ready_o       => fd_data_ready,
    td_i_o                => td_i,
    td_q_o                => td_q,
    
    ---------------------------------------
    -- Bup interface
    ---------------------------------------
    phy_ccarst_req_i      => phy_ccarst_req_i,
    tx_dac_on_i           => tx_active,
    rxe_errorstat_o       => rxe_errorstat_o,
    rxv_length_o          => rxv_length_o,
    rxv_datarate_o        => rxv_datarate_o,
    phy_cca_ind_o         => phy_cca_ind_o,
    phy_ccarst_conf_o     => phy_ccarst_conf_o,
    rxv_service_o         => rxv_service_o,
    rxv_service_ind_o     => rxv_service_ind_o,
    bup_rxdata_o          => bup_rxdata_o,
    phy_data_ind_o        => phy_data_ind_o,
    phy_rxstartend_ind_o  => phy_rxstartend_ind,
    
    ---------------------------------------
    -- Radio controller
    ---------------------------------------
    rxactive_conf_i => a_rxactive_conf_i,
    rssi_on_o       => rssi_on_o,
    rxactive_req_o  => a_rxactive_req_o,
    adc_powerctrl_o => adc_powerctrl_o,

    --------------------------------------------
    -- CCA
    --------------------------------------------
    cca_busy_i      => cca_busy_i,
    listen_start_o  => listen_start_o,
    cp2_detected_o  => cp2_detected,

    ---------------------------------------
    -- IQ compensation
    ---------------------------------------
    i_iqcomp_i          => rx_i_iqcp,
    q_iqcomp_i          => rx_q_iqcp,
    iqcomp_data_valid_i => rx_iqcp_data_valid,
    --
    rx_dpath_reset_n_o  => rx_dpath_reset_n,
    rx_packet_end_o     => rx_packet_end,
    enable_iq_estim_o   => enable_iq_estim,
    disable_output_iq_estim_o => disable_output_iq_estim,

    ---------------------------------------
    -- Registers
    ---------------------------------------
    -- INIT sync
    detect_thr_carrier_i=> detect_thr_carrier,
    initsync_autothr0_i => initsync_autothr0,
    initsync_autothr1_i => initsync_autothr1,
    -- Samplefifo                                           
    sampfifo_timoffst_i => initsync_timoffst,
    -- For IQ calibration module
    calmode_i           => calmode,
    -- ADC mode
    adcpdmod_i          => adc_powerdown_dyn,
    -- Wiener filter
    wf_window_i         => wf_window,
    reducerasures_i     => reducerasures,
    -- Channel decoder
    length_limit_i      => length_limit,
    rx_length_chk_en_i  => rx_length_chk_en,
    -- Equalizer
    histoffset_54_i  => histoffset_54,
    histoffset_48_i  => histoffset_48,
    histoffset_36_i  => histoffset_36,
    histoffset_24_i  => histoffset_24,
    histoffset_18_i  => histoffset_18,
    histoffset_12_i  => histoffset_12,
    histoffset_09_i  => histoffset_09,
    histoffset_06_i  => histoffset_06,
    satmaxncarr_54_i => satmaxncar_54,
    satmaxncarr_48_i => satmaxncar_48,
    satmaxncarr_36_i => satmaxncar_36,
    satmaxncarr_24_i => satmaxncar_24,
    satmaxncarr_18_i => satmaxncar_18,
    satmaxncarr_12_i => satmaxncar_12,
    satmaxncarr_09_i => satmaxncar_09,
    satmaxncarr_06_i => satmaxncar_06,
    -- Frequency correction
    freq_off_est_o   => freq_off_est,
    -- Preprocessing sample number before sync
    ybnb_o           => ybnb,
   
    ---------------------------------------
    -- Diag port
    ---------------------------------------
    rx_top_diag0     => modem_diag0,
    rx_top_diag1     => modem_diag1,
    rx_top_diag2     => modem_diag2
    );  

  --------------------------------------
  -- Registers
  --------------------------------------
  modema2_registers_1: modema2_registers
   generic map (
     radio_interface_g => radio_interface_g)
   port map (
     --------------------------------
     -- Reset
     --------------------------------
     reset_n                   => reset_n,
     --------------------------------
     -- APB interface 
     --------------------------------
     apb_clk                   => pclk,
     apb_sel_i                 => psel_i,
     apb_enable_i              => penable_i,
     apb_write_i               => pwrite_i,
     apb_addr_i                => paddr_i,
     apb_wdata_i               => pwdata_i,
     apb_rdata_o               => prdata_o,
     --------------------------------
     -- Clocks control
     --------------------------------
     calib_test_o              => calib_test,
     --------------------------------
     -- Modules control signals for transmitter
     --------------------------------
     prbs_inv_o                => prbs_inv,
     prbs_sel_o                => prbs_sel,
     prbs_init_o               => prbs_init,
     tx_iq_phase_o             => tx_iq_phase_o,
     tx_iq_ampl_o              => tx_iq_ampl_o,
     add_short_pre_o           => add_short_pre,
     dac_powerdown_dyn_o       => dac_powerdown_dyn,
     tx_enddel_o               => tx_enddel,
     scrmode_o                 => scrmode,
     scrinitval_o              => scrinitval,
     tx_scrambler_i            => tx_scrambler,
     c2disb_tx_o               => c2disb_tx_o,
     tx_const_o                => tx_const_o,
     --------------------------------
     -- Module control signals for RX top sent to global state machine
     --------------------------------
     adc_powerdown_dyn_o       => adc_powerdown_dyn,
     --------------------------------
     -- Channel decoder control
     --------------------------------
     rx_length_limit_o         => length_limit,
     rx_length_chk_en_o        => rx_length_chk_en,
     --------------------------------
     -- RX IQ estimation
     --------------------------------
     iq_mm_estrst_o            => iq_mm_estrst,  --1 : restarts I/Q MM
     iq_mm_est_o               => iq_mm_est,  --1 : enables rx I/Q MM estimation.
     -- MDMaRXIQPRESET
     rx_iq_ph_preset_o         => rx_iq_ph_preset,  -- I/Q MM phase average preset.
     rx_iq_g_preset_o          => rx_iq_g_preset,  -- I/Q MM gain average preset.
     -- MDMaRXIQEST
     rx_iq_ph_est_i            => rx_iq_ph_est,  -- I/Q MM phase average estimation.
     rx_iq_g_est_i             => rx_iq_g_est,  -- I/Q MM gain average estimation.
     iq_mm_estrst_done_i       => iqmm_reset_done, -- I/Q MM reset done
     rx_iq_step_ph_o           => rx_iqmm_ph_step,
     rx_iq_step_g_o            => rx_iqmm_g_step,
     --------------------------------
     -- Time domain stat
     --------------------------------
     rx_ybnb_i                 => ybnb,
     rx_freq_off_est_i         => freq_off_est,
     --------------------------------
     -- Tx Rx filter
     --------------------------------
     tx_norm_factor_o          => tx_norm_o,
     tx_filter_bypass_o        => tx_filter_bypass_o,
     --------------------------------
     -- DC OFFSET
     --------------------------------
     rx_del_dc_cor_o           => rx_del_dc_cor_o,
     dc_off_disb_o             => dc_off_disb_o,
     --------------------------------
     -- Residual DC OFFSET
     --------------------------------
     res_dco_disb_o            => res_dco_disb,
     --------------------------------
     -- Rx 2's complement disable
     --------------------------------
     c2disb_rx_o               => c2disb_rx_o,
     --------------------------------
     -- Init sync
     --------------------------------
     detect_thr_carrier_o      => detect_thr_carrier,
     initsync_timoffst_o       => initsync_timoffst,
     initsync_autothr1_o       => initsync_autothr1,
     initsync_autothr0_o       => initsync_autothr0,
     --------------------------------
     -- Wiener filter
     --------------------------------
     wf_window_o               => wf_window,
     --------------------------------
     -- Equalizer
     --------------------------------
     satmaxncar54_o            => satmaxncar_54,
     satmaxncar48_o            => satmaxncar_48,
     satmaxncar36_o            => satmaxncar_36,
     satmaxncar24_o            => satmaxncar_24,
     satmaxncar18_o            => satmaxncar_18,
     satmaxncar12_o            => satmaxncar_12,
     satmaxncar9_o             => satmaxncar_09,
     satmaxncar6_o             => satmaxncar_06,
     histoffset54_o            => histoffset_54,
     histoffset48_o            => histoffset_48,
     histoffset36_o            => histoffset_36,
     histoffset24_o            => histoffset_24,
     histoffset18_o            => histoffset_18,
     histoffset12_o            => histoffset_12,
     histoffset9_o             => histoffset_09,
     histoffset6_o             => histoffset_06,
     reduceerasures_o          => reducerasures,
     --------------------------------
     -- IQ calibration signal generator
     --------------------------------
     calfrq0_o                 => calfrq0_o,
     calgain_o                 => calgain_o,
     calmode_o                 => calmode
     );

  -- Output register
  calmode_o     <= calmode;

 
end RTL;
