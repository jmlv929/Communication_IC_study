

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of modem802_11b_core is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- MDMbRFDEL register.
  -- signals for resynchronization.
  signal tlockdisb_int       : std_logic;
  signal rxc2disb_int        : std_logic;
  signal interp_disb_int_int : std_logic;
  signal iqmmdisb_int        : std_logic;
  signal gaindisb_int        : std_logic;
  signal precompdisb_int     : std_logic;
  signal dcoffdisb_int       : std_logic;
  signal comp_disb_int       : std_logic;
  signal eq_disb_int         : std_logic;
  signal fir_disb_int        : std_logic;
  signal spread_disb_int     : std_logic;
  signal scrambling_disb_int : std_logic;
  signal interfildisb_int    : std_logic;
  signal txc2disb_int        : std_logic;
  -- Registers signals.
  signal scrambling_disb     : std_logic;  -- disable the scrambling
  signal spread_disb         : std_logic;  -- disable the spreading
  signal eq_disb             : std_logic;  -- disable the equalizer
  signal comp_disb           : std_logic;  -- disable the compensation (error calc)
  signal iqmmdisb            : std_logic;  -- disable I/Q mismatch compensation.
  signal gaindisb            : std_logic;  -- disable the gain compensation.
  signal sfd_detect_enable   : std_logic;  -- enable SFD detection when high
  signal rxlenchken          : std_logic;  -- select ckeck on rx data lenght.
  signal rxmaxlength         : std_logic_vector(11 downto 0);  -- Max accepted received length.
  signal iq_gain_sat_stat    : std_logic_vector(6 downto 0);
  signal dc_offset_i_stat    : std_logic_vector(5 downto 0);
  signal dc_offset_q_stat    : std_logic_vector(5 downto 0);
  signal coeff_sum_i_stat    : std_logic_vector(7 downto 0);
  signal coeff_sum_q_stat    : std_logic_vector(7 downto 0);
  signal freqoffestim_stat   : std_logic_vector(7 downto 0);
  --signal timoffdisb        : std_logic; -- disable timing offset compensation.
  signal precompdisb         : std_logic;  -- disable timing offset compensation.
  signal dcoffdisb           : std_logic;  -- disable the DC offset compensation.
  signal interp_disb_int     : std_logic;  -- disable interpolator
  signal preamble_type_tx    : std_logic;
  signal preamble_type_rx    : std_logic;
  signal seria_data_conf     : std_logic;  -- Serializer is ready for new data
  signal scr_data_in         : std_logic_vector(7 downto 0);  -- data sent to scr
  signal rx_data             : std_logic_vector(7 downto 0);  -- data sent to scr
  signal sm_data_req         : std_logic;  -- State machines data request
  signal tx_psk_mode         : std_logic;  -- 0 = BPSK; 1 = QPSK
  signal rx_psk_mode         : std_logic;  -- 0 = BPSK; 1 = QPSK
  signal tx_activated        : std_logic;  -- indicate when tx_path has finished
  signal sfd_found_int       : std_logic;  -- high when SFD is found on RX
  signal byte_ind            : std_logic;  -- pulse when an RX byte is available
                                           -- from RX path
  signal activate_seria      : std_logic;  -- activate Serializer
  signal shift_period        : std_logic_vector(3 downto 0);  -- Serializer speed
  signal activate_cck        : std_logic;  -- activate CCK modulator
  signal rx_cck_rate         : std_logic;  -- CCK speed (0 = 5.5 Mb/s; 1 = 11 Mb/s)
  signal tx_cck_rate         : std_logic;  -- CCK speed (0 = 5.5 Mb/s; 1 = 11 Mb/s)
  signal crc_out_1st         : std_logic_vector( 7 downto 0);  -- CRC 1st data 
  signal crc_out_2nd         : std_logic_vector( 7 downto 0);  -- CRC 2nd data
  signal crc_data            : std_logic_vector(15 downto 0);  -- CRC 1+2 data
  signal crc_init            : std_logic;  -- init CRC computation
  signal crc_data_valid      : std_logic;  -- compute CRC on packet header
  signal data_to_crc         : std_logic_vector(7 downto 0);  -- byte data to CRC
  signal sfderr              : std_logic_vector( 2 downto 0);  -- Error nb for SFD
  -- Number of preamble bits to be considered in short SFD comparison.
  signal sfdlen              : std_logic_vector( 2 downto 0);
  signal prepre              : std_logic_vector( 5 downto 0);  -- pre-preamble count.
  signal txenddel            : std_logic_vector( 7 downto 0);  -- time to wait after a tx
  -- Initial values for phase correction parameters.
  signal rho                 : std_logic_vector( 1 downto 0);
  signal mu                  : std_logic_vector( 1 downto 0);
  -- Initial values for phase feedforward equalizer parameters.
  signal beta                : std_logic_vector( 1 downto 0);
  signal alpha               : std_logic_vector( 1 downto 0);
  -- Values applied for phase correction parameters.
  signal applied_mu          : std_logic_vector( 2 downto 0);
  -- Values applied for phase feedforward equalizer parameters.
  signal applied_beta        : std_logic_vector( 2 downto 0);
  signal applied_alpha       : std_logic_vector( 2 downto 0);
  signal alpha_accu_disb     : std_logic;
  signal beta_accu_disb      : std_logic;
  -- TALPHAn time interval value for equalizer alpha parameter update.
  signal talpha3             : std_logic_vector( 3 downto 0);
  signal talpha2             : std_logic_vector( 3 downto 0);
  signal talpha1             : std_logic_vector( 3 downto 0);
  signal talpha0             : std_logic_vector( 3 downto 0);
  -- TBETAn time interval value for equalizer beta parameter update.
  signal tbeta3              : std_logic_vector( 3 downto 0);
  signal tbeta2              : std_logic_vector( 3 downto 0);
  signal tbeta1              : std_logic_vector( 3 downto 0);
  signal tbeta0              : std_logic_vector( 3 downto 0);
  -- TMUn time interval value for phase correction and offset comp. mu param.
  signal tmu3                : std_logic_vector( 3 downto 0);
  signal tmu2                : std_logic_vector( 3 downto 0);
  signal tmu1                : std_logic_vector( 3 downto 0);
  signal tmu0                : std_logic_vector( 3 downto 0);
  -- Time delay to switch on frequency pre-compensation after preamble start,
  signal precomp             : std_logic_vector( 5 downto 0);  -- in us.
  -- Delay to stop the equalizer adaptation after the last param update, in 탎.
  signal eqhold              : std_logic_vector(11 downto 0);
  -- Delay to start the compensation after the start of the estimation, in 탎.
  signal comptime            : std_logic_vector( 4 downto 0);
  -- Delay to start the estimation after the enabling of the equalizer, in 탎.
  signal esttime             : std_logic_vector( 4 downto 0);
  -- Time delay to switch on the equalizer after the fine gain setting, in 탎.
  signal eqtime              : std_logic_vector( 3 downto 0);
  -- Delay to switch on phase correction and carrier offset compensation after
  -- the AGC/CCA procedure, in 탎.
  signal looptime            : std_logic_vector( 3 downto 0);
  -- Delay to switch on timing offset compensation after energy detection at
  -- the start of the preamble, in us.
  signal synctime            : std_logic_vector( 5 downto 0);

  signal mod_type : std_logic;
  --signal one_us_it         : std_logic;

  signal rx_idle_state   : std_logic;   -- high when rx sm is idle

  signal remod_data     : std_logic_vector(1 downto 0);  -- Data from the TX path
  signal remod_enable   : std_logic;  -- High when the remodulation is enabled
  signal remod_data_req : std_logic;    -- request to send a byte 
  signal remod_type     : std_logic;    -- CCK : 0 ; PBCC : 1
  signal remod_bq       : std_logic;    -- BPSK = 0 - QPSK = 1 
  signal demod_data     : std_logic_vector(7 downto 0);  -- Data to the TX path

  -- signals for iq_mismatch
  signal iq_estim_enable : std_logic;   -- enable the I/Q Mismatch estim when 1
  signal iq_comp_enable  : std_logic;   -- enable the I/Q Mismatch comp when 1

  signal equalizer_activate   : std_logic;
  signal equalizer_init_n     : std_logic;
  signal equalizer_disb       : std_logic;
  signal synctime_enable      : std_logic;
  signal decode_path_activate : std_logic;
  signal diff_decod_first_val : std_logic;
  signal precomp_enable       : std_logic;
  signal enable_error_int     : std_logic;
  signal rec_mode             : std_logic_vector(1 downto 0);

  signal symbol_sync       : std_logic;
  signal symbol_sync_ff1   : std_logic;
  signal symbol_sync_ff2   : std_logic;
  signal symbol_sync_ff3   : std_logic;
  signal symbol_sync_ff4   : std_logic;
  signal symbol_sync_ff5   : std_logic;
  signal symbol_sync_ff6   : std_logic;
  signal symbol_sync_ff7   : std_logic;
  signal symbol_sync_ff8   : std_logic;
  signal symbol_sync_ff9   : std_logic;
  signal symbol_sync_ff10  : std_logic;
  signal symbol_sync_ff11  : std_logic;
  signal symbol_sync_ff12  : std_logic;
  signal symbol_sync_ff13  : std_logic;
  signal symbol_sync_ff14  : std_logic;

  signal rxv_service_o : std_logic_vector(7 downto 0);
  signal unused_data   : std_logic_vector(31 downto 0);

  signal rf_txonoff_req_o           : std_logic;
  signal phy_txstartend_conf_o      : std_logic;  -- transmission started, ready for data
  signal phy_rxstartend_ind_o       : std_logic;  -- end of the reception
  -- DIAG PORTS.
  signal rx_state_diag              : std_logic_vector(2 downto 0);  -- diag from sm
  signal diag_error_i               : std_logic_vector(7 downto 0);  -- diag from equalizer
  signal diag_error_q               : std_logic_vector(7 downto 0);  -- diag from equalizer
  signal rxe_errorstat_int          : std_logic_vector(1 downto 0);
  signal phy_cca_ind_int            : std_logic;
  signal phy_data_ind_int           : std_logic;
  -- Resynchronization signals.
  signal cca_busy_ff1_resync        : std_logic;
  signal cca_busy_ff2_resync        : std_logic;
  signal rf_txonoff_conf_ff1_resync : std_logic;  -- Radio controller in TX mode conf
  signal rf_txonoff_conf_ff2_resync : std_logic;  -- Radio controller in TX mode conf
  signal rf_rxonoff_conf_ff1_resync : std_logic;  -- Radio controller in RX mode conf
  signal rf_rxonoff_conf_ff2_resync : std_logic;  -- Radio controller in RX mode conf
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  unused_data <= (others => '0');
  
  clock_lock  <= rxv_service_o(2);
  rxv_service <= rxv_service_o;
    
  rf_txonoff_req      <= rf_txonoff_req_o;
  rf_dac_enable       <= phy_txstartend_conf_o or phy_txstartend_req;
  phy_txstartend_conf <= phy_txstartend_conf_o;
  phy_rxstartend_ind  <= phy_rxstartend_ind_o;

  -----------------------------------------------------------------------------
  -- Resynchronisation.
  -----------------------------------------------------------------------------

  resync_cca_busy_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      cca_busy_ff1_resync <= '0';
      cca_busy_ff2_resync <= '0';
    elsif clk'event and clk = '1' then
      cca_busy_ff1_resync <= cca_busy;
      cca_busy_ff2_resync <= cca_busy_ff1_resync;
    end if;
  end process resync_cca_busy_p;
  
  -----------------------------------------------------------------------------
  -- Gating condition
  -----------------------------------------------------------------------------
  modemb_gating_p : process(clk, reset_n)
    variable nb_clock_cnt : std_logic_vector(1 downto 0);
  begin
    if reset_n = '0' then
      rx_gating <= '1';
      tx_gating <= '1';
      nb_clock_cnt := "00";
    elsif clk'event and clk = '1' then
      -- Gating condition for Rx path
      if (cca_busy_ff2_resync = '1' or phy_rxstartend_ind_o = '1') then
          rx_gating <= '1';
          nb_clock_cnt := "01";
      else
        if nb_clock_cnt = "00" then
          rx_gating <= '0';
        elsif nb_clock_cnt = "11" then
          rx_gating <= '0';
        else
          nb_clock_cnt := nb_clock_cnt + '1';          
        end if;
        
      end if;

      -- Gating condition for Tx path
      if (txv_datarate(3) = '0' and
         (phy_txstartend_conf_o = '1' or phy_txstartend_req  = '1')) or
         (cca_busy_ff2_resync = '1' or phy_rxstartend_ind_o = '1') then
        tx_gating <= '0';
      else
        tx_gating <= '1';
      end if;

    end if;
  end process modemb_gating_p;


  -- One micro second counter                  
  one_us_p : process (rx_path_b_gclk, reset_n)
  begin
    if reset_n = '0' then
      symbol_sync_ff1       <= '0';
      symbol_sync_ff2       <= '0';
      symbol_sync_ff3       <= '0';
      symbol_sync_ff4       <= '0';
      symbol_sync_ff5       <= '0';
      symbol_sync_ff6       <= '0';
      symbol_sync_ff7       <= '0';
      symbol_sync_ff8       <= '0';
      symbol_sync_ff9       <= '0';
      symbol_sync_ff10      <= '0';
      symbol_sync_ff11      <= '0';
      symbol_sync_ff12      <= '0';
      symbol_sync_ff13      <= '0';
      symbol_sync_ff14      <= '0';
    elsif rx_path_b_gclk'event and rx_path_b_gclk = '1' then
      symbol_sync_ff1  <= symbol_sync;
      symbol_sync_ff2  <= symbol_sync_ff1;
      symbol_sync_ff3  <= symbol_sync_ff2;
      symbol_sync_ff4  <= symbol_sync_ff3;
      symbol_sync_ff5  <= symbol_sync_ff4;
      symbol_sync_ff6  <= symbol_sync_ff5;
      symbol_sync_ff7  <= symbol_sync_ff6;
      symbol_sync_ff8  <= symbol_sync_ff7;
      symbol_sync_ff9  <= symbol_sync_ff8;
      symbol_sync_ff10 <= symbol_sync_ff9;
      symbol_sync_ff11 <= symbol_sync_ff10;
      symbol_sync_ff12 <= symbol_sync_ff11;
      symbol_sync_ff13 <= symbol_sync_ff12;
      symbol_sync_ff14 <= symbol_sync_ff13;
    end if;
  end process one_us_p;
  symbol_sync2 <= symbol_sync_ff14; --transport symbol_sync after 340 ns;
  
  ------------------------------------------------------------------------------
  -- Tx Path Core Port Map
  ------------------------------------------------------------------------------
  tx_path_core_1 : tx_path_core
  generic map(
    dec_freq_g               => 4
          )
  port map (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    clk                   => tx_path_b_gclk,
    reset_n               => reset_n,
    --------------------------------------------
    -- Interface with Modem State Machines
    --------------------------------------------
    low_r_flow_activate   => activate_seria,
    psk_mode              => tx_psk_mode,
    shift_period          => shift_period,
    cck_flow_activate     => activate_cck,
    cck_speed             => tx_cck_rate,
    tx_activated          => tx_activated,
    --------------------------------------------
    -- Interface with Wild Bup - via or not Modem State Machines
    --------------------------------------------
    scrambling_disb       => scrambling_disb,
    spread_disb           => spread_disb,
    bup_txdata            => scr_data_in,
    phy_data_req          => sm_data_req,
    txv_prtype            => preamble_type_tx,
    txv_immstop           => txv_immstop,
    phy_data_conf         => seria_data_conf,
    --------------------------------------------
    -- Interface for remodulation
    --------------------------------------------
    remod_data            => remod_data, 
    --                          
    remod_enable          => remod_enable,
    remod_data_req        => remod_data_req,
    remod_type            => remod_type,    
    remod_bq              => remod_bq,    
    demod_data            => demod_data,
    --------------------------------------------
    -- FIR controls
    --------------------------------------------
    init_fir              => init_fir,
    fir_activate          => fir_activate,
    fir_phi_out_tog_o     => fir_phi_out_tog_o,
    fir_phi_out           => fir_phi_out
    );

  
  ------------------------------------------------------------------------------
  -- RX Path Core Port map
  ------------------------------------------------------------------------------
  rx_path_core_1 : rx_path_core
    generic map (
      data_length_g       => 9, -- data size
      angle_length_g      => 15 -- agle size for phase compensation cordic
    )
    port map (
      --------------------------------------------
      -- clock and reset
      --------------------------------------------
      reset_n             => reset_n,            -- Global reset.
      rx_path_b_gclk      => rx_path_b_gclk,    -- Gated Clock for RX Path.
      
      --------------------------------------------
      -- Data In
      --------------------------------------------
      data_in_i           => rf_rxi,
      data_in_q           => rf_rxq,
      
      --------------------------------------------
      -- Control inputs
      --------------------------------------------
      -- Control for gain compensation.
      dcoffdisb           => dcoffdisb,          -- disable dc_offset compensation when high.
      
      -- Control for IQ Mismatch Compensation
      iq_estimation_enable   => iq_estim_enable, -- enable the I/Q estimation when high.
      iq_compensation_enable => iq_comp_enable,  -- enable the I/Q compensation when high
      -- Control for equalization
      equ_activate        => equalizer_activate, -- enable the equalizer when high.
      equalizer_disb      => equalizer_disb,     -- disable the equalizer filter when high.
      equalizer_init_n    => equalizer_init_n,   -- equalizer filter coeffs set to 0 when low.
      alpha_accu_disb     => alpha_accu_disb,    -- stop coeff accu when high.
      beta_accu_disb      => beta_accu_disb,     -- stop dc accu when high.
      alpha               => applied_alpha,      -- alpha parameter value.
      beta                => applied_beta,       -- beta parameter value.
      -- Control for DSSS / CCK demodulation
      interp_disb         => interp_disb_int,    -- disable the interpolation when high 
      rx_enable           => cca_busy_ff2_resync,-- enable rx path when high 
      mod_type            => mod_type,           -- '0' for DSSS, '1' for CCK.
      enable_error        => enable_error_int,       -- Enable Error Calculation
      precomp_enable      => precomp_enable,     -- Reload the omega accumulator
      demod_rate          => rx_psk_mode,        -- '0' for BPSK, '1' for QPSK
      cck_rate            => rx_cck_rate,
      rho                 => rho,                -- rho parameter value.
      mu                  => applied_mu,         -- mu parameter value.
      --
      tau_est             => tau_est,           
      -- Control for Decode Path
      scrambling_disb     => scrambling_disb,    -- scrambling disable
      decode_path_activate=> decode_path_activate,-- enable the diff. decoder
      diff_decod_first_val=> diff_decod_first_val,-- initialize the diff. decoder
      sfd_detect_enable   => sfd_detect_enable,
      sfderr              => sfderr,
      sfdlen              => sfdlen,
      rec_mode            => rec_mode,
           
      --------------------------------------------
      -- Remodulation interface
      --------------------------------------------
      remod_data          => remod_data,      -- Data from the TX path
      --
      remod_enable        => remod_enable,    -- High when the remodulation is enabled
      remod_data_req      => remod_data_req,  -- request to send a byte 
      remod_type          => remod_type,      -- CCK : 0 ; PBCC : 1
      remod_bq            => remod_bq,        -- BPSK = 0 - QPSK = 1 
      demod_data          => demod_data,      -- Data to the TX path

      --------------------------------------------
      -- AGC-CCA interface
      --------------------------------------------
      correl_rst_n        => correl_rst_n,    -- reset the Barker correlator when low
      synchro_en          => synctime_enable, -- enable the synchronisation when high
      --
      symbol_synchro      => symbol_sync,     -- pulse at the beginning of a symbol.
      
      --------------------------------------------
      -- Modem B state machines interface
      --------------------------------------------
      sfd_found           => sfd_found_int,       -- sfd found when high
      preamble_type       => preamble_type_rx,-- Type of preamble 
      phy_data_ind        => byte_ind,        -- pulse when an RX byte is available.
      data_to_bup         => rx_data,         -- Received data.
      --------------------------------------------
      -- Status registers.
      --------------------------------------------
      iq_gain_sat_stat    => iq_gain_sat_stat,
      dc_offset_i_stat    => dc_offset_i_stat,
      dc_offset_q_stat    => dc_offset_q_stat,  
      coeff_sum_i_stat    => coeff_sum_i_stat,
      coeff_sum_q_stat    => coeff_sum_q_stat,
      freqoffestim_stat   => freqoffestim_stat,
      -------------------------------
      -- Diag ports
      -------------------------------
      diag_error_i        => diag_error_i,
      diag_error_q        => diag_error_q
      
      );

  --------------------------------------------
  -- RX path control
  --------------------------------------------
  rx_ctrl_1 : rx_ctrl
  port map (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn             => reset_n,
    hclk                => clk,

    --------------------------------------------
    -- Registers interface
    --------------------------------------------
    eq_disb             => eq_disb,
    precomp             => precomp,
    eqtime              => eqtime,
    eqhold              => eqhold,
    looptime            => looptime,
    synctime            => synctime,
    alpha               => alpha,
    beta                => beta,
    mu                  => mu,
    talpha3             => talpha3,
    talpha2             => talpha2,
    talpha1             => talpha1,
    talpha0             => talpha0,
    tbeta3              => tbeta3,
    tbeta2              => tbeta2,
    tbeta1              => tbeta1,
    tbeta0              => tbeta0,
    tmu3                => tmu3,
    tmu2                => tmu2,
    tmu1                => tmu1,
    tmu0                => tmu0,

    --------------------------------------------
    -- Input control
    --------------------------------------------
    energy_detect       => cca_busy_ff2_resync,
    agcproc_end         => agcproc_end,
    rx_psk_mode         => rx_psk_mode,
    rx_idle_state       => rx_idle_state,
    precomp_disb        => precompdisb,
    comp_disb           => comp_disb,
    iqmm_disb           => iqmmdisb,
    gain_disb           => gaindisb,
    --------------------------------------------
    -- RX path control signals
    --------------------------------------------
    equalizer_activate  => equalizer_activate,
    equalizer_init_n    => equalizer_init_n,
    equalizer_disb      => equalizer_disb,
    precomp_enable      => precomp_enable,
    synctime_enable     => synctime_enable,
    phase_estim_enable  => enable_error_int,
    iq_comp_enable      => iq_comp_enable,
    iq_estim_enable     => iq_estim_enable,
    gain_enable         => gain_enable,
    sfd_detect_enable   => sfd_detect_enable,
    applied_alpha       => applied_alpha,
    applied_beta        => applied_beta,
    alpha_accu_disb     => alpha_accu_disb,
    beta_accu_disb      => beta_accu_disb,
    applied_mu          => applied_mu
    
  );

  enable_error <= enable_error_int;  

  ------------------------------------------------------------------------------
  -- Modem State Machines 802.11b Port Map
  ------------------------------------------------------------------------------
  -- Resync of radio-controller signals.
  txonoff_conf_resync_p: process (clk, reset_n)
  begin
    if reset_n = '0' then
      rf_txonoff_conf_ff1_resync <= '0';
      rf_txonoff_conf_ff2_resync <= '0';
      rf_rxonoff_conf_ff1_resync <= '0';
      rf_rxonoff_conf_ff2_resync <= '0';
    elsif clk'event and clk = '1' then
      rf_txonoff_conf_ff1_resync <= rf_txonoff_conf;
      rf_txonoff_conf_ff2_resync <= rf_txonoff_conf_ff1_resync;
      rf_rxonoff_conf_ff1_resync <= rf_rxonoff_conf; 
      rf_rxonoff_conf_ff2_resync <= rf_rxonoff_conf_ff1_resync;      
    end if;
  end process txonoff_conf_resync_p;   

  
  modem_sm_b_1 : modem_sm_b
    port map (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn              => reset_n,
    hclk                 => clk,
    --------------------------------------
    -- TX path block
    -------------------------------------- 
    seria_data_conf      => seria_data_conf,
    tx_activated         => tx_activated,
    --                      
    scr_data_in          => scr_data_in,
    sm_data_req          => sm_data_req,
    tx_psk_mode          => tx_psk_mode,
    activate_seria       => activate_seria,
    shift_period         => shift_period,
    activate_cck         => activate_cck,
    tx_cck_rate          => tx_cck_rate,
    preamble_type_tx     => preamble_type_tx,
    --------------------------------------
    -- RX path block
    -------------------------------------- 
    cca_busy             => cca_busy_ff2_resync,
    preamble_type_rx     => preamble_type_rx,
    sfd_found            => sfd_found_int,
    byte_ind             => byte_ind,
    rx_data              => rx_data,
    --  
    decode_path_activate => decode_path_activate,
    diff_decod_first_val => diff_decod_first_val,
    rec_mode             => rec_mode,
    mod_type             => mod_type,                   
    rx_psk_mode          => rx_psk_mode,
    rx_cck_rate          => rx_cck_rate,
    rx_idle_state        => rx_idle_state,
    rx_plcp_state        => plcp_state,
    --------------------------------------------
    -- Registers
    --------------------------------------------
    reg_prepre           => prepre,
    txenddel_reg         => txenddel,
    rxlenchken           => rxlenchken,
    rxmaxlength          => rxmaxlength,
    --------------------------------------------
    -- CCA
    --------------------------------------------
    psdu_duration        => psdu_duration,
    correct_header       => correct_header,
    plcp_error           => plcp_error,
    listen_start_o       => listen_start_o,
    --------------------------------------
    -- CRC
    -------------------------------------- 
    crc_data_1st         => crc_out_1st,
    crc_data_2nd         => crc_out_2nd,
    --                      
    crc_init             => crc_init,
    crc_data_valid       => crc_data_valid,
    data_to_crc          => data_to_crc,
    --------------------------------------------
    -- Radio controller interface
    --------------------------------------------
    rf_txonoff_req       => rf_txonoff_req_o,
    rf_txonoff_conf      => rf_txonoff_conf_ff2_resync,
    rf_rxonoff_req       => rf_rxonoff_req,
    rf_rxonoff_conf      => rf_rxonoff_conf_ff2_resync,
    --------------------------------------
    -- BuP
    -------------------------------------- 
    -- TX
    phy_txstartend_req   => phy_txstartend_req,
    txv_service          => txv_service,
    phy_data_req         => phy_data_req,
    txv_datarate         => txv_datarate,
    txv_length           => txv_length,
    bup_txdata           => bup_txdata,
    phy_txstartend_conf  => phy_txstartend_conf_o,
    txv_immstop          => txv_immstop,
    -- RX
    phy_cca_ind          => phy_cca_ind_int,
    phy_rxstartend_ind   => phy_rxstartend_ind_o,
    rxv_service          => rxv_service_o,
    phy_data_ind         => phy_data_ind_int,
    rxv_datarate         => rxv_datarate,
    rxv_length           => rxv_length,
    rxe_errorstat        => rxe_errorstat_int,
    bup_rxdata           => bup_rxdata, 
    --------------------------------------
    -- Diag
    --------------------------------------
    rx_state_diag        => rx_state_diag
    );

  
  ------------------------------------------------------------------------------
  -- Registers Port Map
  ------------------------------------------------------------------------------
  
  modemb_registers_1 :modemb_registers
  generic map (
    radio_interface_g => radio_interface_g)
  port map (
    reset_n             => reset_n,          
    -- apb interface
    pclk                => bus_clk,             
    psel                => psel,             
    penable             => penable,          
    paddr               => paddr,            
    pwrite              => pwrite,           
    pwdata              => pwdata,           
    prdata              => prdata,           
    -- modem registers inputs
    -- MDMbSTAT0 register. 
    reg_eqsumq => coeff_sum_q_stat,
    reg_eqsumi => coeff_sum_i_stat,
    reg_dcoffsetq => dc_offset_q_stat,
    reg_dcoffseti => dc_offset_i_stat,
    -- MDMbSTAT1 register.
    reg_iqgainestim => iq_gain_sat_stat,
    reg_freqoffestim => freqoffestim_stat,
    -- modem registers outputs
    -- MDMbCNTL register.
    reg_tlockdisb       => tlockdisb_int,
    reg_rxc2disb        => rxc2disb_int,
    reg_interpdisb      => interp_disb_int_int,
    reg_iqmmdisb        => iqmmdisb_int,
    reg_gaindisb        => gaindisb_int,
    reg_precompdisb     => precompdisb_int,
    reg_dcoffdisb       => dcoffdisb_int,
    reg_compdisb        => comp_disb_int,         
    reg_eqdisb          => eq_disb_int,         
    reg_firdisb         => fir_disb_int,         
    reg_spreaddisb      => spread_disb_int,   
    reg_scrambdisb      => scrambling_disb_int,   
    reg_sfderr          => sfderr,
    reg_interfildisb    => interfildisb_int,
    reg_txc2disb        => txc2disb_int,
    reg_sfdlen          => sfdlen,
    reg_prepre          => prepre,
    -- MDMbPRMINIT register.
    reg_rho             => rho,
    reg_mu              => mu,
    reg_beta            => beta,
    reg_alpha           => alpha,
    -- MDMbTALPHA register.
    reg_talpha3         => talpha3,
    reg_talpha2         => talpha2,
    reg_talpha1         => talpha1,
    reg_talpha0         => talpha0,
    -- MDMbTBETA register.
    reg_tbeta3          => tbeta3,
    reg_tbeta2          => tbeta2,
    reg_tbeta1          => tbeta1,
    reg_tbeta0          => tbeta0,
    -- MDMbTMU register.
    reg_tmu3            => tmu3,
    reg_tmu2            => tmu2,
    reg_tmu1            => tmu1,
    reg_tmu0            => tmu0,
    -- MDMbCNTL1 register.
    reg_rxlenchken  => rxlenchken,
    reg_rxmaxlength => rxmaxlength,
    -- MDMbRFCNTL register: AC coupling gain compensation.
    reg_txconst         => tx_const,
    reg_txenddel        => txenddel,
    -- MDMbCCA register.
    reg_ccamode         => ccamode,  
    -- MDMbEQCNTL register.
    reg_eqhold          => eqhold,
    reg_comptime        => comptime, -- TBD
    reg_esttime         => esttime, -- TBD
    reg_eqtime          => eqtime,
    -- MDMbCNTL2 register
    reg_maxstage    => interpmaxstage,
    reg_precomp     => precomp,
    reg_synctime    => synctime,
    reg_looptime    => looptime 
  );

  interp_disb <= interp_disb_int;

  
  modemb_registers_if_1 : modemb_registers_if
  port map (
    -- Clocks & Reset
    reset_n               => reset_n,
    hclk                  => clk,
    -- Controls
    -- Registers inputs
    reg_tlockdisb         => tlockdisb_int,
    reg_rxc2disb          => rxc2disb_int,
    reg_interpdisb        => interp_disb_int_int,
    reg_iqmmdisb          => iqmmdisb_int,
    reg_gaindisb          => gaindisb_int,
    reg_precompdisb       => precompdisb_int,
    reg_dcoffdisb         => dcoffdisb_int,
    reg_compdisb          => comp_disb_int,
    reg_eqdisb            => eq_disb_int,
    reg_firdisb           => fir_disb_int,
    reg_spreaddisb        => spread_disb_int,
    reg_scrambdisb        => scrambling_disb_int,
    reg_interfildisb      => interfildisb_int,
    reg_txc2disb          => txc2disb_int,
    -- Registers outputs =>
    reg_tlockdisb_sync    => tlockdisb,
    reg_rxc2disb_sync     => rxc2disb,
    reg_interpdisb_sync   => interp_disb_int,
    reg_iqmmdisb_sync     => iqmmdisb,
    reg_gaindisb_sync     => gaindisb,
    reg_precompdisb_sync  => precompdisb,
    reg_dcoffdisb_sync    => dcoffdisb,
    reg_compdisb_sync     => comp_disb,
    reg_eqdisb_sync       => eq_disb,
    reg_firdisb_sync      => fir_disb,
    reg_spreaddisb_sync   => spread_disb,
    reg_scrambdisb_sync   => scrambling_disb,
    reg_interfildisb_sync => interfildisb,
    reg_txc2disb_sync     => txc2disb
  );
  
  gaindisb_out <= gaindisb;
  
  ------------------------------------------------------------------------------
  -- CRC16_8 Port Map
  ------------------------------------------------------------------------------
  crc16_8_1 : crc16_8
  port map (
    clk                 => tx_path_b_gclk,
    resetn              => reset_n,
    data_in             => data_to_crc,
    ld_init             => crc_init,
    calc                => crc_data_valid,
    crc_out_1st         => crc_out_1st,
    crc_out_2nd         => crc_out_2nd
    );
    
  crc_data <= crc_out_2nd & crc_out_1st;

  phy_data_conf <= seria_data_conf;
  
  sfd_found <= sfd_found_int;


  rxe_errorstat <= rxe_errorstat_int;

  phy_cca_ind <= phy_cca_ind_int;
  
  phy_data_ind <= phy_data_ind_int;

  --------------------------------------------
  -- Diagnostic port assignment for modem b.
  --------------------------------------------
  modem_diag(0) <= sfd_found_int;
  modem_diag(1) <= symbol_sync;
  modem_diag(17 downto 2)  <= agc_diag;
  --------------------------------------------
  -- Diagnostic ports for wild chip.
  --------------------------------------------
  -- Input of modem b.
  modem_diag0(7 downto 0) <= rf_rxi;
  modem_diag0(15 downto 8) <= rf_rxq;
  -- Control/error signals of modem b.
  modem_diag1(0) <= '0';
  modem_diag1(1) <= sfd_found_int;
  modem_diag1(2) <= symbol_sync;
  modem_diag1(3) <= cca_busy_ff2_resync;
  modem_diag1(4) <= agcproc_end;
  modem_diag1(5) <= preamble_type_rx;
  modem_diag1(6) <= rxe_errorstat_int(0);
  modem_diag1(7) <= rxe_errorstat_int(1);
  modem_diag1(8) <= rx_state_diag(0);
  modem_diag1(9) <= rx_state_diag(1);
  modem_diag1(10) <= rx_state_diag(2);
  modem_diag1(11) <= phy_rxstartend_ind_o;
  modem_diag1(12) <= phy_cca_ind_int;
  modem_diag1(13) <= phy_data_ind_int;
  modem_diag1(14) <= phy_txstartend_req;
  modem_diag1(15) <= '0';
  -- Equalizer error signals.
  modem_diag2(7 downto 0) <= diag_error_i;
  modem_diag2(15 downto 8) <= diag_error_q;

  -- Globals.
  
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off
--  synctime_enable_gbl <= synctime_enable;
--  applied_beta_gbl <= applied_beta;
--  applied_alpha_gbl <= applied_alpha;
--  rx_data_gbl <= rx_data;
--  cca_busy_gbl <= cca_busy_ff2_resync;
--  equalizer_activate_gbl        <= equalizer_activate;
--  equalizer_disb_gbl      <= equalizer_disb;
--  equalizer_init_n_gbl    <= equalizer_init_n;
--  reset_n_modem_gbl             <= reset_n;
--  phy_data_ind_bcore_gbl <= phy_data_ind_int;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on 
end rtl;

--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: modemb_registers_if.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/modem802_11b/vhdl/rtl/modemb_registers_if.vhd,v  
--  Log: modemb_registers_if.vhd,v  
-- Revision 1.2  2005/02/11 14:48:31  arisse
-- #BugId:953#
-- Resynchronization of signals with two flip-flops instead of one.
--
-- Revision 1.1  2004/09/13 08:46:41  arisse
-- initial release
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity modemb_registers_if is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n : in std_logic;
    hclk    : in std_logic;             -- 44 MHz clock.

    --------------------------------------
    -- Controls
    --------------------------------------
    -- Registers inputs :
    reg_tlockdisb         : in  std_logic;  -- '0': use timing lock from service field.
    reg_rxc2disb          : in  std_logic;  -- '1' to disable 2 complement.
    reg_interpdisb        : in  std_logic;  -- '0' to enable interpolator.
    reg_iqmmdisb          : in  std_logic;  -- '0' to enable I/Q mismatch compensation.
    reg_gaindisb          : in  std_logic;  -- '0' to enable the gain compensation.
    reg_precompdisb       : in  std_logic;  -- '0' to enable timing offset compensation
    reg_dcoffdisb         : in  std_logic;  -- '0' to enable the DC offset compensation
    reg_compdisb          : in  std_logic;  -- '0' to enable the compensation.
    reg_eqdisb            : in  std_logic;  -- '0' to enable the Equalizer.
    reg_firdisb           : in  std_logic;  -- '0' to enable the FIR.
    reg_spreaddisb        : in  std_logic;  -- '0' to enable spreading.                        
    reg_scrambdisb        : in  std_logic;  -- '0' to enable scrambling.
    reg_interfildisb      : in  std_logic;  -- '1' to bypass rx_11b_interf_filter 
    reg_txc2disb          : in  std_logic;  -- '1' to disable 2 complement.   
    -- Registers outputs :
    reg_tlockdisb_sync    : out std_logic;  -- '0': use timing lock from service field.
    reg_rxc2disb_sync     : out std_logic;  -- '1' to disable 2 complement.
    reg_interpdisb_sync   : out std_logic;  -- '0' to enable interpolator.
    reg_iqmmdisb_sync     : out std_logic;  -- '0' to enable I/Q mismatch compensation.
    reg_gaindisb_sync     : out std_logic;  -- '0' to enable the gain compensation.
    reg_precompdisb_sync  : out std_logic;  -- '0' to enable timing offset compensation
    reg_dcoffdisb_sync    : out std_logic;  -- '0' to enable the DC offset compensation
    reg_compdisb_sync     : out std_logic;  -- '0' to enable the compensation.
    reg_eqdisb_sync       : out std_logic;  -- '0' to enable the Equalizer.
    reg_firdisb_sync      : out std_logic;  -- '0' to enable the FIR.
    reg_spreaddisb_sync   : out std_logic;  -- '0' to enable spreading.                        
    reg_scrambdisb_sync   : out std_logic;  -- '0' to enable scrambling.
    reg_interfildisb_sync : out std_logic;  -- '1' to bypass rx_11b_interf_filter 
    reg_txc2disb_sync     : out std_logic   -- '1' to disable 2 complement.   
    );

end modemb_registers_if;
