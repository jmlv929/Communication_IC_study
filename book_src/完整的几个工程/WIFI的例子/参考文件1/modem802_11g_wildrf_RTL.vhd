

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of modem802_11g_wildrf is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant fsize_in_tx_ct  : integer := 10;
  constant fsize_out_tx_ct : integer := 8;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal phy_rxstartend_ind_int: std_logic; -- indication of RX packet                     
  
  -------------------------------------------
  -- 802.11a
  -------------------------------------------
  -- Registers
  signal calmode               : std_logic;
  signal calfrq0               : std_logic_vector(22 downto 0);
  signal calgain               : std_logic_vector( 2 downto 0);
  signal tx_iq_phase           : std_logic_vector( 5 downto 0);
  signal tx_iq_ampl            : std_logic_vector( 8 downto 0);
  signal rx_del_dc_cor         : std_logic_vector( 7 downto 0);
  signal dc_off_disb           : std_logic;
  -- Tx/Rx filter
  signal tx_active             : std_logic;
  signal tx_filter_bypass      : std_logic;
  signal filter_start_of_burst : std_logic;
  signal filter_valid_tx       : std_logic;
  signal tx_norm               : std_logic_vector(7 downto 0);
  signal tx_data2filter_i      : std_logic_vector(fsize_in_tx_ct-1 downto 0);
  signal tx_data2filter_q      : std_logic_vector(fsize_in_tx_ct-1 downto 0);
  signal rx_filtered_data_i    : std_logic_vector(10 downto 0);
  signal rx_filtered_data_q    : std_logic_vector(10 downto 0);
  signal filter_valid_rx       : std_logic;
  -- Tx outputs
  signal a_txi_int             : std_logic_vector(9 downto 0);
  signal a_txq_int             : std_logic_vector(9 downto 0);
  -- 2's complement
  signal a_c2disb_tx           : std_logic;
  signal a_c2disb_rx           : std_logic;
  -- Signed value from reg of the constant to be sent
  signal a_txiconst            : std_logic_vector(7 downto 0);

  -------------------------------------------
  -- 802.11b
  -------------------------------------------
  -- Disable Tx & Rx filter
  signal fir_disb            : std_logic;
  -- Tx Filter
  signal init_fir            : std_logic;
  signal fir_activate        : std_logic;
  signal fir_phi_out         : std_logic_vector (1 downto 0);
  signal fir_phi_out_tog     : std_logic;
  signal b_txiconst          : std_logic_vector(7 downto 0); -- for constant generator
  -- Tx outputs
  signal b_txi_int           : std_logic_vector(7 downto 0);
  signal b_txq_int           : std_logic_vector(7 downto 0);
  -- AGC/CCA
  signal power_estim_en      : std_logic;
  signal integration_end     : std_logic;
  signal cca_busy_a          : std_logic;
  signal cca_busy_b          : std_logic;
  signal cca_busy_hiss       : std_logic;
  signal cca_busy_ana        : std_logic;
  signal cca_busy_b_ana      : std_logic;
  signal cca_busy_b_hiss     : std_logic;
  signal cca_busy_a_ana      : std_logic;
  signal cca_busy_a_hiss     : std_logic;
  signal ab_mode             : std_logic;
  signal cp2_detected        : std_logic;
  signal ed_stat             : std_logic;
  signal ed_stat_ana         : std_logic;
  signal ed_stat_hiss        : std_logic;
  signal correl_rst_n        : std_logic;
  signal power_estim_a       : std_logic_vector(18 downto 0);
  signal power_estim_b       : std_logic_vector(20 downto 0);
  signal psdu_duration       : std_logic_vector(15 downto 0);
  signal correct_header      : std_logic;
  signal plcp_state          : std_logic;
  signal plcp_error          : std_logic;
  signal agc_disb            : std_logic;
  signal interfildisb        : std_logic;
  signal ccamode             : std_logic_vector( 2 downto 0);
  signal sfd_found           : std_logic;
  signal symbol_sync2        : std_logic;

  signal rssi_s              : std_logic_vector(5 downto 0);
  signal a_rssi              : std_logic_vector(6 downto 0);
  
  signal listen_start        : std_logic;
  signal phy_txstartend_conf_s  : std_logic;
  signal a_rxonoff_req_s     : std_logic;
  signal b_rxonoff_req_s     : std_logic;
  
  -- ** Rx Front-End <-> Modem_802_11b_core Interface
  -- data signals from frent end
  signal rxi_fe              : std_logic_vector(7 downto 0);
  signal rxq_fe              : std_logic_vector(7 downto 0); 
  -- control
  signal dcoffdisb           : std_logic;
  signal txc2disb            : std_logic;
  signal rxc2disb            : std_logic;
  signal tx_iqswap           : std_logic;
  signal rx_iqswap           : std_logic;
  signal interp_disb         : std_logic;
  signal interp_max_stage    : std_logic_vector(5 downto 0);
  signal clock_lock          : std_logic;
  signal tlockdisb           : std_logic;
  signal tau_est             : std_logic_vector(17 downto 0);
  signal enable_error        : std_logic;
  signal gain_enable         : std_logic;
  signal gain_enable_n       : std_logic;
  signal scaling             : std_logic_vector(6 downto 0);

  -- Signals comming from Hiss controller.
  signal toggle_hiss_buffer : std_logic;
  signal rx_i_hiss_i        : std_logic_vector(7 downto 0);
  signal rx_q_hiss_i        : std_logic_vector(7 downto 0);
  signal clk_2skip_hiss_i   : std_logic;
  
  -- gating condition
  signal modemb_tx_gating_int : std_logic;
  signal modemb_rx_gating_int : std_logic;
  -------------------------------------------
  -- AGC
  -------------------------------------------
  signal agc_sync_rst_n    : std_logic;  -- Synchronous reset from AGC to reset
                                      -- filters and resynch block.
  signal filt_out_4_corr_i : std_logic_vector(9 downto 0);  -- These
  signal filt_out_4_corr_q : std_logic_vector(9 downto 0); -- outputs 

  signal agc_wait_cs_max  : std_logic_vector(3 downto 0);  -- Max time to wait for cca_cs
  signal agc_wait_sig_max : std_logic_vector(3 downto 0);  -- Max time to wait for
                                                     -- signal valid on
  signal agc_longslot             : std_logic;
  signal agc_modeabg              : std_logic_vector(1 downto 0);
  signal agc_hissbb_rx_onoff_req  : std_logic;
  signal mdma_sm_rst_n            : std_logic; -- synchronous reset for state machine .11a
  signal agc_hissbb_mdma_sm_rst_n : std_logic;
  ------------------------------------------
  -- Registers
  -------------------------------------------

  -- MDMg11hCNTL register.
  signal ofdmcoex            : std_logic_vector(7 downto 0);  -- Current value of the 
  -- MDMgADDESTMDUR register.
  signal reg_addestimdura    : std_logic_vector(3 downto 0); -- additional time duration 11a
  signal reg_addestimdurb    : std_logic_vector(3 downto 0); -- additional time duration 11b
  signal reg_rampdown        : std_logic_vector(2 downto 0); -- ramp-down time duration
  -- MDMg11hCNTL register.
  signal reg_rstoecnt        : std_logic;                    -- Reset OFDM Preamble Existence cnounter

    -- MDMgAGCCCA register.
  signal edtransmode_reset   : std_logic; -- Reset the edtransmode register     
  signal reg_edtransmode     : std_logic; -- Energy Detect Transitional Mode
  signal reg_edmode          : std_logic; -- Energy Detect Mode


  ------------------------------------------
  -- 802.11g
  -------------------------------------------
  signal a_phy_ccarst_conf   : std_logic;
  
  -- Signal for ports not yet implemented.
  signal all_zero               : std_logic_vector(31 downto 0);
  signal logic1                 : std_logic;
  signal logic0                 : std_logic;

  signal init_rx_b            : std_logic;
  signal init_rx_b_hiss       : std_logic;
  signal init_rx_b_ff1_resync : std_logic;
  signal init_rx_b_ff2_resync : std_logic;
  signal init_rx_b_ff3_resync : std_logic;
  signal deldc2          : std_logic_vector(4 downto 0);
  
  signal hiss_mode_int_n        : std_logic;
  signal rx_11a_enable          : std_logic;
  signal rx_11b_enable          : std_logic;
  signal rx_11a_enable_hiss     : std_logic;
  signal rx_11b_enable_hiss     : std_logic;
  signal select_rx_ab_hiss      : std_logic;
  signal rx_11a_enable_ana      : std_logic;
  signal rx_11b_enable_ana      : std_logic;
  signal phy_cca_ind_ana        : std_logic;
  signal agc_fake_rxonoff_req   : std_logic;
  signal rx_init_fake           : std_logic;
  signal agc_fake_mdma_sm_rst_n : std_logic;
  signal txi_int                : std_logic_vector(9 downto 0);
  signal txq_int                : std_logic_vector(9 downto 0);

  signal select_rx_ab : std_logic;

  -- FE specific
  signal txonoff_conf : std_logic;
  signal abmode       : std_logic;
  signal clkskip_int  : std_logic;

  -- For globals
  signal phy_data_conf_int   : std_logic;  -- last byte was read, ready for new one 
  signal phy_data_ind_int    : std_logic;  -- received byte ready   
  signal bup_rxdata_int      : std_logic_vector(7 downto 0);  -- data received 
  signal rxv_datarate_int    : std_logic_vector( 3 downto 0);  -- PSDU rec. rate
  signal rxv_length_int      : std_logic_vector(11 downto 0);  -- RX PSDU length       
  signal rxe_errorstat_int   : std_logic_vector( 1 downto 0);  -- packet recep. stat
  signal phy_cca_ind_int     : std_logic;  -- CCA status from Modems 
  signal rxv_rssi_int        : std_logic_vector( 6 downto 0);  -- rx rssi
  signal rxv_service_int     : std_logic_vector(15 downto 0);  -- rx service field
  signal rxv_service_ind_int : std_logic;
  signal phy_ccarst_conf_int : std_logic;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  all_zero <= (others => '0');
  logic1 <= '1';
  logic0 <= '0';

  dcoffdisb <= '1'; -- Disable dc offset into interference filter.

  phy_txstartend_conf <= phy_txstartend_conf_s;
  
  agc_ab_mode <= ab_mode when hiss_mode_int_n = '0'
            else agc_modeabg(1);
  
  agc_rx_onoff_req <= agc_hissbb_rx_onoff_req when hiss_mode_int_n = '0'
                 else agc_fake_rxonoff_req;
  
  a_rssi <= '0' & rssi_s;
  rssi_s <= (others => '0'); -- RSSI information is not available in the BB.
      
  
  a_rxonoff_req <= a_rxonoff_req_s;
  b_rxonoff_req <= b_rxonoff_req_s;
  
  sync_found    <= cp2_detected;
  
  phy_rxstartend_ind <= phy_rxstartend_ind_int;

  -- Gating condition
  modemb_rx_gating <= not (modemb_rx_gating_int or rx_11b_enable);
  modema_rx_gating <= not rx_11a_enable;
  modemb_tx_gating <= modemb_tx_gating_int and not rx_11b_enable;
  
  ------------------------------------------------------------------------------
  -- 802.11g Core Port Map
  ------------------------------------------------------------------------------
  modem802_11g_core_1 : modem802_11g_core
  generic map (
    radio_interface_g => radio_interface_g)
  port map (
    -- Clocks & Reset
    modema_clk          => modema_clk,
    rx_path_a_gclk      => rx_path_a_gclk,
    tx_path_a_gclk      => tx_path_a_gclk,
    modemb_clk          => modemb_clk,
    rx_path_b_gclk      => rx_path_b_gclk,
    tx_path_b_gclk      => tx_path_b_gclk,
    fft_gclk            => fft_gclk,
    bus_clk             => bus_clk,
    bup_clk             => bup_clk,
    reset_n             => reset_n,
    mdma_sm_rst_n       => mdma_sm_rst_n,
    --
    rstn_non_srpg_wild_sync => rstn_non_srpg_wild_sync,  -- For PSO
    --
    modema_rx_gating    => open,
    modema_tx_gating    => modema_tx_gating,
    modemb_rx_gating    => modemb_rx_gating_int,
    modemb_tx_gating    => modemb_tx_gating_int,
    --
    calib_test          => calib_test,
    -- APB interface
    psel_a              => psel_modema,
    psel_b              => psel_modemb,
    psel_g              => psel_modemg,
    penable             => penable,
    paddr               => paddr,
    pwrite              => pwrite,
    pwdata              => pwdata,
    prdata_modema       => prdata_modema,
    prdata_modemb       => prdata_modemb,
    prdata_modemg       => prdata_modemg,
    -- WILD bup interface
    bup_txdata            => bup_txdata,
    phy_txstartend_req    => phy_txstartend_req,
    phy_data_req          => phy_data_req,
    phy_ccarst_req        => phy_ccarst_req,
    txv_length            => txv_length,
    txv_service           => txv_service,
    txv_datarate          => txv_datarate,
    txpwr_level           => txpwr_level,
    bup_rxv_macaddr_match => rxv_macaddr_match,
    bup_txv_immstop       => txv_immstop,    
    select_rx_ab          => select_rx_ab, 
    --                                                      
    phy_txstartend_conf => phy_txstartend_conf_s,
    phy_rxstartend_ind  => phy_rxstartend_ind_int,
    a_phy_ccarst_conf   => a_phy_ccarst_conf,
    phy_data_conf       => phy_data_conf_int,
    phy_data_ind        => phy_data_ind_int,
    rxv_length          => rxv_length_int,
    rxv_rssi            => open,
    rxv_service         => rxv_service_int,
    rxv_service_ind     => rxv_service_ind_int,
    rxv_datarate        => rxv_datarate_int,
    rxe_errorstat       => rxe_errorstat_int,
    phy_cca_ind         => phy_cca_ind_ana,
    bup_rxdata          => bup_rxdata_int,
    -- Radio controller interface
    -- 802.11a side
    a_txonoff_conf      => a_txonoff_conf,
    a_rxonoff_conf      => a_rxonoff_conf,
    a_rssi              => a_rssi,
    a_txonoff_req       => a_txonoff_req,
    a_txbbonoff_req_o   => a_txbbonoff_req_o,
    a_rxonoff_req       => a_rxonoff_req_s,
    a_txpwr             => open,
    a_dac_enable        => a_dac_enable,
    --
    b_txonoff_conf      => b_txonoff_conf,
    b_rxonoff_conf      => b_rxonoff_conf,
    b_rxi               => rxi_fe,
    b_rxq               => rxq_fe,
    b_txon              => b_txonoff_req,
    b_rxon              => b_rxonoff_req_s,
    b_dac_enable        => b_dac_enable,
    -- Rssi above threshold for mdma2_rx_sm
    cca_busy_a          => cca_busy_a,
    -- AGC
    listen_start_o      => listen_start,
    cp2_detected        => cp2_detected,
    -- 802.11b TX front end
    fir_disb            => fir_disb,
    -- Tx
    init_fir            => init_fir,
    fir_activate        => fir_activate,
    fir_phi_out_tog_o   => fir_phi_out_tog,
    fir_phi_out         => fir_phi_out,
    tx_const            => b_txiconst,
    txc2disb            => txc2disb,
    -- 11b RX Frontend
    interp_disb         => interp_disb,
    clock_lock          => clock_lock,
    tlockdisb           => tlockdisb,
    gain_enable         => gain_enable,
    tau_est             => tau_est,
    enable_error        => enable_error,
    rxc2disb            => rxc2disb,
    interpmaxstage      => interp_max_stage,
    -- 802.11b AGC
    power_estim_en      => power_estim_en,
    integration_end     => integration_end,
    agcproc_end         => init_rx_b_ff2_resync,
    cca_busy_b          => cca_busy_b,
    correl_rst_n        => correl_rst_n,
    agc_diag            => all_zero(15 downto 0),
    agc_modeabg         => agc_modeabg,
    agc_longslot        => agc_longslot,
    agc_wait_cs_max     => agc_wait_cs_max,   -- Max time to wait for cca_cs
    agc_wait_sig_max    => agc_wait_sig_max,  -- Max time to wait for
    agc_modeant         => open,
    --
    power_estim         => open,
    psdu_duration       => psdu_duration,
    correct_header      => correct_header,
    plcp_state          => plcp_state,
    plcp_error          => plcp_error,
    --
    agc_disb            => agc_disb,
    interfildisb        => interfildisb,
    ccamode             => ccamode,
    --
    sfd_found           => sfd_found,
    symbol_sync2        => symbol_sync2,
    -- 802.11a2 front end
    filter_valid_rx_i       => filter_valid_rx,
    rx_filtered_data_i      => rx_filtered_data_i,
    rx_filtered_data_q      => rx_filtered_data_q,
    --
    tx_active_o             => tx_active,
    tx_filter_bypass_o      => tx_filter_bypass,
    filter_start_of_burst_o => filter_start_of_burst,
    filter_valid_tx_o       => filter_valid_tx,
    tx_norm_o               => tx_norm,
    tx_data2filter_i        => tx_data2filter_i,
    tx_data2filter_q        => tx_data2filter_q,
    -- Registers for wild rf front end
    calmode_o               => calmode,
    -- IQ calibration signal generator
    calfrq0_o               => calfrq0,
    calgain_o               => calgain,
    -- Modules control signals for transmitter
    tx_iq_phase_o           => tx_iq_phase,
    tx_iq_ampl_o            => tx_iq_ampl,
    rx_del_dc_cor_o         => rx_del_dc_cor,
    -- 2's complement
    a_c2disb_tx_o           => a_c2disb_tx,
    a_c2disb_rx_o           => a_c2disb_rx,
    -- DC waiting period.
    deldc2_o                => deldc2,
    dc_off_disb_o           => dc_off_disb,
    -- Constant generator
    tx_const_o              => a_txiconst,
    -- IQ swap
    tx_iqswap               => tx_iqswap,
    rx_iqswap               => rx_iqswap,
    -- MDMg11hSTAT register.
    ofdmcoex                => ofdmcoex,
    edtransmode_reset       => edtransmode_reset,
    -- MDMgADDESTMDUR register. 
    reg_addestimdura        => reg_addestimdura,
    reg_addestimdurb        => reg_addestimdurb,
    reg_rampdown            => reg_rampdown,
    -- MDMg11hCNTL register.
    reg_rstoecnt            => reg_rstoecnt, 
    reg_edtransmode         => reg_edtransmode,
    reg_edmode              => reg_edmode,
    -- Diagnostic port
    modem_diag0             => modem_diag0, -- modemb
    modem_diag1             => modem_diag1,
    modem_diag2             => modem_diag2,
    modem_diag3             => modem_diag6, -- modema Rx
    modem_diag4             => modem_diag7,
    modem_diag5             => modem_diag8,
    modem_diag6             => modem_diag9(8 downto 0) -- modema Tx
    );
  

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- FRONTEND ANALOG
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  FRONTEND_ANALOG_GEN : if radio_interface_g = 1 generate

    hiss_mode_int_n <= '1';

    ----------------------------------------------------------------------------
    -- 802.11g Front-end Port Map
    ----------------------------------------------------------------------------
    modem802_11g_frontend_1 : modem802_11g_frontend
    generic map(
      radio_interface_g => radio_interface_g,
--      use_sync_reset_g  => 1
      use_sync_reset_g  => 1
      )
    port map(
      -- Clocks & Reset
      rx_11a_clk                   => filta_clk,
      rx_11b_clk                   => filtb_clk,
      tx_11a_clk                   => filta_clk,
      tx_11b_clk                   => filtb_clk,
      tx_rx_filter_clk             => filta_clk,
      rx_path_b_gclk               => rx_path_b_gclk,
      modemb_clk                   => modemb_clk,
      interf_filter_clk            => filtb_clk,  -- Clock for rx_11b_interf_filter (60MHz)
      adc_pw_clk                   => filta_clk,  -- ????
      --
      reset_n                      => reset_n,
      tx_reset_n                   => reset_n,
      sync_reset_n                 => agc_sync_rst_n,
      interf_filter_reset_n        => reset_n,  -- Reset for rx_11b_interf_filter.
      tx_rx_filter_reset_n         => reset_n,
      -- Modem A interface
      txa_active_i                 => tx_active,
      txi_data2filter_i            => tx_data2filter_i,
      txq_data2filter_i            => tx_data2filter_q,
      filter_toggle_tx_i           => filter_valid_tx,
      filter_start_of_burst_i      => filter_start_of_burst,
      --
      rxa_filtered_data_i          => open, -- TBD
      rxa_filtered_data_q          => open, -- TBD
      rxa_filter_toggle_o          => open, -- TBD
      rxa_filter_pulse_o           => open, -- TBD
      -- Rxa DC offset pre-estimation - AGC interface
      sel_dc_mode                  => logic1, -- TBD
      dc_pre_estim_i               => open, -- TBD
      dc_pre_estim_q               => open, -- TBD
      dc_pre_estim_valid           => open, -- TBD
      -- DC offset estimation
      dc_off_4_11h_i               => open, -- TBD
      dc_off_4_11h_q               => open, -- TBD
      --
      rxa_synch_detect_i           => cp2_detected,
      dcadisbmode                  => all_zero(1 downto 0),  -- ????
      rxa_power_estim_o            => power_estim_a,
      --
      select_gain_digital_i        => all_zero(1 downto 0),
      rxa_out_i_o                  => rx_filtered_data_i,
      rxa_out_q_o                  => rx_filtered_data_q,
      rxa_out_toggle_o             => filter_valid_rx,
      -- Modem B interface
      txb_phi_angle_i              => fir_phi_out,
      fir_activate_i               => fir_activate,
      phi_angle_tog_i              => fir_phi_out_tog,
      txb_active_i                 => all_zero(0),
      txb_init_i                   => all_zero(0),
      --
      rxb_enable_i                 => logic1,
      h_b_select                   => logic0,  -- Select modem b for interf_filter.
      rx_i_interf_filter_o         => open,
      rx_q_interf_filter_o         => open,
      rxb_filt_4_corr_i_o          => filt_out_4_corr_i,
      rxb_filt_4_corr_q_o          => filt_out_4_corr_q,
      rxb_filter_down_toggle_o     => open,
      clock_lock_i                 => clock_lock,
      tlockdisb_i                  => tlockdisb,
      tau_est_i                    => tau_est,
      clk_skip_o                   => clkskip,
      timingoff_en_i               => enable_error,
      rxb_pw_estim_active_i        => power_estim_en,
      integration_end_i            => integration_end,
      rxb_power_estimation_o       => power_estim_b,
      rxb_gaindisb_i               => gain_enable_n,
      rxb_out_i_o                  => rxi_fe,
      rxb_out_q_o                  => rxq_fe,
      rxb_valid_o                  => open,
      clk_2skip_i                  => clk_2skip_i,
      -- Registers
      txa_filter_bypass_i          => tx_filter_bypass,
      txa_norm_i                   => tx_norm,
      abmode_i                     => abmode,
      tx_iq_phase_i                => tx_iq_phase,
      tx_iq_ampl_i                 => tx_iq_ampl,
      calmode_i                    => calmode,
      calfrq0_i                    => calfrq0,
      calgain_i                    => calgain,
      a_txiconst_i                 => a_txiconst,
      b_txiconst_i                 => b_txiconst,
      rxa_maxcount_4corr_i         => rx_del_dc_cor,
      rxa_dcoff_disb_i             => dc_off_disb,
      rxb_dcoff_disb_i             => dc_off_disb,
      rxa_coarsedc_comp_disb_i     => logic1,
      rxa_diggain_disb_i           => logic1,
      interf_filt_disb_i           => interfildisb,
      interf_filt_scaling_i        => scaling,
      interp_disb_i                => interp_disb,
      interp_max_stage_i           => interp_max_stage,
      b_fir_disb_i                 => fir_disb,
      attenuator_scale             => all_zero(5 downto 0),
      c2disb_tx_i                  => txc2disb,
      c2disb_rx_i                  => rxc2disb,
      txiqswap_i                   => tx_iqswap,
      rxiqswap_i                   => rx_iqswap,
      rfspeval_reg                 => all_zero(3 downto 0),
      -- Constant generator
      pa_on_i                      => pa_on,
      txonoff_conf_i               => txonoff_conf,
      rampup                       => all_zero(0),
      -- ADC/DAC
      dac_out_i                    => txi_int(7 downto 0),
      dac_out_q                    => txq_int(7 downto 0),
      adc_in_i                     => rxi(7 downto 0),
      adc_in_q                     => rxq(7 downto 0),
      -- Diag. port
      modem_diag                   => modem_diag3
      );


    txonoff_conf  <= a_txonoff_conf or b_txonoff_conf;
    abmode        <= '0' when tx_active = '1' else '1';
    gain_enable_n <= not gain_enable;

    -- Unused outputs
    txi_int(9 downto 8) <= (others => '0');
    txq_int(9 downto 8) <= (others => '0');
    a_txdatavalid       <= '0';
    b_txdatavalid       <= '0';

  end generate FRONTEND_ANALOG_GEN;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- FRONTEND HISS
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  FRONTEND_HISS_GEN : if radio_interface_g = 2 generate

  -- This generate is used when the modem has only a digital connection (HISS)
  -- to the radio. In this case, the block needs only wires connections.

    hiss_mode_int_n <= '0';
   
    -----------------
    -- 802.11a side
    -----------------
    -- Rx part
    rx_filtered_data_i <= rxi;
    rx_filtered_data_q <= rxq;
    filter_valid_rx    <= a_rxdatavalid;

    -- Tx part
    a_txdatavalid <= filter_valid_tx;

    -----------------
    -- 802.11b side
    -----------------
    -- Tx part
    b_txdatavalid <= fir_phi_out_tog  ;  -- only used with HiSS

    -- Rx part
    hiss_buffer_1 : hiss_buffer -- Resynchronized 60Mhz clock domain
    generic map (               --  to 44Mhz clock domain.
      buf_size_g  => 4,
      rx_length_g => 8)
    port map (
      reset_n       => reset_n,
      clk_44        => modemb_clk,
      clk_44g       => rx_path_b_gclk,
      -- Controls
      hiss_buf_init => init_rx_b_ff2_resync,
      toggle_i      => toggle_hiss_buffer,
      -- Input data.
      rx_i_i        => rx_i_hiss_i,
      rx_q_i        => rx_q_hiss_i,
      clk_2skip_i   => clk_2skip_hiss_i,
      -- Output data.
      rx_i_o        => rxi_fe,
      rx_q_o        => rxq_fe,
      clkskip_o     => clkskip_int
      );

    -- 802.11 a/b common
    txi_int <= tx_data2filter_i when tx_active = '1' else
               "000000000" & fir_phi_out(1);
    txq_int <= tx_data2filter_q when tx_active = '1' else
               "000000000" & fir_phi_out(0);

    -- output port
    clkskip <= clkskip_int;

    -- Diag port
    modem_diag3(0) <= filtb_clk;
    modem_diag3(4 downto 1) <= rx_i_hiss_i(3 downto 0);
    modem_diag3(5) <= '0';
    modem_diag3(6) <= '0';
    modem_diag3(7) <= clkskip_int;
    modem_diag3(15 downto 8) <= rxi_fe;

  end generate FRONTEND_HISS_GEN;



  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- FRONTEND ANALOG AND HISS
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  FRONTEND_ANALOG_AND_HISS_GEN : if radio_interface_g = 3 generate

    hiss_mode_int_n <= hiss_mode_n;

    ----------------------------------------------------------------------------
    -- 802.11a2 Components
    ----------------------------------------------------------------------------
    -------------------------------------------
    -- 802.11a2 front end port map
    -------------------------------------------
    modem802_11a2_frontend_1: modem802_11a2_frontend
    generic map(
      radio_interface_g => radio_interface_g -- 0 -> reserved
      )                                      -- 1 -> only Analog interface
                                             -- 2 -> only HISS interface
    port map(                                -- 3 -> both interfaces (HISS and Analog)
      -- Clocks & Reset
      sampling_clk            => filta_clk,
      reset_n                 => reset_n,
      -- HISS mode
      hiss_mode_n             => hiss_mode_n,
      -- Tx & Rx filter
      tx_active_i             => tx_active,
      tx_filter_bypass_i      => tx_filter_bypass,
      filter_start_of_burst_i => filter_start_of_burst,
      filter_valid_tx_i       => filter_valid_tx,
      tx_norm_i               => tx_norm,
      tx_data2filter_i        => tx_data2filter_i,
      tx_data2filter_q        => tx_data2filter_q,
      --
      rx_filtered_data_i      => rx_filtered_data_i,
      rx_filtered_data_q      => rx_filtered_data_q,
      filter_valid_rx_o       => filter_valid_rx,
      -- Radio controller
      a_rxi                   => rxi,
      a_rxq                   => rxq,
      a_rxdatavalid           => a_rxdatavalid,
      --
      a_txi                   => a_txi_int,
      a_txq                   => a_txq_int,
      a_txdatavalid           => a_txdatavalid,
      --
      pa_on                   => pa_on,
      txonoff_conf            => a_txonoff_conf,
      -- Init sync
      cp2_detected            => cp2_detected,
      -- AGC
      cca_busy                => agc_sync_rst_n,
      power_estim             => power_estim_a,
      -- Registers
      -- calibration_mux
      calmode_i               => calmode,
      -- IQ calibration signal generator
      calfrq0_i               => calfrq0,
      calgain_i               => calgain,
      -- Modules control signals for transmitter
      tx_iq_phase_i           => tx_iq_phase,
      tx_iq_ampl_i            => tx_iq_ampl,
      -- dc offset
      maxcount_4corr          => rx_del_dc_cor,
      dc_off_disb             => dc_off_disb,
      -- Control for 2's complement.
      c2disb_tx_i             => a_c2disb_tx,
      c2disb_rx_i             => a_c2disb_rx,
      -- Signed value from reg of the constant to be sent
      a_txiconst              => a_txiconst
      );


    ------------------------------------------------------------------------------
    -- 802.11b Components
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    -- TX B Front End
    ------------------------------------------------------------------------------
    tx_b_frontend_wildrf_1: tx_b_frontend_wildrf
      generic map (
        out_length_g      => 7,
        phi_degree_g      => 5,
        radio_interface_g => radio_interface_g)
      port map (
        -- Clocks & Reset
        clk_44        => tx_path_b_gclk,
        clk_60        => filtb_clk,
        reset_n       => reset_n,
        -- Signals
        hiss_enable_n => hiss_mode_n,    -- when high, the analog interface is selected
        fir_activate  => fir_activate,   -- activate the block (when disact, it finishes the transfer) 
        c2disb        => txc2disb,
        fir_disb      => fir_disb,       -- when disb, i and q are transfered without modif
        phi_angle_tog => fir_phi_out_tog,-- toggle when new data
        phi_angle     => fir_phi_out,    -- phi input
        pa_on         => pa_on,
        b_txiconst    => b_txiconst,
        -- Outputs Signals : Data to radio_controller
        tx_val_tog    => b_txdatavalid,
        tx_i_o        => b_txi_int,
        tx_q_o        => b_txq_int
        );


    ------------------------------------------------------------------------------
    -- RX B Front End
    ------------------------------------------------------------------------------
    rx_b_front_end_wildrf_1: rx_b_front_end_wildrf
      generic map (
        radio_interface_g => radio_interface_g,
        rx_length_g       => 7,
        m_size_g          => 7)
      port map (
      -- Clocks & Reset
        reset_n                  => reset_n,
        interf_filter_reset_n    => reset_n,  -- Reset for rx_11b_interf_filter.
        filtb_clk                => filtb_clk,     -- 60 MHz clock
        rx_path_b_gclk           => rx_path_b_gclk,-- gated 44 MHz clock 
        modemb_clk               => modemb_clk,    -- 44 MHz clock
        interf_filter_clk        => filtb_clk,  -- Clock for rx_11b_interf_filter.
        -- Controls
        rx_i_i                   => rxi(7 downto 0),
        rx_q_i                   => rxq(7 downto 0),
        hiss_mode_n              => hiss_mode_n,
        rx_val_tog               => b_rxdatavalid,
        -- AGC
        agc_sync_rst_n           => agc_sync_rst_n,  -- Synchronous reset from AGC to reset
                                          -- filters and resynch block.
        filt_out_4_corr_i        => filt_out_4_corr_i, 
        filt_out_4_corr_q        => filt_out_4_corr_q, 
        -- Control for 2's complement.
        c2disb                   => rxc2disb,
        -- Control for interference filter
        dcoffdisb                => dcoffdisb,
        h_b_select               => logic0,  -- =1: modem_11h, =0 : modem_11b
        interf_filter_disable    => interfildisb,
        scaling                  => scaling(3 downto 0),
        rx_i_interf_filter_o     => open,  -- for modem h.
        rx_q_interf_filter_o     => open,  -- for modem h.
        -- Control for interpolator
        interp_disb              => interp_disb,
        interp_max_stage_i       => interp_max_stage,
        clock_lock               => clock_lock,
        tlockdisb                => tlockdisb,
        tau_est                  => tau_est,
        clk_skip                 => clkskip,
        -- Control for timingoff_estim.
        timingoff_en             => enable_error,
        -- Control for power_estimation
        pw_estim_activate        => power_estim_en,
        integration_end          => integration_end,
        power_estimation         => power_estim_b,
        -- Control for filter-Downsampling_44to22
        fir_disb                 => fir_disb,
        -- Control for gain compensation.
        gain_enable              => gain_enable,
        -- Control for resync_buf
        clk_2skip                => clk_2skip_i,
        --
        rx_i_o                   => rxi_fe,
        rx_q_o                   => rxq_fe,
        -- Control for hiss_buff
        hiss_buf_init            => init_rx_b_ff2_resync,
        toggle_hiss_buffer       => toggle_hiss_buffer,
        rx_i_hiss_i              => rx_i_hiss_i,
        rx_q_hiss_i              => rx_q_hiss_i,
        clk_2skip_hiss_i         => clk_2skip_hiss_i,
        -- Diag ports.
        modem_diag               => modem_diag3
        );

    -- 802.11 a/b common
    txi_int <= a_txi_int when tx_active = '1' else "00" & b_txi_int;
    txq_int <= a_txq_int when tx_active = '1' else "00" & b_txq_int;

  
  end generate FRONTEND_ANALOG_AND_HISS_GEN;

  -- Assign Tx output
  txi <= txi_int;
  txq <= txq_int;

  -- fir_activate (which is similar to tx_activated) indicate when data are
  -- coming to the hiss interface (from tx_path_core).  
  b_txbbonoff_req <= fir_activate;

  -- Setting of data coming from Hiss controller.
  toggle_hiss_buffer <= b_rxdatavalid;
  rx_i_hiss_i        <= rxi(7 downto 0);
  rx_q_hiss_i        <= rxq(7 downto 0);
  clk_2skip_hiss_i   <= clk_2skip_i;
  


  -------------------------------------------
  -- AGC CCA
  -------------------------------------------
  scaling     <= "0000011"; --debug : !! Connect to AGC when AGC READY !!
  agc_sync_rst_n <= '1' when hiss_mode_int_n ='0'
               else  rx_11a_enable_ana or rx_11b_enable_ana; -- in Hiss mode:
                                           -- in the BB: signal connected to '1'
                                           -- in the RF: signal driven by the AGC block

  correl_rst_n <= not init_rx_b_ff3_resync;
  
  agc_cca_hissbb_1 : agc_cca_hissbb
  port map(
    -- Clocks & Reset
    clk     => rcagc_main_clk,             -- 80 MHz
    reset_n => reset_n,
    -- Registers

    -- cca_mode used only for 11b
    -- 000: Reserved, 001: Carrier Sense only, 010: Carrier Sense Only
    -- 011 Carrier sense with energy above threshold
    -- 100: Carrier sense with timer
    -- 101: A combination of carrier sense and energy above threshold
    cca_mode     => ccamode,
    modeabg      => agc_modeabg,  -- Reception Mode 11a(01) 11b(10) 11g(00)
    deldc2       => deldc2,       -- Delay for DC loop convergence
    longslot     => agc_longslot,      -- Long slot mode => 1
                                       -- Short slot mode=> 0
    wait_cs_max  => agc_wait_cs_max,   -- Max time to wait for cca_cs
    wait_sig_max => agc_wait_sig_max,  -- Max time to wait for
                                       -- signal valid on    
    select_clk80 => select_clk80,       -- Clock used is at 80 MHz
    edtransmode_reset => edtransmode_reset,  -- Reset the Energy Detect Transitional Mode
    -- MDMgADDESTMDUR register. 
    reg_addestimdura => reg_addestimdura,
    reg_addestimdurb => reg_addestimdurb,
    reg_rampdown     => reg_rampdown,
    reg_edtransmode  => reg_edtransmode,  -- Energy Detect Transitional Mode
    reg_edmode       => reg_edmode,       -- Energy Detect Mode
    -- Modem 11a
    cp2_detected      => cp2_detected,             -- Indicates synchronization has been found
    rx_11a_enable     => rx_11a_enable_hiss,       -- Enables .11a RX path block
    modem_a_fsm_rst_n => agc_hissbb_mdma_sm_rst_n, -- Reset SM modem a
    rxv_length        => rxv_length_int,           -- Rx Length
    rxv_datarate      => rxv_datarate_int,         -- RX Rate
    rxe_errorstat     => rxe_errorstat_int,        -- RX Error Status
    -- Modem 11b
    sfd_found        => sfd_found,           -- SFD has been detected when hi           
    packet_length    => psdu_duration,       -- Packet length in us                     
    energy_detect    => ed_stat_hiss,             -- Energy above threshold                  
    cca_busy         => cca_busy_hiss,          -- Indicates correlation result=>           
                                                -- a signal is present when high           
    init_rx          => init_rx_b_hiss,           -- Initializes the modem 11b               
    rx_11b_enable    => rx_11b_enable_hiss,    -- Enables .11b RX path bloc               
    -- BUP
    phy_rxstartend_ind => phy_rxstartend_ind_int,  -- Indicates start/end of Rx packe
    phy_txstartend_req => phy_txstartend_req,  --   Indicates start/end of transmissi
    phy_ccarst_req     => phy_ccarst_req,      --   Reset AGC procedu
    rxv_macaddr_match  => rxv_macaddr_match,   -- Stop the reception because the mac 
                                               -- addresss does not match   
    phy_ccarst_conf    => phy_ccarst_conf_int, --   Acknowledges reset request
    phy_cca_ind        => phy_cca_ind_int,
    rxv_rssi           => rxv_rssi_int,       -- Value of measured RSSI
    rxv_rxant          => rxv_rxant,          -- Antenna used
    rxv_ccaaddinfo     => rxv_ccaaddinfo,     -- Additionnal data
    select_rx_ab       => select_rx_ab_hiss,
    -- Radio Controller
    cca_flags          => agc_cca_flags,         -- Indicates CCA procedure stat
    cca_add_flags      => agc_cca_add_flags,     -- Additional CCA data
    cca_flags_marker   => agc_cca_flags_marker,  -- Pulse to indicate cca_flags are val
    cca_cs             => agc_cca_cs,
    agc_rxonoff_conf   => agc_rx_onoff_conf,     -- Acknowledges start/end of Rx packet
    sw_rfoff_req       => sw_rfoff_req,   -- pulse resquest by SW to switch idle the WiLDRF  

    cca_cs_valid       => agc_cca_cs_valid,      -- Pulse to indicate cca_cs are valid
    agc_disb           => agc_disb,              -- Disable AGC procedure
    a_b_mode           => ab_mode,           -- Indicates the reception mode
    hiss_stream_enable => agc_stream_enable,    -- Enable Hiss master to receive data
    agc_rfoff          => agc_rfoff,  -- Indicates that the WiLD RF can be switch off
    agc_rfint          => agc_rfint,  -- Interrupt from WiLDRF
    agc_rxonoff_req    => agc_hissbb_rx_onoff_req,     -- Indicates start/end of Rx packet
    agc_busy           => agc_busy,   -- Indicates when receiving a packet(Including RF config)
    -- WLAN Reception
    wlanrxind          => wlanrxind,  -- Indicates a WLAN reception
    -- Diag port
    agc_cca_hissbb_diag_port => agc_cca_diag0
    );


  ofdm_preamble_detector_1 : ofdm_preamble_detector
  port map (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n         =>  reset_n,
    clk             =>  rcagc_main_clk,
    --------------------------------------
    -- Controls
    --------------------------------------
    reg_rstoecnt    => reg_rstoecnt,
    a_b_mode        => select_rx_ab,
    cp2_detected    => cp2_detected,
    rxe_errorstat   => rxe_errorstat_int,
    phy_cca_ind     => phy_cca_ind_int,
    ofdmcoex        => ofdmcoex
  );






  AGC_ANALOG_FAKE_GEN : if (radio_interface_g = 1 or radio_interface_g = 3) generate

    agc_cca_analog_fake_1 : agc_cca_analog_fake
    port map(
      --------------------------------------
      -- Clocks & Reset
      --------------------------------------
      clk                 => rcagc_main_clk,             -- 80 MHz
      reset_n             => reset_n,

      --------------------------------------
      -- Registers
      --------------------------------------

      modeabg             => agc_modeabg, -- Reception Mode 11a(01) 11b(10) 11g(00)
      rf_cca              => rf_cca,
      phy_rxstartend_ind  => phy_rxstartend_ind_int,
      phy_txstartend_req  => phy_txstartend_req,
      
      agc_rxonoff_req     => agc_fake_rxonoff_req,
      
      rx_init             => rx_init_fake,
      rx_11a_enable       => rx_11a_enable_ana,
      rx_11b_enable       => rx_11b_enable_ana,
      cca_busy            => cca_busy_ana,
      energy_detect       => ed_stat_ana,
      power_estim_en      => power_estim_en,
      integration_end     => integration_end
    );

  end generate AGC_ANALOG_FAKE_GEN;

  cca_busy_b_hiss <= cca_busy_hiss and ab_mode;
  cca_busy_a_hiss <= cca_busy_hiss and not ab_mode;

  cca_busy_b_ana <= cca_busy_ana when agc_modeabg = "10" else '0';
  cca_busy_a_ana <= cca_busy_ana when agc_modeabg = "01" else '0';
  
  
  agc_fake_mdma_sm_rst_n <= not rx_init_fake;
  
  mdma_sm_rst_n  <= agc_fake_mdma_sm_rst_n when hiss_mode_int_n = '1' else agc_hissbb_mdma_sm_rst_n;
  
  
  cca_busy_b    <= cca_busy_b_ana    when hiss_mode_int_n = '1' else cca_busy_b_hiss;
  cca_busy_a    <= cca_busy_a_ana    when hiss_mode_int_n = '1' else cca_busy_a_hiss;
  ed_stat       <= ed_stat_ana       when hiss_mode_int_n = '1' else ed_stat_hiss;
  init_rx_b     <= rx_init_fake      when hiss_mode_int_n = '1' else init_rx_b_hiss;
  rx_11a_enable <= rx_11a_enable_ana when hiss_mode_int_n = '1' else rx_11a_enable_hiss;
  rx_11b_enable <= rx_11b_enable_ana when hiss_mode_int_n = '1' else rx_11b_enable_hiss;
  select_rx_ab  <= rx_11b_enable_ana when hiss_mode_int_n = '1' else select_rx_ab_hiss;


  ---------------------------------------------
  -- Resynchronization of control
  -- signals going from AGC to hiss_buffer and
  -- modem b
  ---------------------------------------------
  resync_modemb_hiss_buff_p: process (modemb_clk, reset_n)
  begin
    if reset_n = '0' then
      init_rx_b_ff1_resync <= '0';
      init_rx_b_ff2_resync <= '0';
      init_rx_b_ff3_resync <= '0';
    elsif modemb_clk'event and modemb_clk = '1' then
      init_rx_b_ff1_resync <= init_rx_b;
      init_rx_b_ff2_resync <= init_rx_b_ff1_resync;
      init_rx_b_ff3_resync <= init_rx_b_ff2_resync;
    end if;
  end process resync_modemb_hiss_buff_p;

  -----------------------------------------------------------------------------
  -- Diag. ports
  -----------------------------------------------------------------------------
  -- Common diag. port
  modem_diag4 <= txq_int(7 downto 0) & txi_int(7 downto 0);
  modem_diag5 <= rxq(7 downto 0) & rxi(7 downto 0);
  -- Tx diag.
  modem_diag9(15 downto 9) <= '0' &
                              filta_clk &
                              '0' &
                              '0' &
                              filtb_clk &
                              '0' &
                              phy_txstartend_req;  

-- Output assignement for intermediate signals used as globals.
  phy_data_conf   <= phy_data_conf_int;
  phy_data_ind    <= phy_data_ind_int;
  bup_rxdata      <= bup_rxdata_int;
  rxv_datarate    <= rxv_datarate_int;
  rxv_length      <= rxv_length_int;
  rxe_errorstat   <= rxe_errorstat_int;
  phy_cca_ind     <= phy_cca_ind_ana when hiss_mode_int_n = '1'
                else phy_cca_ind_int;
  rxv_service     <= rxv_service_int;
  rxv_service_ind <= rxv_service_ind_int;
  phy_ccarst_conf <= phy_ccarst_conf_int;
  rxv_rssi        <= rxv_rssi_int;


-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off
--
-- Output assignement for global signals.                                     
--  phy_txstartend_conf_gbl <= phy_txstartend_conf_s;
--  phy_data_req_gbl        <= phy_data_req;
--  phy_data_conf_gbl       <= phy_data_conf_int;
--  bup_txdata_gbl          <= bup_txdata;
--  txv_datarate_gbl        <= txv_datarate;
--  txv_length_gbl          <= txv_length;
--  txpwr_level_gbl         <= txpwr_level;
--  txv_service_gbl         <= txv_service;
  --
--  phy_rxstartend_ind_gbl  <= phy_rxstartend_ind_int;
--  phy_data_ind_gbl        <= phy_data_ind_int;
--  bup_rxdata_gbl          <= bup_rxdata_int;
--  rxv_datarate_gbl        <= rxv_datarate_int;
--  rxv_length_gbl          <= rxv_length_int;
--  rxe_errorstat_gbl       <= rxe_errorstat_int;
--  phy_cca_ind_gbl         <= phy_cca_ind_int;
--  rxv_rssi_gbl            <= rxv_rssi_int;
--  rxv_service_gbl         <= rxv_service_int;
--  rxv_service_ind_gbl     <= rxv_service_ind_int;
--  phy_ccarst_req_gbl      <= phy_ccarst_req;
--  phy_ccarst_conf_gbl     <= phy_ccarst_conf_int;
--  bup_txdata_gbl          <= bup_txdata;
--  phy_data_req_gbl        <= phy_data_req;
--
  -- Modem B Globals.
--  rx_path_b_gclk_gbl      <= rx_path_b_gclk;
--  modemb_clk_gbl          <= modemb_clk;
--  rxi_fe_gbl              <= rxi_fe;
--  rxq_fe_gbl              <= rxq_fe;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on 

end RTL;
