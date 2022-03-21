

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of modem802_11g_core is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant fsize_in_tx_ct  : integer := 10;
  constant fsize_out_tx_ct : integer := 8;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -------------
  -- 802.11g --
  -------------
  signal mode_force               : std_logic_vector(1 downto 0); -- register

  -------------
  -- 802.11a --
  -------------
  -- Signals for Modem 802.11a.
  signal a_phy_txstartend_req     : std_logic;
  signal a_phy_txstartend_conf    : std_logic;
  signal a_phy_rxstartend_ind     : std_logic;
  signal a_phy_data_req           : std_logic;
  signal a_phy_data_conf          : std_logic;
  signal a_phy_data_ind           : std_logic;
  signal a_rxv_datarate           : std_logic_vector( 3 downto 0);
  signal a_rxv_length             : std_logic_vector(11 downto 0);
  signal a_rxe_errorstat          : std_logic_vector( 1 downto 0);
  signal a_rxv_rssi               : std_logic_vector( 7 downto 0);
  signal a_rxv_service            : std_logic_vector(15 downto 0);
  signal a_rxdata                 : std_logic_vector( 7 downto 0);
  signal a_phy_ccarst_req         : std_logic;
  signal a_listen_start           : std_logic;
  signal modema_rx_gating_int     : std_logic; -- Gating condition Rx path
  signal modema_tx_gating_int     : std_logic; -- Gating condition Tx path
  signal a_phy_cca_ind_int        : std_logic; -- CCA status from ModemA
  signal a_rxv_service_ind        : std_logic;
  signal a_phy_ccarst_conf_int    : std_logic;
  signal a_txv_immstop            : std_logic;

  -------------
  -- 802.11b -- 
  -------------
  -- Signals for Modem 802.11b.
  signal b_phy_txstartend_req     : std_logic;
  signal b_phy_txstartend_conf    : std_logic;
  signal b_phy_rxstartend_ind     : std_logic;
  signal b_phy_data_req           : std_logic;
  signal b_phy_data_conf          : std_logic;
  signal b_phy_data_ind           : std_logic;
  signal b_rxv_datarate           : std_logic_vector( 3 downto 0);
  signal b_rxv_length             : std_logic_vector(11 downto 0);
  signal b_rxe_errorstat          : std_logic_vector( 1 downto 0);
  signal b_rxv_rssi               : std_logic_vector( 7 downto 0);
  signal b_rxv_service            : std_logic_vector( 7 downto 0);
  signal b_rxdata                 : std_logic_vector( 7 downto 0);
  signal b_phy_ccarst_req         : std_logic;
  signal b_listen_start           : std_logic;
  signal modemb_rx_gating_int     : std_logic; -- Gating condition Rx path
  signal modemb_tx_gating_int     : std_logic; -- Gating condition Tx path
  signal modemb_diag              : std_logic_vector(31 downto 0);
  signal b_phy_cca_ind_int        : std_logic; -- CCA status from ModemB
  signal b_txv_immstop            : std_logic;
  
  -- Signal for ports not yet implemented.
  signal all_zero                 : std_logic_vector(31 downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  all_zero <= (others => '0');

  -- unused signal
  b_rxv_rssi <= (others => '0');

  listen_start_o <= a_listen_start or b_listen_start;
  a_phy_cca_ind <= a_phy_cca_ind_int;
  b_phy_cca_ind <= b_phy_cca_ind_int;
  
  
  -----------------------------------------------------------------------------
  -- Gating condition :
  -- mode_force[1..0] : "00" -> 802.11g mode (normal mode)
  --                    "01" -> 802.11a mode
  --                    "10" -> 802.11b mode
  --                    "11" -> reserved
  -----------------------------------------------------------------------------
  -- Gating condition for Rx path .11a
  modema_rx_gating <= modema_rx_gating_int when mode_force(1) = '0' else '1';

  -- Gating condition for Tx path .11a
  modema_tx_gating <= modema_tx_gating_int when mode_force(1) = '0' else '1';

  -- Gating condition for Rx path .11b
  modemb_rx_gating <= modemb_rx_gating_int when mode_force(0) = '0' else '1';

  -- Gating condition for Tx path .11b
  modemb_tx_gating <= modemb_tx_gating_int when mode_force(0) = '0' else '1';

  agc_modeabg <= mode_force;
  
  ------------------------------------------------------------------------------
  -- 802.11g Registers Port map
  ------------------------------------------------------------------------------
  modemg_registers_1 : modemg_registers
  port map (
    -- clock and reset
    reset_n          => reset_n,
    pclk             => bus_clk,
    -- APB slave
    psel             => psel_g,
    penable          => penable,
    paddr            => paddr,
    pwrite           => pwrite,
    pwdata           => pwdata,
    --
    prdata           => prdata_modemg,
    -- MDMg11hSTAT register.
    ofdmcoex         => ofdmcoex,
    edtransmode_reset=> edtransmode_reset, 
    -- MDMgCNTL register.
    reg_modeabg      => mode_force,
    reg_tx_iqswap    => tx_iqswap,
    reg_rx_iqswap    => rx_iqswap,
    -- MDMgAGCCCA register.
    reg_deldc2       => deldc2_o,
    reg_longslot     => agc_longslot,
    reg_cs_max       => agc_wait_cs_max,  
    reg_sig_max      => agc_wait_sig_max, 
    reg_agc_disb     => agc_disb,
    reg_modeant      => agc_modeant,
    reg_edtransmode  => reg_edtransmode,
    reg_edmode       => reg_edmode,     
    -- MDMgADDESTMDUR register. 
    reg_addestimdura => reg_addestimdura,
    reg_addestimdurb => reg_addestimdurb,
    reg_rampdown     => reg_rampdown,
    -- MDMg11hCNTL register.
    reg_rstoecnt     => reg_rstoecnt   
    );
  
  ------------------------------------------------------------------------------
  -- Modem 802.11a2 Core Port map
  ------------------------------------------------------------------------------
  modem802_11a2_core_1 : modem802_11a2_core
  generic map (
    radio_interface_g       => radio_interface_g
    )
  port map (
    -- Clocks & Reset
    clk                     => modema_clk,
    rx_path_a_gclk          => rx_path_a_gclk,
    tx_path_a_gclk          => tx_path_a_gclk,
    fft_gclk                => fft_gclk,
    pclk                    => bus_clk,
--    reset_n                 => reset_n,
    reset_n                 => rstn_non_srpg_wild_sync,  -- For PSO
    mdma_sm_rst_n           => mdma_sm_rst_n,
    --
    rx_gating               => modema_rx_gating_int,
    tx_gating               => modema_tx_gating_int,
    --
    calib_test              => calib_test,

    -- WILD bup interface
    phy_txstartend_req_i    => a_phy_txstartend_req,
    txv_immstop_i           => a_txv_immstop,
    txv_length_i            => txv_length,
    txv_datarate_i          => txv_datarate,
    txv_service_i           => txv_service,
    txpwr_level_i           => txpwr_level,
    phy_data_req_i          => a_phy_data_req,
    bup_txdata_i            => bup_txdata,
    phy_txstartend_conf_o   => a_phy_txstartend_conf,
    phy_data_conf_o         => a_phy_data_conf,
    --                                                      
    phy_ccarst_req_i        => a_phy_ccarst_req,
    phy_rxstartend_ind_o    => a_phy_rxstartend_ind,
    rxv_length_o            => a_rxv_length,
    rxv_datarate_o          => a_rxv_datarate,
    rxv_rssi_o              => a_rxv_rssi,
    rxv_service_o           => a_rxv_service,
    rxv_service_ind_o       => a_rxv_service_ind,
    rxe_errorstat_o         => a_rxe_errorstat,
    phy_ccarst_conf_o       => a_phy_ccarst_conf_int,
    phy_cca_ind_o           => a_phy_cca_ind_int,
    phy_data_ind_o          => a_phy_data_ind,
    bup_rxdata_o            => a_rxdata,

    -- APB interface
    penable_i               => penable,
    paddr_i                 => paddr,
    pwrite_i                => pwrite,
    psel_i                  => psel_a,
    pwdata_i                => pwdata,
    prdata_o                => prdata_modema,

    -- Radio controller interface
    a_txonoff_conf_i        => a_txonoff_conf,
    a_rxactive_conf_i       => a_rxonoff_conf,
    a_txonoff_req_o         => a_txonoff_req,
    a_txbbonoff_req_o       => a_txbbonoff_req_o,
    a_txpga_o               => a_txpwr,
    a_rxactive_req_o        => a_rxonoff_req,
    --
    dac_on_o                => a_dac_enable,
    --
    adc_powerctrl_o         => open,
    --
    rssi_on_o               => open,
    --
    cca_busy_i              => cca_busy_a,
    listen_start_o          => a_listen_start,
    cp2_detected_o          => cp2_detected,

    -- Tx & Rx filter
    filter_valid_rx_i       => filter_valid_rx_i,
    rx_filtered_data_i      => rx_filtered_data_i,
    rx_filtered_data_q      => rx_filtered_data_q,    
    --
    tx_active_o             => tx_active_o,
    tx_filter_bypass_o      => tx_filter_bypass_o,
    filter_start_of_burst_o => filter_start_of_burst_o,
    filter_valid_tx_o       => filter_valid_tx_o,
    tx_norm_o               => tx_norm_o,
    tx_data2filter_i        => tx_data2filter_i,
    tx_data2filter_q        => tx_data2filter_q,

    -- Registers
    calmode_o               => calmode_o,
    calfrq0_o               => calfrq0_o,
    calgain_o               => calgain_o,
    tx_iq_phase_o           => tx_iq_phase_o,
    tx_iq_ampl_o            => tx_iq_ampl_o,
    rx_del_dc_cor_o         => rx_del_dc_cor_o,
    tx_const_o              => tx_const_o,
    dc_off_disb_o           => dc_off_disb_o,
    
    -- Diag. port
    c2disb_tx_o             => a_c2disb_tx_o,
    c2disb_rx_o             => a_c2disb_rx_o,
    modem_diag0             => modem_diag3,
    modem_diag1             => modem_diag4,
    modem_diag2             => modem_diag5,
    modem_diag3             => modem_diag6
    );


  ------------------------------------------------------------------------------
  -- Modem 802.11b Core Port map
  ------------------------------------------------------------------------------
  modem802_11b_core_1 : modem802_11b_core
  generic map (
    radio_interface_g => radio_interface_g)
  port map (
    -- clocks and reset
    bus_clk             => bus_clk,
    clk                 => modemb_clk,
    rx_path_b_gclk      => rx_path_b_gclk,
    tx_path_b_gclk      => tx_path_b_gclk,
    reset_n             => reset_n,
    --
    rx_gating           => modemb_rx_gating_int,
    tx_gating           => modemb_tx_gating_int,
   
    --------------------------------------------
    -- APB slave
    --------------------------------------------
    psel                => psel_b,
    penable             => penable,
    paddr               => paddr,
    pwrite              => pwrite,
    pwdata              => pwdata,
    --
    prdata              => prdata_modemb,
  
    --------------------------------------------
    -- Interface with Wild Bup
    --------------------------------------------
    -- inputs signals                                                          
    bup_txdata          => bup_txdata,
    phy_txstartend_req  => b_phy_txstartend_req,
    phy_data_req        => b_phy_data_req,
    phy_ccarst_req      => b_phy_ccarst_req,
    txv_length          => txv_length,
    txv_service         => txv_service(7 downto 0),
    txv_datarate        => txv_datarate,
    txpwr_level         => txpwr_level,
    txv_immstop         => b_txv_immstop,

    -- outputs signals                                                         
    phy_txstartend_conf => b_phy_txstartend_conf,
    phy_rxstartend_ind  => b_phy_rxstartend_ind,
    phy_data_conf       => b_phy_data_conf,
    phy_data_ind        => b_phy_data_ind,
    rxv_length          => b_rxv_length,
    rxv_service         => b_rxv_service,
    rxv_datarate        => b_rxv_datarate,
    rxe_errorstat       => b_rxe_errorstat,
    phy_cca_ind         => b_phy_cca_ind_int,          
    bup_rxdata          => b_rxdata,
   
    --------------------------------------------
    -- Radio controller interface
    --------------------------------------------
    rf_txonoff_conf     => b_txonoff_conf,
    rf_rxonoff_conf     => b_rxonoff_conf,
    --
    rf_txonoff_req      => b_txon,
    rf_rxonoff_req      => b_rxon,
    rf_dac_enable       => b_dac_enable,
   
    --------------------------------------------
    -- AGC
    --------------------------------------------
    agcproc_end         => agcproc_end,
    cca_busy            => cca_busy_b,
    correl_rst_n        => correl_rst_n,
    agc_diag            => agc_diag,
    --
    psdu_duration       => psdu_duration,
    correct_header      => correct_header,
    plcp_state          => plcp_state,
    plcp_error          => plcp_error,
    --
    listen_start_o      => b_listen_start,
    -- registers
    interfildisb        => interfildisb,
    ccamode             => ccamode,
    --
    sfd_found           => sfd_found,
    symbol_sync2        => symbol_sync2,
   
    --------------------------------------------
    -- Radio interface
    --------------------------------------------
    rf_rxi              => b_rxi,
    rf_rxq              => b_rxq,
   
    --------------------------------------------
    -- Disable Tx & Rx filter
    --------------------------------------------
    fir_disb            => fir_disb,
   
    --------------------------------------------
    -- Tx FIR controls
    --------------------------------------------
    init_fir            => init_fir,
    fir_activate        => fir_activate,
    fir_phi_out_tog_o   => fir_phi_out_tog_o,
    fir_phi_out         => fir_phi_out,
    tx_const            => tx_const,
    txc2disb            => txc2disb,
   
    --------------------------------------------
    --  Interface with RX Frontend
    --------------------------------------------
    rxc2disb            => rxc2disb,
    interp_disb         => interp_disb,
    clock_lock          => clock_lock,
    tlockdisb           => tlockdisb,
    gain_enable         => gain_enable,
    tau_est             => tau_est,
    enable_error        => enable_error,
    interpmaxstage      => interpmaxstage,
   
    --------------------------------------------
    -- Diagnostic port
    --------------------------------------------
    modem_diag          => modemb_diag,
    modem_diag0         => modem_diag0,
    modem_diag1         => modem_diag1,
    modem_diag2         => modem_diag2
    );


  ------------------------------------------------------------------------------
  -- Modems/BuP interface
  ------------------------------------------------------------------------------
  modemg2bup_if_1 : modemg2bup_if
    port map (
      -- Clocks & Reset
      reset_n                     => reset_n,
      bup_clk                     => bup_clk,
      modemb_clk                  => modemb_clk,
      modema_clk                  => modema_clk,
      -- Modem selection
      bup_txv_datarate3           => txv_datarate(3),
      select_rx_ab                => select_rx_ab,
      --------------------------------------
      -- Modems to BuP interface
      --------------------------------------
      -- Signals from Modem A
      a_phy_txstartend_conf       => a_phy_txstartend_conf,
      a_phy_rxstartend_ind        => a_phy_rxstartend_ind,
      a_phy_data_conf             => a_phy_data_conf,
      a_phy_data_ind              => a_phy_data_ind,
      a_phy_cca_ind               => a_phy_cca_ind_int,
      a_rxv_service_ind           => a_rxv_service_ind,
      a_phy_ccarst_conf           => a_phy_ccarst_conf_int,
      a_rxv_datarate              => a_rxv_datarate,
      a_rxv_length                => a_rxv_length,
      a_rxv_rssi                  => a_rxv_rssi,
      a_rxv_service               => a_rxv_service,
      a_rxe_errorstat             => a_rxe_errorstat,
      a_rxdata                    => a_rxdata,
      -- Signals from Modem B
      b_phy_txstartend_conf       => b_phy_txstartend_conf,
      b_phy_rxstartend_ind        => b_phy_rxstartend_ind,
      b_phy_data_conf             => b_phy_data_conf,
      b_phy_data_ind              => b_phy_data_ind,
      b_phy_cca_ind               => b_phy_cca_ind_int,
      b_rxv_datarate              => b_rxv_datarate,
      b_rxv_length                => b_rxv_length,
      b_rxv_rssi                  => b_rxv_rssi,
      b_rxv_service               => b_rxv_service,
      b_rxe_errorstat             => b_rxe_errorstat,
      b_rxdata                    => b_rxdata,
      -- Signals to BuP
      bup_phy_txstartend_conf     => phy_txstartend_conf,
      bup_phy_rxstartend_ind      => phy_rxstartend_ind,
      bup_phy_data_conf           => phy_data_conf,
      bup_phy_data_ind            => phy_data_ind,
      bup_phy_cca_ind             => phy_cca_ind,
      bup_rxv_service_ind         => rxv_service_ind,
      bup_a_phy_ccarst_conf       => a_phy_ccarst_conf,
      bup_rxv_datarate            => rxv_datarate,
      bup_rxv_length              => rxv_length,
      bup_rxv_rssi                => rxv_rssi,
      bup_rxv_service             => rxv_service,
      bup_rxe_errorstat           => rxe_errorstat,
      bup_rxdata                  => bup_rxdata,
      --------------------------------------
      -- BuP to Modems interface
      --------------------------------------
      -- Signals from BuP
      bup_phy_txstartend_req      => phy_txstartend_req,
      bup_phy_data_req            => phy_data_req,
      bup_phy_ccarst_req          => phy_ccarst_req,
      bup_rxv_macaddr_match       => bup_rxv_macaddr_match,
      bup_txv_immstop             => bup_txv_immstop,
      -- Signals to Modem A
      a_phy_txstartend_req        => a_phy_txstartend_req,
      a_phy_data_req              => a_phy_data_req,
      a_phy_ccarst_req            => a_phy_ccarst_req,
      a_rxv_macaddr_match         => open,
      a_txv_immstop               => a_txv_immstop,
      -- Signals to Modem B
      b_phy_txstartend_req        => b_phy_txstartend_req,
      b_phy_data_req              => b_phy_data_req,
      b_phy_ccarst_req            => b_phy_ccarst_req,
      b_rxv_macaddr_match         => open,
      b_txv_immstop               => b_txv_immstop
      );



end RTL;
