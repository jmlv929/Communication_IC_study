

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of modema2_registers is

  -- registers signals.
  -- *_d signals are combinational signals.

  -- MDMaTXCNTL
  signal add_short_pre       : std_logic_vector(1 downto 0);
  signal add_short_pre_d     : std_logic_vector(1 downto 0);
  signal scrmode             : std_logic;                     -- to tx scrambler.
  signal scrmode_d           : std_logic;                     -- to tx scrambler.
  signal tx_filter_bypass    : std_logic;                     -- to tx_rx_filter
  signal tx_filter_bypass_d  : std_logic;                     -- to tx_rx_filter
  signal dac_powerdown_dyn   : std_logic;                     -- 
  signal dac_powerdown_dyn_d : std_logic;                     -- 
  signal tx_enddel           : std_logic_vector(7 downto 0);  -- 
  signal tx_enddel_d         : std_logic_vector(7 downto 0);  -- 
  signal scrinitval          : std_logic_vector(6 downto 0);  -- to tx scrambler.
  signal scrinitval_d        : std_logic_vector(6 downto 0);  -- to tx scrambler.
  signal c2disb_tx           : std_logic;                     -- to front_end
  signal c2disb_tx_d         : std_logic;                     -- to front_end
  signal tx_norm_factor      : std_logic_vector(7 downto 0);  -- to tx_rx_filter
  signal tx_norm_factor_d    : std_logic_vector(7 downto 0);  -- to tx_rx_filter
  -- MDMaTXIQCOMP
  signal tx_iq_phase         : std_logic_vector(5 downto 0);  --to iq_compensation
  signal tx_iq_phase_d       : std_logic_vector(5 downto 0);  --to iq_compensation
  signal tx_iq_ampl          : std_logic_vector(8 downto 0);  --to iq_compensation
  signal tx_iq_ampl_d        : std_logic_vector(8 downto 0);  --to iq_compensation
  -- MDMaTXCONST
  signal tx_const            : std_logic_vector(7 downto 0);  --to DAC (I only)
  signal tx_const_d          : std_logic_vector(7 downto 0);  --to DAC (I only)
  -- MDMaRXCNTL0
  signal rx_iq_step_ph       : std_logic_vector(7 downto 0);
  signal rx_iq_step_ph_d     : std_logic_vector(7 downto 0);
  signal rx_iq_step_g        : std_logic_vector(7 downto 0);
  signal rx_iq_step_g_d      : std_logic_vector(7 downto 0);
  signal adc_powerdown_dyn   : std_logic;
  signal adc_powerdown_dyn_d : std_logic;
  signal c2disb_rx           : std_logic;                     -- to front_end
  signal c2disb_rx_d         : std_logic;                     -- to front_end
  signal wf_window           : std_logic_vector(1 downto 0);  -- to wiener
  signal wf_window_d         : std_logic_vector(1 downto 0);  -- to wiener
  signal reduceerasures      : std_logic_vector(1 downto 0);  -- to or_equ
  signal reduceerasures_d    : std_logic_vector(1 downto 0);  -- to or_equ
  signal res_dco_disb        : std_logic;
  signal res_dco_disb_d      : std_logic;
  signal iq_mm_estrst        : std_logic;
  signal iq_mm_estrst_d      : std_logic;
  signal iq_mm_estrst_flag   : std_logic;
  signal dc_off_disb         : std_logic;
  signal dc_off_disb_d       : std_logic;
  signal iq_mm_est           : std_logic;
  signal iq_mm_est_d         : std_logic;
  -- MDMaRXCNTL1
  signal rx_del_dc_cor       : std_logic_vector(7 downto 0);
  signal rx_del_dc_cor_d     : std_logic_vector(7 downto 0);
  signal rx_length_limit     : std_logic_vector(11 downto 0);
  signal rx_length_limit_d   : std_logic_vector(11 downto 0);
  signal rx_length_chk_en    : std_logic;
  signal rx_length_chk_en_d  : std_logic;
  -- MDMaRXIQPRESET
  signal rx_iq_ph_preset     : std_logic_vector(15 downto 0);
  signal rx_iq_ph_preset_d   : std_logic_vector(15 downto 0);
  signal rx_iq_g_preset      : std_logic_vector(15 downto 0);
  signal rx_iq_g_preset_d    : std_logic_vector(15 downto 0);
  -- MDMaEQCNTL1
  signal histoffset18        : std_logic_vector(1 downto 0);
  signal histoffset18_d      : std_logic_vector(1 downto 0);
  signal histoffset12        : std_logic_vector(1 downto 0);
  signal histoffset12_d      : std_logic_vector(1 downto 0);
  signal histoffset9         : std_logic_vector(1 downto 0);
  signal histoffset9_d       : std_logic_vector(1 downto 0);
  signal histoffset6         : std_logic_vector(1 downto 0);
  signal histoffset6_d       : std_logic_vector(1 downto 0);
  signal satmaxncar18        : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar18_d      : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar12        : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar12_d      : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar9         : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar9_d       : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar6         : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar6_d       : std_logic_vector(5 downto 0);  -- to or_equ
  -- MDMaEQCNTL2
  signal histoffset54        : std_logic_vector(1 downto 0);
  signal histoffset54_d      : std_logic_vector(1 downto 0);
  signal histoffset48        : std_logic_vector(1 downto 0);
  signal histoffset48_d      : std_logic_vector(1 downto 0);
  signal histoffset36        : std_logic_vector(1 downto 0);
  signal histoffset36_d      : std_logic_vector(1 downto 0);
  signal histoffset24        : std_logic_vector(1 downto 0);
  signal histoffset24_d      : std_logic_vector(1 downto 0);
  signal satmaxncar54        : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar54_d      : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar48        : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar48_d      : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar36        : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar36_d      : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar24        : std_logic_vector(5 downto 0);  -- to or_equ
  signal satmaxncar24_d      : std_logic_vector(5 downto 0);  -- to or_equ
  -- MDMaINITSYNCCNTL
  signal detect_thr_carrier : std_logic_vector(3 downto 0);
  signal detect_thr_carrier_d : std_logic_vector(3 downto 0);
  signal initsync_timoffst   : std_logic_vector(2 downto 0);
  signal initsync_timoffst_d : std_logic_vector(2 downto 0);
  -- Combiner accumulator for slow preamble detection.
  signal initsync_autothr1   : std_logic_vector(5 downto 0);
  signal initsync_autothr1_d : std_logic_vector(5 downto 0);
  -- Combiner accumulator for fast preamble detection.
  signal initsync_autothr0   : std_logic_vector(5 downto 0);
  signal initsync_autothr0_d : std_logic_vector(5 downto 0);
  -- MDMaPRBSCNTL
  signal prbs_inv            : std_logic;
  signal prbs_inv_d          : std_logic;
  signal prbs_sel            : std_logic_vector(1 downto 0);
  signal prbs_sel_d          : std_logic_vector(1 downto 0);
  signal prbs_init           : std_logic_vector(22 downto 0);
  signal prbs_init_d         : std_logic_vector(22 downto 0);
  -- MDMaIQCALIBCNTL1
  signal calmode             : std_logic;
  signal calmode_d           : std_logic;
  signal calgain             : std_logic_vector(2 downto 0);
  signal calgain_d           : std_logic_vector(2 downto 0);
  signal calfrq0             : std_logic_vector(22 downto 0);
  signal calfrq0_d           : std_logic_vector(22 downto 0);
  -- Modem A2 version register.
  signal int_build           : std_logic_vector(15 downto 0);  -- Build of modema.
  signal int_rel             : std_logic_vector( 7 downto 0);  -- Release number.
  signal int_upg             : std_logic_vector( 7 downto 0);  -- Upgrade number.
  -- Combinational signals for prdata buses.
  signal next_apb_rdata      : std_logic_vector(31 downto 0);
  -- Frontend registers generation.
  signal gen_frontend_reg    : std_logic;


begin


  ------------------------------------------------------------------------------
  -- Frontend registers generation.
  ------------------------------------------------------------------------------
  FRONTEND_REG_G : IF radio_interface_g = 1 or radio_interface_g = 3 GENERATE
    gen_frontend_reg <= '1';
  END GENERATE FRONTEND_REG_G;
    
  NO_FRONTEND_REG_G : IF radio_interface_g = 2 GENERATE
    gen_frontend_reg <= '0';
  END GENERATE NO_FRONTEND_REG_G;


  ------------------------------------------------------------------------------
  -- Fixed registers.
  ------------------------------------------------------------------------------
  -- Modema2 version register.
  int_build <= "0000000000000000";
  int_rel   <= "00000001";
  int_upg   <= "00000011";

  --------------------------------------------
  -- Registers write process.
  -- Combinational part.
  --------------------------------------------
  write_register_comb_p : process( adc_powerdown_dyn, add_short_pre,
                                   apb_addr_i, apb_enable_i, apb_sel_i,
                                   apb_wdata_i, apb_write_i, calfrq0, calgain,
                                   calmode, tx_enddel, dac_powerdown_dyn,
                                   detect_thr_carrier, histoffset12,
                                   histoffset18, histoffset24, histoffset36,
                                   histoffset48, histoffset54, histoffset6,
                                   histoffset9, initsync_autothr0,
                                   initsync_autothr1, initsync_timoffst,
                                   iq_mm_est, prbs_init, prbs_inv, prbs_sel,
                                   reduceerasures, rx_iq_step_ph, res_dco_disb,
                                   rx_iq_g_preset, rx_iq_ph_preset,
                                   rx_iq_step_g, satmaxncar12, gen_frontend_reg,
                                   satmaxncar18, satmaxncar24, satmaxncar36,
                                   satmaxncar48, satmaxncar54, satmaxncar6,
                                   satmaxncar9, tx_filter_bypass, tx_iq_ampl,
                                   tx_iq_phase, tx_norm_factor, c2disb_tx,
                                   scrinitval, scrmode, rx_length_chk_en,
                                   wf_window, c2disb_rx, rx_del_dc_cor,
                                   rx_length_limit, tx_const, dc_off_disb)
  begin

    -- MDMaTXCNTL
    add_short_pre_d     <= add_short_pre;
    scrmode_d           <= scrmode;
    tx_filter_bypass_d  <= tx_filter_bypass;
    dac_powerdown_dyn_d <= dac_powerdown_dyn;
    tx_enddel_d         <= tx_enddel;
    scrinitval_d        <= scrinitval;
    c2disb_tx_d         <= c2disb_tx;
    tx_norm_factor_d    <= tx_norm_factor;
    -- MDMaTXIQCOMP
    tx_iq_phase_d       <= tx_iq_phase;
    tx_iq_ampl_d        <= tx_iq_ampl;
    -- MDMaTXCONST
    tx_const_d          <= tx_const;
    -- MDMaRXCNTL0
    rx_iq_step_ph_d     <= rx_iq_step_ph;
    rx_iq_step_g_d      <= rx_iq_step_g;
    adc_powerdown_dyn_d <= adc_powerdown_dyn;
    c2disb_rx_d         <= c2disb_rx;
    wf_window_d         <= wf_window;
    reduceerasures_d    <= reduceerasures;
    res_dco_disb_d      <= res_dco_disb;
    iq_mm_estrst_d      <= '0';         -- this bit is always read as '0'
    dc_off_disb_d       <= dc_off_disb;
    iq_mm_est_d         <= iq_mm_est;
    -- MDMaRXCNTL1
    rx_length_chk_en_d  <= rx_length_chk_en;
    rx_length_limit_d   <= rx_length_limit;
    rx_del_dc_cor_d     <= rx_del_dc_cor;
    -- MDMaRXIQPRESET
    rx_iq_ph_preset_d   <= rx_iq_ph_preset;
    rx_iq_g_preset_d    <= rx_iq_g_preset;
    -- MDMaRXIQEST
    -- MDMaEQCNTL1
    histoffset18_d      <= histoffset18;
    histoffset12_d      <= histoffset12;
    histoffset9_d       <= histoffset9;
    histoffset6_d       <= histoffset6;
    satmaxncar18_d      <= satmaxncar18;
    satmaxncar12_d      <= satmaxncar12;
    satmaxncar9_d       <= satmaxncar9;
    satmaxncar6_d       <= satmaxncar6;
    -- MDMaEQCNTL2
    histoffset54_d      <= histoffset54;
    histoffset48_d      <= histoffset48;
    histoffset36_d      <= histoffset36;
    histoffset24_d      <= histoffset24;
    satmaxncar54_d      <= satmaxncar54;
    satmaxncar48_d      <= satmaxncar48;
    satmaxncar36_d      <= satmaxncar36;
    satmaxncar24_d      <= satmaxncar24;
    -- MDMaINITSYNCCNTL
    detect_thr_carrier_d <= detect_thr_carrier;
    initsync_timoffst_d <= initsync_timoffst;
    -- Combiner accumulator for slow preamble detection.
    initsync_autothr1_d <= initsync_autothr1;
    -- Combiner accumulator for fast preamble detection.
    initsync_autothr0_d <= initsync_autothr0;
    -- MDMaPRBSCNTL
    prbs_inv_d          <= prbs_inv;
    prbs_sel_d          <= prbs_sel;
    prbs_init_d         <= prbs_init;
    -- MDMaIQCALIBCNTL1
    calmode_d           <= calmode;
    calgain_d           <= calgain;
    calfrq0_d           <= calfrq0;
    ---------------------------------------------------------------------
    if ( apb_sel_i = '1' and apb_write_i = '1' and apb_enable_i = '1' ) then
      case apb_addr_i is
        when TX_CTRL_ADDR_CT =>
          add_short_pre_d       <= apb_wdata_i(29 downto 28);
          scrmode_d             <= apb_wdata_i(26);
          tx_enddel_d           <= apb_wdata_i(23 downto 16);
          scrinitval_d          <= apb_wdata_i(15 downto 9);
          if gen_frontend_reg = '1' then
            tx_filter_bypass_d  <= apb_wdata_i(25);
            dac_powerdown_dyn_d <= apb_wdata_i(24);
            c2disb_tx_d         <= apb_wdata_i(8);
            tx_norm_factor_d    <= apb_wdata_i(7 downto 0);
          end if;
        when TX_IQCOMP_ADDR_CT =>
          if gen_frontend_reg = '1' then
            tx_iq_phase_d     <= apb_wdata_i(21 downto 16);
            tx_iq_ampl_d      <= apb_wdata_i(8 downto 0);
          end if;
        when TX_CONST_ADDR_CT =>
          if gen_frontend_reg = '1' then
            tx_const_d        <= apb_wdata_i(7 downto 0);
          end if;
        when RX_CTRL0_ADDR_CT =>
          rx_iq_step_ph_d     <= apb_wdata_i(31 downto 24);
          rx_iq_step_g_d      <= apb_wdata_i(23 downto 16);
          wf_window_d         <= apb_wdata_i(7 downto 6);
          reduceerasures_d    <= apb_wdata_i(5 downto 4);
          res_dco_disb_d      <= apb_wdata_i(3);
          iq_mm_estrst_d      <= apb_wdata_i(2);
          iq_mm_est_d         <= apb_wdata_i(0);
          if gen_frontend_reg = '1' then
            adc_powerdown_dyn_d <= apb_wdata_i(15);
            c2disb_rx_d         <= apb_wdata_i(8);
            dc_off_disb_d       <= apb_wdata_i(1);
          end if;
        when RX_CTRL1_ADDR_CT =>
          rx_length_chk_en_d  <= apb_wdata_i(20);
          rx_length_limit_d   <= apb_wdata_i(19 downto 8);
          if gen_frontend_reg = '1' then
            rx_del_dc_cor_d   <= apb_wdata_i(7 downto 0);
          end if;
        when RX_IQPRESET_ADDR_CT =>
          rx_iq_ph_preset_d <= apb_wdata_i(31 downto 16);
          rx_iq_g_preset_d  <= apb_wdata_i(15 downto 0);
        when EQU_CTRL1_ADDR_CT =>
          histoffset18_d <= apb_wdata_i(31 downto 30);
          satmaxncar18_d <= apb_wdata_i(29 downto 24);
          histoffset12_d <= apb_wdata_i(23 downto 22);
          satmaxncar12_d <= apb_wdata_i(21 downto 16);
          histoffset9_d  <= apb_wdata_i(15 downto 14);
          satmaxncar9_d  <= apb_wdata_i(13 downto 8);
          histoffset6_d  <= apb_wdata_i(7 downto 6);
          satmaxncar6_d  <= apb_wdata_i(5 downto 0);
        when EQU_CTRL2_ADDR_CT =>
          histoffset54_d <= apb_wdata_i(31 downto 30);
          satmaxncar54_d <= apb_wdata_i(29 downto 24);
          histoffset48_d <= apb_wdata_i(23 downto 22);
          satmaxncar48_d <= apb_wdata_i(21 downto 16);
          histoffset36_d <= apb_wdata_i(15 downto 14);
          satmaxncar36_d <= apb_wdata_i(13 downto 8);
          histoffset24_d <= apb_wdata_i(7 downto 6);
          satmaxncar24_d <= apb_wdata_i(5 downto 0);
        when INITSYNC_CTRL_ADDR_CT =>
          initsync_timoffst_d <= apb_wdata_i(18 downto 16);
          if gen_frontend_reg = '1' then
            detect_thr_carrier_d <= apb_wdata_i(27 downto 24);
            initsync_autothr1_d <= apb_wdata_i(13 downto 8);
            initsync_autothr0_d <= apb_wdata_i(5 downto 0);
          end if;
        when PRBS_CTRL_ADDR_CT =>
          prbs_inv_d  <= apb_wdata_i(28);
          prbs_sel_d  <= apb_wdata_i(25 downto 24);
          prbs_init_d <= apb_wdata_i(22 downto 0);
        when IQCALIB_CTRL_ADDR_CT =>
          calmode_d   <= apb_wdata_i(31);
          calgain_d   <= apb_wdata_i(26 downto 24);
          calfrq0_d   <= apb_wdata_i(22 downto 0);
        when others =>
          null;
      end case;
    end if;
  end process write_register_comb_p;

  --------------------------------------------
  -- Registers write process.
  -- Sequencial part, synchronous to apb_clk.
  --------------------------------------------
  write_register_seq_p : process(reset_n, apb_clk)
  begin
    if ( reset_n = '0' ) then
      -- MDMaTXCNTL
      add_short_pre     <= "00";
      scrmode           <= '0';
      tx_filter_bypass  <= '0';
      dac_powerdown_dyn <= '1';
      tx_enddel         <= "00011110";
      scrinitval        <= "1010110";
      c2disb_tx         <= '1';
      tx_norm_factor    <= "10001111";
      -- MDMaTXIQCOMP
      tx_iq_phase       <= "000000";
      tx_iq_ampl        <= "100000000";
      -- MDMaTXCONST
      tx_const          <= "00000000";
      -- MDMaRXCNTL0
      rx_iq_step_ph     <= "01011001";
      rx_iq_step_g      <= "00010100";
      adc_powerdown_dyn <= '0';
      c2disb_rx         <= '1';
      wf_window         <= "01";
      reduceerasures    <= "10";
      res_dco_disb      <= '1';
      iq_mm_estrst      <= '0';
      dc_off_disb       <= '0';
      iq_mm_est         <= '0';
      -- MDMaRXCNTL1
      rx_length_chk_en  <= '1';
      rx_length_limit   <= "100100101010";
      rx_del_dc_cor     <= "00110000";
      -- MDMaRXIQPRESET
      rx_iq_ph_preset   <= (others => '0');
      rx_iq_g_preset    <= "1000000000000000";
      -- MDMaEQCNTL1
      histoffset18      <= "01";
      histoffset12      <= "01";
      histoffset9       <= "01";
      histoffset6       <= "01";
      satmaxncar18      <= "101010";
      satmaxncar12      <= "101010";
      satmaxncar9       <= "101010";
      satmaxncar6       <= "101010";
      -- MDMaEQCNTL2
      histoffset54      <= "01";
      histoffset48      <= "01";
      histoffset36      <= "01";
      histoffset24      <= "01";
      satmaxncar54      <= "101010";
      satmaxncar48      <= "101010";
      satmaxncar36      <= "101010";
      satmaxncar24      <= "101010";
      -- MDMaINITSYNCCNTL
      detect_thr_carrier <= "0000";
      initsync_timoffst <= "100";
      -- Combiner accumulator for slow preamble detection.
      initsync_autothr1 <= "000000";
      -- Combiner accumulator for fast preamble detection.
      initsync_autothr0 <= "000000";
      -- MDMaPRBSCNTL
      prbs_inv          <= '0';
      prbs_sel          <= "00";
      prbs_init         <= (others => '0');
      -- MDMaIQCALIBCNTL1
      calmode           <= '0';
      calgain           <= "000";
      calfrq0           <= (others => '0');
      
    elsif ( apb_clk'event and apb_clk = '1' ) then
      -- MDMaTXCNTL
      add_short_pre     <= add_short_pre_d;
      scrmode           <= scrmode_d;
      tx_enddel         <= tx_enddel_d;
      scrinitval        <= scrinitval_d;
      if gen_frontend_reg = '1' then
        tx_filter_bypass  <= tx_filter_bypass_d;
        dac_powerdown_dyn <= dac_powerdown_dyn_d;
        c2disb_tx         <= c2disb_tx_d;
        tx_norm_factor    <= tx_norm_factor_d;
      end if;
      -- MDMaTXIQCOMP
      if gen_frontend_reg = '1' then
        tx_iq_phase     <= tx_iq_phase_d;
        tx_iq_ampl      <= tx_iq_ampl_d;
      end if;
      -- MDMaTXCONST
      if gen_frontend_reg = '1' then
        tx_const        <= tx_const_d;
      end if;
      -- MDMaRXCNTL0
      rx_iq_step_ph     <= rx_iq_step_ph_d;
      rx_iq_step_g      <= rx_iq_step_g_d;
      wf_window         <= wf_window_d;
      reduceerasures    <= reduceerasures_d;
      res_dco_disb      <= res_dco_disb_d;
      iq_mm_estrst      <= iq_mm_estrst_d;
      iq_mm_est         <= iq_mm_est_d;
      if gen_frontend_reg = '1' then
        adc_powerdown_dyn <= adc_powerdown_dyn_d;
        c2disb_rx         <= c2disb_rx_d;
        dc_off_disb       <= dc_off_disb_d;
      end if;
      -- MDMaRXCNTL1
      rx_length_chk_en  <= rx_length_chk_en_d;
      rx_length_limit   <= rx_length_limit_d;
      if gen_frontend_reg = '1' then
        rx_del_dc_cor   <= rx_del_dc_cor_d;
      end if;
      -- MDMaRXIQPRESET
      rx_iq_ph_preset   <= rx_iq_ph_preset_d;
      rx_iq_g_preset    <= rx_iq_g_preset_d;
      -- MDMaEQCNTL1
      histoffset18      <= histoffset18_d;
      histoffset12      <= histoffset12_d;
      histoffset9       <= histoffset9_d;
      histoffset6       <= histoffset6_d;
      satmaxncar18      <= satmaxncar18_d;
      satmaxncar12      <= satmaxncar12_d;
      satmaxncar9       <= satmaxncar9_d;
      satmaxncar6       <= satmaxncar6_d;
      -- MDMaEQCNTL2
      histoffset54      <= histoffset54_d;
      histoffset48      <= histoffset48_d;
      histoffset36      <= histoffset36_d;
      histoffset24      <= histoffset24_d;
      satmaxncar54      <= satmaxncar54_d;
      satmaxncar48      <= satmaxncar48_d;
      satmaxncar36      <= satmaxncar36_d;
      satmaxncar24      <= satmaxncar24_d;
      -- MDMaINITSYNCCNTL
      initsync_timoffst <= initsync_timoffst_d;
      if gen_frontend_reg = '1' then
        detect_thr_carrier <= detect_thr_carrier_d;
        -- Combiner accumulator for slow preamble detection.
        initsync_autothr1 <= initsync_autothr1_d;
        -- Combiner accumulator for fast preamble detection.
        initsync_autothr0 <= initsync_autothr0_d;
      end if;
      -- MDMaPRBSCNTL
      prbs_inv          <= prbs_inv_d;
      prbs_sel          <= prbs_sel_d;
      prbs_init         <= prbs_init_d;
      -- MDMaIQCALIBCNTL1
      if gen_frontend_reg = '1' then
        calmode         <= calmode_d;
        calgain         <= calgain_d;
        calfrq0         <= calfrq0_d;
      end if;
    end if;
  end process write_register_seq_p;

  --------------------------------------------
  -- Registers read process. Combinational.
  --------------------------------------------
  -- The read cycle follows the timing shown in page 5-6 of the AMBA
  -- Specification.
  -- psel is used to detect the beginning of the two-clock-cycle-long APB
  -- read access. This way, the second cycle can be used to register prdata
  -- and comply with interfaces timing requirements.
  read_register_comb_p : process(adc_powerdown_dyn, add_short_pre,
                             apb_addr_i, apb_sel_i, apb_write_i,
                             calfrq0, calgain, calmode, tx_enddel,
                             dac_powerdown_dyn, detect_thr_carrier,
                             histoffset12, histoffset18, histoffset24,
                             histoffset36, histoffset48, histoffset54,
                             histoffset6, histoffset9, initsync_autothr0,
                             initsync_autothr1, initsync_timoffst, int_build,
                             int_rel, int_upg, iq_mm_est, dc_off_disb,
                             iq_mm_estrst, prbs_init, prbs_inv, prbs_sel,
                             reduceerasures, rx_iq_step_ph, res_dco_disb,
                             rx_iq_g_est_i, rx_iq_g_preset, gen_frontend_reg,
                             rx_iq_ph_est_i, rx_iq_ph_preset,
                             rx_freq_off_est_i, rx_iq_step_g,
                             satmaxncar12, satmaxncar18, satmaxncar24, 
                             satmaxncar36, satmaxncar48, satmaxncar54,
                             satmaxncar6, satmaxncar9, tx_filter_bypass,
                             tx_iq_ampl, tx_iq_phase, tx_norm_factor, wf_window,
                             scrmode, scrinitval, tx_scrambler_i,
                             c2disb_tx, c2disb_rx, rx_del_dc_cor,
                             rx_length_chk_en, rx_length_limit, tx_const,
                             rx_ybnb_i)
  begin
    next_apb_rdata <= (others => '0');

    if (apb_sel_i = '1') then

      case apb_addr_i is
        when MDMaVERSION_ADDR_CT =>
          next_apb_rdata <= int_build & int_rel & int_upg;
        
        when TX_CTRL_ADDR_CT =>
          next_apb_rdata(29 downto 28) <= add_short_pre;
          next_apb_rdata(26)           <= scrmode;
          next_apb_rdata(23 downto 16) <= tx_enddel;
          if scrmode = '1' then
            next_apb_rdata(15 downto 9)  <= scrinitval;
          else
            next_apb_rdata(15 downto 9)  <= tx_scrambler_i;
          end if;
          if gen_frontend_reg = '1' then
            next_apb_rdata(25)         <= tx_filter_bypass;
            next_apb_rdata(24)         <= dac_powerdown_dyn;
            next_apb_rdata(8)          <= c2disb_tx;
            next_apb_rdata(7 downto 0) <= tx_norm_factor;
          end if;
        
        when TX_IQCOMP_ADDR_CT =>
          if gen_frontend_reg = '1' then
            next_apb_rdata(21 downto 16) <= tx_iq_phase;
            next_apb_rdata(8 downto 0)   <= tx_iq_ampl;
          end if;
        
        when TX_CONST_ADDR_CT =>
          if gen_frontend_reg = '1' then
            next_apb_rdata(7 downto 0) <= tx_const;
          end if;
        
        when RX_CTRL0_ADDR_CT =>
          next_apb_rdata(31 downto 24) <= rx_iq_step_ph;
          next_apb_rdata(23 downto 16) <= rx_iq_step_g;
          next_apb_rdata(7 downto 6)   <= wf_window;
          next_apb_rdata(5 downto 4)   <= reduceerasures;
          next_apb_rdata(3)            <= res_dco_disb;
          next_apb_rdata(2)            <= iq_mm_estrst;
          next_apb_rdata(0)            <= iq_mm_est;
          if gen_frontend_reg = '1' then
            next_apb_rdata(15)         <= adc_powerdown_dyn;
            next_apb_rdata(8)          <= c2disb_rx;
            next_apb_rdata(1)          <= dc_off_disb;
          end if;
        
        when RX_CTRL1_ADDR_CT =>
          next_apb_rdata(20)           <= rx_length_chk_en;
          next_apb_rdata(19 downto 8)  <= rx_length_limit;
          if gen_frontend_reg = '1' then
            next_apb_rdata(7 downto 0) <= rx_del_dc_cor;
          end if;
        
        when RX_IQPRESET_ADDR_CT =>
          next_apb_rdata(31 downto 16) <= rx_iq_ph_preset;
          next_apb_rdata(15 downto 0)  <= rx_iq_g_preset;
        
        when RX_IQEST_ADDR_CT =>
          next_apb_rdata(31 downto 16) <= rx_iq_ph_est_i;
          next_apb_rdata(15 downto 0)  <= rx_iq_g_est_i;

        when TIME_DOM_STAT_ADDR_CT =>
          next_apb_rdata(26 downto 20) <= rx_ybnb_i;
          next_apb_rdata(19 downto 0)  <= rx_freq_off_est_i;

        when EQU_CTRL1_ADDR_CT =>
          next_apb_rdata(31 downto 30) <= histoffset18;
          next_apb_rdata(23 downto 22) <= histoffset12;
          next_apb_rdata(15 downto 14) <= histoffset9;
          next_apb_rdata(7 downto 6)   <= histoffset6;
          next_apb_rdata(29 downto 24) <= satmaxncar18;
          next_apb_rdata(21 downto 16) <= satmaxncar12;
          next_apb_rdata(13 downto 8)  <= satmaxncar9;
          next_apb_rdata(5 downto 0)   <= satmaxncar6;
        
        when EQU_CTRL2_ADDR_CT =>
          next_apb_rdata(31 downto 30) <= histoffset54;
          next_apb_rdata(23 downto 22) <= histoffset48;
          next_apb_rdata(15 downto 14) <= histoffset36;
          next_apb_rdata(7 downto 6)   <= histoffset24;
          next_apb_rdata(29 downto 24) <= satmaxncar54;
          next_apb_rdata(21 downto 16) <= satmaxncar48;
          next_apb_rdata(13 downto 8)  <= satmaxncar36;
          next_apb_rdata(5 downto 0)   <= satmaxncar24;
        
        when INITSYNC_CTRL_ADDR_CT =>
          next_apb_rdata(18 downto 16) <= initsync_timoffst;
          if gen_frontend_reg = '1' then
            next_apb_rdata(27 downto 24) <= detect_thr_carrier;
            -- Combiner accumulator for slow preamble detection.
            next_apb_rdata(13 downto 8)  <= initsync_autothr1;
            -- Combiner accumulator for fast preamble detection.
            next_apb_rdata(5 downto 0)   <= initsync_autothr0;
          end if;
        
        when PRBS_CTRL_ADDR_CT =>
          next_apb_rdata(28)           <= prbs_inv;
          next_apb_rdata(25 downto 24) <= prbs_sel;
          next_apb_rdata(22 downto 0)  <= prbs_init;
        
        when IQCALIB_CTRL_ADDR_CT =>
          if gen_frontend_reg = '1' then
            next_apb_rdata(31)           <= calmode;
            next_apb_rdata(26 downto 24) <= calgain;
            next_apb_rdata(22 downto 0)  <= calfrq0;
          end if;
        
        when others =>
          next_apb_rdata <= (others => '0');
          
      end case;
    end if;
  end process read_register_comb_p;

  -- Register rdata output.
  read_register_seq_p: process (apb_clk, reset_n)
  begin
    if reset_n = '0' then
      apb_rdata_o <= (others => '0');      
    elsif apb_clk'event and apb_clk = '1' then
      if apb_sel_i = '1' then
        apb_rdata_o <= next_apb_rdata;
      end if;
    end if;
  end process read_register_seq_p;

  ------------------------------------------------------------------------------
  -- Assign calib_test_o output port.
  ------------------------------------------------------------------------------
    -- calib_test_o is high when the modem is in PRBS test mode or
    -- calibration mode.
    calib_test_o <= '1'
                    when (calmode = '1' and gen_frontend_reg = '1') or 
                          prbs_sel /= "00"
                    else '0';

  ------------------------------------------------------------------------------
  -- Assign iq_mm_estrst_flag.
  ------------------------------------------------------------------------------
  -- iq_mm_estrst_flag is high when iq_mm_estrst is set by software,
  -- and low when the iq_mm_estrst_done_i is set by iq_estimation.
  iq_mm_estrst_flag_p : process(reset_n, apb_clk)
  begin
    if reset_n = '0' then
      iq_mm_estrst_flag <= '0';
    elsif apb_clk'event and apb_clk = '1' then
      if iq_mm_estrst = '1' then
        iq_mm_estrst_flag <= '1';
      elsif iq_mm_estrst_done_i = '1' then
        iq_mm_estrst_flag <= '0';
      end if;
    end if;
  end process iq_mm_estrst_flag_p;

  -----------------------------------------------------------------------------
  -- Output assignment.
  -----------------------------------------------------------------------------
  -- MDMaTXCNTL
  add_short_pre_o     <= add_short_pre;
  scrmode_o           <= scrmode;
  tx_filter_bypass_o  <= tx_filter_bypass when gen_frontend_reg = '1' else '0';
  dac_powerdown_dyn_o <= dac_powerdown_dyn when gen_frontend_reg = '1' else '1';
  tx_enddel_o         <= tx_enddel;
  scrinitval_o        <= scrinitval;
  c2disb_tx_o         <= c2disb_tx when gen_frontend_reg = '1' else '0';
  tx_norm_factor_o    <= tx_norm_factor when gen_frontend_reg = '1' 
                    else (others => '0');
  -- MDMaTXIQCOMP
  tx_iq_phase_o       <= tx_iq_phase when gen_frontend_reg = '1' 
                    else (others => '0');
  tx_iq_ampl_o        <= tx_iq_ampl when gen_frontend_reg = '1' 
                    else (others => '0');
  -- MDMaTXCONST
  tx_const_o          <= tx_const when gen_frontend_reg = '1' 
                    else (others => '0');
  -- MDMaRXCNTL0
  rx_iq_step_ph_o     <= rx_iq_step_ph;
  rx_iq_step_g_o      <= rx_iq_step_g;
  adc_powerdown_dyn_o <= adc_powerdown_dyn when gen_frontend_reg = '1' else '0';
  c2disb_rx_o         <= c2disb_rx when gen_frontend_reg = '1' else '0';
  wf_window_o         <= wf_window;
  reduceerasures_o    <= reduceerasures;
  res_dco_disb_o      <= res_dco_disb;
  iq_mm_estrst_o      <= iq_mm_estrst_flag;
  dc_off_disb_o       <= dc_off_disb when gen_frontend_reg = '1' else '0';
  iq_mm_est_o         <= iq_mm_est;
  -- MDMaRXCNTL1
  rx_length_chk_en_o  <= rx_length_chk_en;
  rx_length_limit_o   <= rx_length_limit;
  rx_del_dc_cor_o     <= rx_del_dc_cor when gen_frontend_reg = '1' 
                    else (others => '0');
  -- MDMaRXIQPRESET
  rx_iq_ph_preset_o   <= rx_iq_ph_preset;
  rx_iq_g_preset_o    <= rx_iq_g_preset;
  -- MDMaEQCNTL1
  histoffset18_o      <= histoffset18;
  histoffset12_o      <= histoffset12;
  histoffset9_o       <= histoffset9;
  histoffset6_o       <= histoffset6;
  satmaxncar18_o      <= satmaxncar18;
  satmaxncar12_o      <= satmaxncar12;
  satmaxncar9_o       <= satmaxncar9;
  satmaxncar6_o       <= satmaxncar6;
  -- MDMaEQCNTL2
  histoffset54_o      <= histoffset54;
  histoffset48_o      <= histoffset48;
  histoffset36_o      <= histoffset36;
  histoffset24_o      <= histoffset24;
  satmaxncar54_o      <= satmaxncar54;
  satmaxncar48_o      <= satmaxncar48;
  satmaxncar36_o      <= satmaxncar36;
  satmaxncar24_o      <= satmaxncar24;
  -- MDMaINITSYNCCNTL
  detect_thr_carrier_o <= detect_thr_carrier when gen_frontend_reg = '1' 
                     else (others => '0');
  initsync_timoffst_o <= initsync_timoffst;
  -- Combiner accumulator for slow preamble detection.
  initsync_autothr1_o <= initsync_autothr1 when gen_frontend_reg = '1' 
                    else (others => '0');
  -- Combiner accumulator for fast preamble detection.
  initsync_autothr0_o <= initsync_autothr0 when gen_frontend_reg = '1' 
                    else (others => '0');
  -- MDMaPRBSCNTL
  prbs_inv_o          <= prbs_inv;
  prbs_sel_o          <= prbs_sel;
  prbs_init_o         <= prbs_init;
  -- MDMaIQCALIBCNTL1
  calmode_o           <= calmode when gen_frontend_reg = '1' else '0';
  calgain_o           <= calgain when gen_frontend_reg = '1' 
                    else (others => '0');
  calfrq0_o           <= calfrq0 when gen_frontend_reg = '1' 
                    else (others => '0');

end rtl;
