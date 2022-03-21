

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of rx_top is


  -- freq_domain
  signal data_valid_freq_domain        : std_logic;
  signal data_freq_domain              : std_logic;
  signal start_of_burst_freq_domain    : std_logic;

  -- rx_mac_if
  signal data_ready_mac                : std_logic;

  -- glb_cntl
  signal signal_field_unsupported_rate   : std_logic;
  signal signal_field_unsupported_length : std_logic;
  signal signal_field                    : std_logic_vector(17 downto 0);
  signal signal_field_valid              : std_logic;
  signal channel_decoder_end             : std_logic;
  signal signal_field_parity_error       : std_logic;
  -- glb enable and reset sync
  signal data_path_sync_res              : std_logic;
  signal low                             : std_logic;
  signal high                            : std_logic;

  -- Modem state machine
  signal preamb_detect                   : std_logic;

  -- Diag. port
  signal time_domain_diag0             : std_logic_vector(15 downto 0);
  signal time_domain_diag1             : std_logic_vector(11 downto 0);
  signal time_domain_diag2             : std_logic_vector(5 downto 0);
  signal freq_domain_diag              : std_logic_vector(6 downto 0);
  signal rx_gsm_state_o                : std_logic_vector(3 downto 0);
  signal rx_packet_end                 : std_logic;

begin

  low                  <= '0';
  high                 <= '1';
  rx_dpath_reset_n_o   <= data_path_sync_res;
  rx_packet_end_o      <= rx_packet_end;

  ---------------------------------
  -- Diag. port
  ---------------------------------
  rx_top_diag0 <= time_domain_diag0;
  rx_top_diag1 <= time_domain_diag1 & 
                  freq_domain_diag(6 downto 3);
  rx_top_diag2 <= data_path_sync_res &
                  channel_decoder_end &
                  time_domain_diag2 &
                  rx_gsm_state_o &
                  freq_domain_diag(2 downto 0) &
                  rx_packet_end;


  --------------------------------------------
  -- Time domain
  --------------------------------------------
  time_domain_1: time_domain
  port map (
    -- Clocks & Reset
    clk                         => gclk,   
    reset_n                     => reset_n,         
    -- Synchronous reset
    sync_reset_n                => data_path_sync_res,
    -- INIT sync
    detect_thr_carrier_i        => detect_thr_carrier_i,
    initsync_autothr0_i         => initsync_autothr0_i,
    initsync_autothr1_i         => initsync_autothr1_i,
    -- Samplefifo
    sampfifo_timoffst_i         => sampfifo_timoffst_i,
    -- Frequency correction
    freq_off_est_o              => freq_off_est_o,
    -- Preprocessing sample number before sync
    ybnb_o                      => ybnb_o,
    -- To FFT
    data_ready_i                => fft_data_ready_i,
    start_of_symbol_o           => td_start_of_symbol_o,
    data_valid_o                => td_data_valid_o, 
    start_of_burst_o            => td_start_of_burst_o,
    -- to global state machine
    preamb_detect_o             => preamb_detect,
    cp2_detected_o              => cp2_detected_o,
    -- I&Q
    i_iqcomp_i                  => i_iqcomp_i,
    q_iqcomp_i                  => q_iqcomp_i,
    iqcomp_data_valid_i         => iqcomp_data_valid_i,
    --
    i_o                         => td_i_o,
    q_o                         => td_q_o,
    --  Diag. port
    time_domain_diag0           => time_domain_diag0,
    time_domain_diag1           => time_domain_diag1,
    time_domain_diag2           => time_domain_diag2
  );
  
  
  --------------------------------------------
  -- Frequency domain
  --------------------------------------------
  freq_domain_1 : freq_domain
    port map (
      clk                        => gclk,
      reset_n                    => reset_n,
      sync_reset_n               => data_path_sync_res,
      -- from or_mac
      data_ready_i               => data_ready_mac,
      --from fft
      i_i                        => fft_i_i,
      q_i                        => fft_q_i,
      data_valid_i               => fft_data_valid_i,
      start_of_burst_i           => fft_start_of_burst_i,
      start_of_symbol_i          => fft_start_of_symbol_i,
      data_ready_o               => fd_data_ready_o,
      -- from rx_descr
      data_o                     => data_freq_domain,
      data_valid_o               => data_valid_freq_domain,
      rxv_service_o              => rxv_service_o,
      rxv_service_ind_o          => rxv_service_ind_o,
      start_of_burst_o           => start_of_burst_freq_domain,
      -----------------------------------------------------------------------
      -- Parameters
      -----------------------------------------------------------------------
      -- to wiener
      wf_window_i                => wf_window_i,
      -- to channel decoder
      length_limit_i             => length_limit_i,
      rx_length_chk_en_i         => rx_length_chk_en_i,
      -- to equalizer
      histoffset_54_i            => histoffset_54_i,
      histoffset_48_i            => histoffset_48_i,
      histoffset_36_i            => histoffset_36_i,
      histoffset_24_i            => histoffset_24_i,
      histoffset_18_i            => histoffset_18_i,
      histoffset_12_i            => histoffset_12_i,
      histoffset_09_i            => histoffset_09_i,
      histoffset_06_i            => histoffset_06_i,

      satmaxncarr_54_i           => satmaxncarr_54_i,
      satmaxncarr_48_i           => satmaxncarr_48_i,
      satmaxncarr_36_i           => satmaxncarr_36_i,
      satmaxncarr_24_i           => satmaxncarr_24_i,
      satmaxncarr_18_i           => satmaxncarr_18_i,
      satmaxncarr_12_i           => satmaxncarr_12_i,
      satmaxncarr_09_i           => satmaxncarr_09_i,
      satmaxncarr_06_i           => satmaxncarr_06_i,

      reducerasures_i                   => reducerasures_i, 
      -----------------------------------------------------------------------
      -- Control info interface
      -----------------------------------------------------------------------
      signal_field_o                    => signal_field,
      signal_field_parity_error_o       => signal_field_parity_error,
      signal_field_unsupported_rate_o   => signal_field_unsupported_rate,
      signal_field_unsupported_length_o => signal_field_unsupported_length,
      signal_field_valid_o              => signal_field_valid,
      end_of_data_o                     => channel_decoder_end,
      -----------------------------------------------------------------------
      -- Diag. port
      -----------------------------------------------------------------------
      freq_domain_diag                  => freq_domain_diag
      );


  --------------------------------------------
  -- RX MAC interface
  --------------------------------------------
  rx_mac_if_1 : rx_mac_if
    port map (
      clk                => gclk,
      reset_n            => reset_n,
      sync_reset_n       => data_path_sync_res,
      data_i             => data_freq_domain,
      data_valid_i       => data_valid_freq_domain,
      start_of_burst_i   => start_of_burst_freq_domain,
      packet_end_i       => rx_packet_end,
      data_ready_o       => data_ready_mac,
      rx_data_o          => bup_rxdata_o,
      rx_data_ind_o      => phy_data_ind_o
    );


  --------------------------------------------
  -- RX global state machine
  --------------------------------------------
  mdma2_rx_sm_1 : mdma2_rx_sm
    generic map (
      delay_chdec_sig_g  => 102,
      delay_datapath_g   => 413,
      worst_case_chdec_g => 150)
    port map (
      clk                         => clk,
      reset_n                     => reset_n,
      mdma_sm_rst_n               => mdma_sm_rst_n,
      reset_dp_modules_n_o        => data_path_sync_res,
      --
      calmode_i                   => calmode_i,
      rx_start_end_ind_o          => phy_rxstartend_ind_o,
      tx_dac_on_i                 => tx_dac_on_i,
      rxactive_req_o              => rxactive_req_o,
      rxactive_conf_i             => rxactive_conf_i,
      rx_packet_end_o             => rx_packet_end,
      enable_iq_estim_o           => enable_iq_estim_o,
      disable_output_iq_estim_o   => disable_output_iq_estim_o,
      rx_error_o                  => rxe_errorstat_o,
      rxv_length_o                => rxv_length_o,
      rxv_rate_o                  => rxv_datarate_o,
      rx_cca_ind_o                => phy_cca_ind_o,
      rx_ccareset_req_i           => phy_ccarst_req_i,
      rx_ccareset_confirm_o       => phy_ccarst_conf_o,
      signal_field_unsup_rate_i   => signal_field_unsupported_rate,
      signal_field_unsup_length_i => signal_field_unsupported_length,
      signal_field_i              => signal_field,
      signal_field_parity_error_i => signal_field_parity_error,
      signal_field_valid_i        => signal_field_valid,
      channel_decoder_end_i       => channel_decoder_end,
      listen_start_o              => listen_start_o,
      rssi_abovethr_i             => cca_busy_i,
      rssi_enable_o               => rssi_on_o,
      tdone_i                     => preamb_detect,
      adc_powerdown_dyn_i         => adcpdmod_i,
      adc_powctrl_o               => adc_powerctrl_o,
      rx_gsm_state_o              => rx_gsm_state_o
    );

  
end rtl;
