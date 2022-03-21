
--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of modem_sm_b is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal rx_crc_init       : std_logic;
  signal tx_crc_init       : std_logic;
  signal rx_crc_data_valid : std_logic;
  signal tx_crc_data_valid : std_logic;
  signal rx_data_to_crc    : std_logic_vector(7 downto 0);
  signal tx_data_to_crc    : std_logic_vector(7 downto 0);
  signal tx_activated_long : std_logic;
  
  ---------------------------------------------------- End of Signal declaration

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------

begin

  
  -- CRC muxes
  crc_init       <= tx_crc_init when phy_txstartend_req = '1' else 
                    rx_crc_init;
  crc_data_valid <= tx_crc_data_valid when phy_txstartend_req = '1' else 
                    rx_crc_data_valid;
  data_to_crc    <= tx_data_to_crc when phy_txstartend_req = '1' else 
                    rx_data_to_crc;
                    
  ------------------------------------------------------------------------------
  -- TX state machine
  ------------------------------------------------------------------------------
  modem_tx_sm_1 : modem_tx_sm
    port map (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn             => hresetn,
    hclk                => hclk,
    --------------------------------------
    -- TX path block
    -------------------------------------- 
    seria_data_conf     => seria_data_conf,
    tx_activated        => tx_activated_long,
    --                     
    scr_data_in         => scr_data_in,
    sm_data_req         => sm_data_req,
    psk_mode            => tx_psk_mode,
    activate_seria      => activate_seria,
    shift_period        => shift_period,
    activate_cck        => activate_cck,
    cck_speed           => tx_cck_rate,
    preamble_type       => preamble_type_tx,
    --------------------------------------------
    -- Registers
    --------------------------------------------
    reg_prepre          => reg_prepre,
    --------------------------------------
    -- CRC
    -------------------------------------- 
    crc_data_1st        => crc_data_1st,
    crc_data_2nd        => crc_data_2nd,
    --                     
    crc_init            => tx_crc_init,
    crc_data_valid      => tx_crc_data_valid,
    data_to_crc         => tx_data_to_crc,
    --------------------------------------------
    -- Radio controller interface
    --------------------------------------------
    rf_txonoff_req      => rf_txonoff_req,
    rf_txonoff_conf     => rf_txonoff_conf,
    rf_rxonoff_req      => rf_rxonoff_req,
    rf_rxonoff_conf     => rf_rxonoff_conf,
    --------------------------------------
    -- BuP
    -------------------------------------- 
    phy_txstartend_req  => phy_txstartend_req,
    txv_service         => txv_service,
    phy_data_req        => phy_data_req,
    txv_datarate        => txv_datarate,
    txv_length          => txv_length,
    bup_txdata          => bup_txdata,
    txv_immstop         => txv_immstop,
    --                  
    phy_txstartend_conf => phy_txstartend_conf     
    );


  ------------------------------------------------------------------------------
  -- RX state machine
  ------------------------------------------------------------------------------
  modem_rx_sm_1 : modem_rx_sm
    port map (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn             => hresetn,
    hclk                => hclk,
    --------------------------------------
    -- RX path block
    -------------------------------------- 
    cca_busy            => cca_busy,
    preamble_type       => preamble_type_rx,
    sfd_found           => sfd_found,
    byte_ind            => byte_ind,
    tx_activated        => tx_activated_long,
    rx_data             => rx_data,
    --       
    decode_path_activate => decode_path_activate,
    diff_decod_first_val => diff_decod_first_val,
    rec_mode             => rec_mode,
    mod_type            => mod_type,              
    rx_psk_mode         => rx_psk_mode,
    cck_rate            => rx_cck_rate,
    rx_idle_state       => rx_idle_state,
    rx_plcp_state       => rx_plcp_state,
    --------------------------------------------
    -- CCA
    --------------------------------------------
    psdu_duration       => psdu_duration,
    correct_header      => correct_header,
    plcp_error          => plcp_error,
    listen_start_o      => listen_start_o,
    --------------------------------------
    -- CRC
    -------------------------------------- 
    crc_data_1st        => crc_data_1st,
    crc_data_2nd        => crc_data_2nd,
    --                     
    crc_init            => rx_crc_init,
    crc_data_valid      => rx_crc_data_valid,
    data_to_crc         => rx_data_to_crc,
    --------------------------------------
    -- BuP
    --------------------------------------
    phy_txstartend_req  => phy_txstartend_req,
    phy_cca_ind         => phy_cca_ind,
    phy_rxstartend_ind  => phy_rxstartend_ind,
    rxv_service         => rxv_service,
    phy_data_ind        => phy_data_ind,
    rxv_datarate        => rxv_datarate,
    rxv_length          => rxv_length,
    rxe_errorstat       => rxe_errorstat,
    bup_rxdata          => bup_rxdata,
    --------------------------------------
    -- Registers
    --------------------------------------
    rxlenchken          => rxlenchken,
    rxmaxlength         => rxmaxlength,
    --------------------------------------
    -- Diag
    --------------------------------------    
    rx_state_diag       => rx_state_diag
    );


  -----------------------------------------------------------------------------
  -- Delay the tx_activate of the delay of the front-end
  -----------------------------------------------------------------------------
  tx_activ_gen_1: tx_activ_gen
    port map (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
      hresetn          => hresetn,    -- [in]  AHB reset line.
      hclk             => hclk,       -- [in]  AHB clock line.
     --------------------------------------
     -- Signals
     --------------------------------------
      txenddel_reg      => txenddel_reg,        -- [in]
      tx_acti_tx_path   => tx_activated,        -- [in]  tx_activate from tx_path_core
      tx_activated_long => tx_activated_long);  -- [out] tx_activate longer of txenddel_reg periods

  
end RTL;
