

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of rx_path_core is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Signals for symbol synchronization.
  ------------------------------------------------------------------------------
  signal barker_sync         : std_logic; 
  signal symbol_synchro_int  : std_logic; 
  signal symbol_synchro_ff1  : std_logic; 
  signal symbol_synchro_ff2  : std_logic; 
  signal symbol_synchro_ff3  : std_logic; 
  signal symbol_synchro_ff4  : std_logic;
  --signal symbol_synchro_ff5  : std_logic;   
  signal rx_enable_ff1       : std_logic; 
    
  ------------------------------------------------------------------------------
  -- Signals for DC offset
  ------------------------------------------------------------------------------
  -- dc offset compensation output datas.
  signal data_dc_i : std_logic_vector(7 downto 0);
  signal data_dc_q : std_logic_vector(7 downto 0);
  
  ------------------------------------------------------------------------------
  -- Signals for IQ mismatch
  ------------------------------------------------------------------------------
  -- iq mismatch compensation output datas.
  signal data_iq_i : std_logic_vector(7 downto 0);
  signal data_iq_q : std_logic_vector(7 downto 0);

  ------------------------------------------------------------------------------
  -- Signals for rx11b_demod
  ------------------------------------------------------------------------------
  signal interpolator_enable : std_logic;
  signal valid_symbol        : std_logic;
  signal biggest_index       : std_logic_vector(5 downto 0);
  signal demap_data          : std_logic_vector(1 downto 0);
  signal remod_data_sync     : std_logic;
  signal rho_int             : std_logic_vector(3 downto 0);  -- rho parameter value.
  signal mu_int              : std_logic_vector(3 downto 0);  -- mu parameter value.
  signal phi                 : std_logic_vector(angle_length_g-1 downto 0);  -- was for debug
  signal omega               : std_logic_vector(11 downto 0);
  signal sigma_est           : std_logic_vector(9 downto 0);
  ------------------------------------------------------------------------------
  -- Signals for equalizer
  ------------------------------------------------------------------------------
  -- Use a multiplier of the equalizer for peak_detect.
  signal abs_2_corr        : std_logic_vector(15 downto 0);
  signal d_signed_peak_i   : std_logic_vector(7 downto 0);
  signal d_signed_peak_q   : std_logic_vector(7 downto 0);
  -- Incoming data stream at 22 MHz (I and Q).
  signal filter_out_i_sync : std_logic_vector(7 downto 0);
  signal filter_out_q_sync : std_logic_vector(7 downto 0);  
  -- Remodulated data at 11 MHz (I and Q).  
  signal aligned_data_i   : std_logic_vector(8 downto 0);
  signal aligned_data_q   : std_logic_vector(8 downto 0);
  -- Equalizer outputs
  signal equalizer_data_out_i  : std_logic_vector(data_length_g-1 downto 0);
  signal equalizer_data_out_q  : std_logic_vector(data_length_g-1 downto 0);
  -- Signals delayed to compensate the delay in the equalizer.
  signal symbol_synchro_delay     : std_logic;  
  signal symbol_synchro_delay_ff1 : std_logic;  
  signal mod_type_delay           : std_logic;  
  signal equalizer_disb_sync      : std_logic;
  -- dc offset compensation.
  signal dc_offset_i : std_logic_vector(5 downto 0);
  signal dc_offset_q : std_logic_vector(5 downto 0);

  ------------------------------------------------------------------------------
  -- Signals for phase alignment cordic.
  ------------------------------------------------------------------------------
  signal unused_remo_data : std_logic_vector(7 downto 0);
  signal remod_data_delay : std_logic_vector(1 downto 0);
  signal remod_data_i     : std_logic_vector(7 downto 0);
  signal remod_data_q     : std_logic_vector(7 downto 0);
  signal a_data_i         : std_logic_vector(9 downto 0);
  signal a_data_q         : std_logic_vector(9 downto 0);

  signal enable_cordic : std_logic;
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  ------------------------------------------------------------------------------
  -- DC Offset compensation
  ------------------------------------------------------------------------------
  data_dc_i <= signed(data_in_i) - signed(dc_offset_i) when dcoffdisb = '0'
               else data_in_i;
  data_dc_q <= signed(data_in_q) - signed(dc_offset_q) when dcoffdisb = '0'
               else data_in_q;

  dc_offset_i_stat <= dc_offset_i;
  dc_offset_q_stat <= dc_offset_q;
  ------------------------------------------------------------------------------
  -- IQ Mismatch Compensation
  ------------------------------------------------------------------------------
  iq_mismatch_1 : iq_mismatch
    port map (
      -- Clock and reset
      clk                    => rx_path_b_gclk,
      reset_n                => reset_n,
      -- Controls.
      iq_estimation_enable   => iq_estimation_enable,
      iq_compensation_enable => iq_compensation_enable,
      -- Data inputs.
      data_in_i              => data_dc_i,
      data_in_q              => data_dc_q,
      -- Data outputs.
      iq_gain_sat_stat       => iq_gain_sat_stat,
      data_out_i             => data_iq_i,
      data_out_q             => data_iq_q
      );


  ------------------------------------------------------------------------------
  -- Barker correlator.
  ------------------------------------------------------------------------------
  barker_cor_1: barker_cor
  generic map (dsize_g => 8)
  port map (
      -- clock and reset.
      reset_n             => reset_n,
      clk                 => rx_path_b_gclk,
      correl_rst_n        => correl_rst_n,
      barker_sync         => barker_sync,
      -- Input data.
      sampl_i             => data_iq_i,
      sampl_q             => data_iq_q,
      -- Saturated correlated outputs.
      peak_data_i         => d_signed_peak_i,
      peak_data_q         => d_signed_peak_q
      );
  
  
  ------------------------------------------------------------------------------
  -- Peak detector.
  ------------------------------------------------------------------------------
  peak_detect_1: peak_detect
  generic map (accu_size_g => 19)
  port map (
      -- clock and reset.
      reset_n             => reset_n,
      clk                 => rx_path_b_gclk,
      accu_resetn         => correl_rst_n,
      -- control.
      synchro_en          => synchro_en,
      mod_type            => mod_type,
      -- Input data.
      abs_2_corr          => abs_2_corr,
      -- 
      barker_sync         => barker_sync,
      symbol_sync         => symbol_synchro_int
      );
      
  symbol_synchro <= symbol_synchro_int;
      
  ------------------------------------------------------------------------------
  -- Data synchronization for equalizer input.
  ------------------------------------------------------------------------------
  data_synchro_p : process (reset_n, rx_path_b_gclk)
  variable cnt : std_logic;
  variable filter_out_i_v : std_logic_vector(7 downto 0);
  variable filter_out_q_v : std_logic_vector(7 downto 0);
  variable data_iq_i_v : std_logic_vector(7 downto 0);
  variable data_iq_q_v : std_logic_vector(7 downto 0);
  begin
    if reset_n='0' then
      filter_out_i_v := (others => '0');
      filter_out_q_v := (others => '0');
      filter_out_i_sync <= (others => '0');
      filter_out_q_sync <= (others => '0');
      data_iq_i_v := (others => '0');
      data_iq_q_v := (others => '0');
      
      cnt:='0';
    elsif rx_path_b_gclk'event and rx_path_b_gclk='1' then
      if symbol_synchro_int='1' then  
        cnt:='0';
      end if;
      if cnt='0' then
        filter_out_i_sync <= filter_out_i_v ;
        filter_out_q_sync <= filter_out_q_v ;
        filter_out_i_v := data_iq_i_v;
        filter_out_q_v := data_iq_q_v;
      end if;
      data_iq_i_v := data_iq_i;
      data_iq_q_v := data_iq_q;
      cnt:=not cnt;
    end if;
  end process data_synchro_p;


  ------------------------------------------------------------------------------
  -- Symbol_synchro delay.
  ------------------------------------------------------------------------------
  symbol_synchro_p : process (reset_n, rx_path_b_gclk)
  begin
    if reset_n='0' then
      symbol_synchro_ff1 <= '0';
      symbol_synchro_ff2 <= '0';
      symbol_synchro_ff3 <= '0';
      symbol_synchro_ff4 <= '0';
      --symbol_synchro_ff5 <= '0';      
    elsif rx_path_b_gclk'event and rx_path_b_gclk='1' then
      symbol_synchro_ff1 <= symbol_synchro_int;
      symbol_synchro_ff2 <= symbol_synchro_ff1;
      symbol_synchro_ff3 <= symbol_synchro_ff2;
      symbol_synchro_ff4 <= symbol_synchro_ff3;
      --symbol_synchro_ff5 <= symbol_synchro_ff4;      
    end if;
  end process symbol_synchro_p;
  
  
  ------------------------------------------------------------------------------
  -- Symbol_synchro delay for the equalizer.
  ------------------------------------------------------------------------------
  -- delay of the symbol_synchro due to the delay in
  -- the equalizer.
  symbol_delay_p : process (reset_n, rx_path_b_gclk)
  variable clk_cnt  : std_logic_vector(1 downto 0);
  variable symbol_synchro_dly12 : std_logic;
  variable symbol_synchro_dly11 : std_logic;
  variable symbol_synchro_dly10 : std_logic;
  variable symbol_synchro_dly9 : std_logic;
  variable symbol_synchro_dly8 : std_logic;
  variable symbol_synchro_dly7 : std_logic;
  variable symbol_synchro_dly6 : std_logic;
  variable symbol_synchro_dly5 : std_logic;
  variable symbol_synchro_dly4 : std_logic;
  variable symbol_synchro_dly3 : std_logic;
  variable symbol_synchro_dly2 : std_logic;
  variable symbol_synchro_dly1 : std_logic;
  begin
    if reset_n='0' then
      clk_cnt  := "00";
        symbol_synchro_dly12 := '0';
        symbol_synchro_dly11 := '0';
        symbol_synchro_dly10 := '0';
        symbol_synchro_dly9 := '0';
        symbol_synchro_dly8 := '0';
        symbol_synchro_dly7 := '0';
        symbol_synchro_dly6 := '0';
        symbol_synchro_dly5 := '0';
        symbol_synchro_dly4 := '0';
        symbol_synchro_dly3 := '0';
        symbol_synchro_dly2 := '0';
        symbol_synchro_dly1 := '0';
        symbol_synchro_delay <= '0';
        symbol_synchro_delay_ff1 <= '0';
        mod_type_delay <= '0';
        equalizer_disb_sync <= '0';
        rx_enable_ff1 <= '0';
    else if rx_path_b_gclk'event and rx_path_b_gclk='1' then
        symbol_synchro_delay     <= '0';
        symbol_synchro_delay_ff1 <= symbol_synchro_delay;
        rx_enable_ff1            <= rx_enable;
        if symbol_synchro_ff4 = '1' then
          mod_type_delay <= mod_type;
          equalizer_disb_sync <= equalizer_disb;
        end if;  
        if symbol_synchro_int = '1' then
          clk_cnt  := "00";
        end if;  
        if clk_cnt = "00" then
          symbol_synchro_delay <= symbol_synchro_dly11;
          symbol_synchro_dly12 := symbol_synchro_dly11;
          symbol_synchro_dly11 := symbol_synchro_dly10;
          symbol_synchro_dly10 := symbol_synchro_dly9;
          symbol_synchro_dly9 := symbol_synchro_dly8;
          symbol_synchro_dly8 := symbol_synchro_dly7;
          symbol_synchro_dly7 := symbol_synchro_dly6;
          symbol_synchro_dly6 := symbol_synchro_dly5;
          symbol_synchro_dly5 := symbol_synchro_dly4;
          symbol_synchro_dly4 := symbol_synchro_dly3;
          symbol_synchro_dly3 := symbol_synchro_dly2;
          symbol_synchro_dly2 := symbol_synchro_dly1;
          symbol_synchro_dly1 := symbol_synchro_int;
        end if;  
        clk_cnt := clk_cnt + '1';
      end if;
    end if;
  end process symbol_delay_p;

  
  ------------------------------------------------------------------------------
  -- Equalizer
  ------------------------------------------------------------------------------
  equalizer_1 :  equalizer
  generic map (
    dsize_g    => 8,  -- Input data size
    csize_g    => 8,  -- Coefficient size 
    coeff_g    => 36, -- Number of filter coefficients (31 to 50)
    delay_g    => 50, -- Delay for remodulation (22 Mchip/s)
    
    -- for ffwd_estimation:
    -- generics for coefficients calculation
    shifta_g   => 14,  -- data size after shifting by alpha.
    cacsize_g  => 19,  -- accumulated coeff size  
    -- generics for DC_output calculation
    dccoeff_g  => 19, -- numbers of bits kept from coeff to calc sum.
    sum_g      => 8,  -- data size of the sum
    multerr_g  => 12, -- data size after the mult by error
    shiftb_g   => 14, -- data size after shifting by beta
    dcacsize_g => 17, -- accumulated dc_offset size  
    dcsize_g   => 6,  -- DC_offset size (output)
    outsize_g  => 9,

    -- Generics for shared multipliers data size.
    p_size_g   => 8   -- nb of input bits from correlator for peak_detect
  )
  port map (
    -------------------------------
    -- reset and clock
    -------------------------------
    reset_n         => reset_n,
    clk             => rx_path_b_gclk,
    -------------------------------
    -- Control signals
    -------------------------------
    equ_activate     => equ_activate,         -- activate the equalizer
    equalizer_init_n => equalizer_init_n,     -- filter coeffs=0  when low.
    equalizer_disb   => equalizer_disb_sync,  -- Disable the filter when high.
    data_sync        => symbol_synchro_ff3,   -- Pulse at first data.
    --data_sync        => symbol_synchro_ff5,
    alpha_accu_disb  => alpha_accu_disb,      -- stop coeff accu when high.
    beta_accu_disb   => beta_accu_disb,       -- stop dc accu when high.
    -------------------------------
    -- Equalizer inputs
    -------------------------------
    -- Incoming data stream at 22 MHz (I and Q).
    data_fil_i       => filter_out_i_sync,
    data_fil_q       => filter_out_q_sync,
    -- Remodulated data at 11 MHz (I and Q).
    remod_data_i     => a_data_i(8 downto 0),
    remod_data_q     => a_data_q(8 downto 0),
    -- Equalizer parameters.
    alpha            => alpha,
    beta             => beta,
    -- Data to multiply  when equalizer is disabled for peak detector
    d_signed_peak_i  => d_signed_peak_i,
    d_signed_peak_q  => d_signed_peak_q,
    -------------------------------
    -- Equalizer outputs
    -------------------------------
    equalized_data_i => equalizer_data_out_i,
    equalized_data_q => equalizer_data_out_q,
    -- Output for peak_detect
    abs_2_corr       => abs_2_corr,
    -- Register stat
    coeff_sum_i_stat => coeff_sum_i_stat,
    coeff_sum_q_stat => coeff_sum_q_stat,
    -- Output for DC Offset compensation
    dc_offset_i      => dc_offset_i,
    dc_offset_q      => dc_offset_q,
    -------------------------------
    -- Diag ports
    -------------------------------
    diag_error_i     => diag_error_i,
    diag_error_q     => diag_error_q
  );


  ------------------------------------------------------------------------------
  -- DSSS / CCK demodulation and phase compensation
  ------------------------------------------------------------------------------
  -- Extend rho and mu to four bits.
  rho_int           <= "00" & rho;
  mu_int            <= '0' & mu;
  phi               <= (others => '0');
  omega             <= (others => '0');


  interpolator_enable <= not interp_disb;

  rx11b_demod_1 : rx11b_demod
    generic map (
      global_enable_g        => 0,  -- Do not assign global signals.
      data_length_g          => data_length_g,  -- data size.
      angle_length_g         => angle_length_g, -- input angle size.
      -- number of microrotation stages in a combinational path :
      nbr_cordic_combstage_g => 3,
      nbr_cordic_pipe_g      => 4   -- number of pipes in the cordic
    )
    port map (
      -- clock and reset.
      reset_n             => reset_n,
      clk                 => rx_path_b_gclk,

      symbol_sync         => symbol_synchro_delay,
      precomp_enable      => precomp_enable,       -- Reload the omega accumulator
      mod_type            => mod_type_delay,       -- Modulation type: '0' for DSSS, '1' for CCK.
      demod_rate          => demod_rate,           -- '0' for BPSK, '1' for QPSK
      cck_rate            => cck_rate,             -- '0' for 5.5 Mhz, '1' for 11 Mhz
      enable_error        => enable_error,         -- Enable error calculation when high
      interpolation_enable => interpolator_enable, -- Enable the Interpolation.
      rho                 => rho_int,              -- rho parameter value.
      mu                  => mu_int,               -- mu parameter value.    
      -- Angles.
      phi                 => phi,
      omega               => omega,
      sigma               => sigma_est,
      tau                 => tau_est,
      -- Data Inputs.
      data_in_i           => equalizer_data_out_i,
      data_in_q           => equalizer_data_out_q,
      -- Data Outputs.
      freqoffestim_stat   => freqoffestim_stat,
      demap_data_out      => demap_data,
      biggest_index       => biggest_index,
      remod_type          => remod_type,
      valid_symbol        => valid_symbol,
      data_to_remod       => demod_data,
      remod_data_sync     => remod_data_sync
     );


  ------------------------------------------------------------------------------
  -- Decode Path
  ------------------------------------------------------------------------------
  decode_path_1 : decode_path
    port map (
    ---------------------
    -- clocks and reset
    ---------------------
    clk    => rx_path_b_gclk,
    reset_n => reset_n,
    ---------------------
    -- inputs
    ---------------------
    -- data
    demap_data      => demap_data,     -- data from demapping
    d_from_cck_dem  => biggest_index,  -- data from cck_demod
    -- blocks activation
    decode_path_activate  => decode_path_activate,
    diff_decod_first_val  => diff_decod_first_val,
    -- control signals
    sfderr          => sfderr, -- Number of errors allowed
    sfdlen          => sfdlen,
    sfd_detect_enable => sfd_detect_enable,
    symbol_sync     => valid_symbol,
    rec_mode        => rec_mode,
    scrambling_disb => scrambling_disb, -- disable the descr.when high 

    ---------------------
    -- outputs
    ---------------------
    sfd_found       => sfd_found,
    preamble_type   => preamble_type,
    phy_data_ind    => phy_data_ind,
    data_to_bup     => data_to_bup

  );

  ------------------------------------------------------------------------------
  -- Remodulation management
  ------------------------------------------------------------------------------
  remod_enable   <= rx_enable_ff1;
  remod_data_req <= remod_data_sync;
  remod_bq       <= demod_rate;

  
  ------------------------------------------------------------------------------
  -- Phase Aligment CORDIC
  ------------------------------------------------------------------------------
   remod_data_i(7 downto 0) <= "00000000" when remod_data_delay="01" or 
                                               remod_data_delay="10" or 
                                               rx_enable_ff1='0' else
                               "10110100" when remod_data_delay="11" else
                               "01001100";
 
   remod_data_q(7 downto 0) <= "00000000" when remod_data_delay="00" or 
                                               remod_data_delay="11" or 
                                               rx_enable_ff1='0' else
                               "10110100" when remod_data_delay="10" else
                               "01001100";

   -- Add delay to align remodulated datas with sigma.
   remod_data_delay_p : process(rx_path_b_gclk, reset_n)
   --variable remod_data_dly7_v : std_logic_vector(1 downto 0);
   --variable remod_data_dly6_v : std_logic_vector(1 downto 0);
   variable remod_data_dly5_v : std_logic_vector(1 downto 0);
   variable remod_data_dly4_v : std_logic_vector(1 downto 0);
   variable remod_data_dly3_v : std_logic_vector(1 downto 0);
   variable remod_data_dly2_v : std_logic_vector(1 downto 0);
   variable remod_data_dly1_v : std_logic_vector(1 downto 0);
   variable cnt               : std_logic_vector(1 downto 0);
   begin
     if reset_n='0' then
       remod_data_delay <= "00";
       --remod_data_dly7_v := "00";
       --remod_data_dly6_v := "00";
       remod_data_dly5_v := "00";
       remod_data_dly4_v := "00";
       remod_data_dly3_v := "00";
       remod_data_dly2_v := "00";
       remod_data_dly1_v := "00";
       cnt:="00";
     elsif rx_path_b_gclk'event and rx_path_b_gclk='1' then
       cnt:=cnt + "1";  
       
       --remod_data_delay <= remod_data_dly6_v;
       remod_data_delay <= remod_data_dly5_v;
       if remod_data_sync='1' then
         cnt := "11";
       end if;  
       if cnt = "11" then
         --remod_data_dly7_v := remod_data_dly6_v;
         --remod_data_dly6_v := remod_data_dly5_v;
         remod_data_dly5_v := remod_data_dly4_v;
         remod_data_dly4_v := remod_data_dly3_v;
         remod_data_dly3_v := remod_data_dly2_v;
         remod_data_dly2_v := remod_data_dly1_v;
         remod_data_dly1_v := remod_data;
       end if;
     end if;
   end process remod_data_delay_p;
   
  enable_cordic <= '1';
 
  phase_aligment_cordic_1 : cordic
    generic map (
      data_length_g          => 8,
      angle_length_g         => 10,
      nbr_combstage_g        => 2,
      nbr_pipe_g             => 4,
      nbr_input_g            => 1)
    port map (
      clk                 => rx_path_b_gclk,
      reset_n             => reset_n,
      enable              => enable_cordic,
      z_in                => sigma_est,
      x0_in               => remod_data_i,
      y0_in               => remod_data_q,
      x1_in               => unused_remo_data,
      y1_in               => unused_remo_data,
      x2_in               => unused_remo_data,
      y2_in               => unused_remo_data,
      x3_in               => unused_remo_data,
      y3_in               => unused_remo_data,
      x0_out              => a_data_i,
      y0_out              => a_data_q,
      x1_out              => open,
      y1_out              => open,
      x2_out              => open,
      y2_out              => open,
      x3_out              => open,
      y3_out              => open
      );


  al_data_sync : process (reset_n,rx_path_b_gclk)
  variable aligned_data_i_ff1 : std_logic_vector(8 downto 0);
  variable aligned_data_q_ff1 : std_logic_vector(8 downto 0);
  variable aligned_data_i_ff2 : std_logic_vector(8 downto 0);
  variable aligned_data_q_ff2 : std_logic_vector(8 downto 0);
  begin
    if reset_n='0' then
      aligned_data_i_ff1 := (others => '0');
      aligned_data_q_ff1 := (others => '0');
      aligned_data_i_ff2 := (others => '0');
      aligned_data_q_ff2 := (others => '0');
      aligned_data_i <= (others => '0');
      aligned_data_q <= (others => '0');
    elsif rx_path_b_gclk'event and rx_path_b_gclk='1' then
--       aligned_data_i <= aligned_data_i_ff1;
--       aligned_data_q <= aligned_data_q_ff1;
      aligned_data_i_ff2 := aligned_data_i_ff1; 
      aligned_data_q_ff2 := aligned_data_q_ff1; 
      aligned_data_i_ff1 := a_data_i(8 downto 0);
      aligned_data_q_ff1 := a_data_q(8 downto 0);
      aligned_data_i <= a_data_i(8 downto 0);
      aligned_data_q <= a_data_q(8 downto 0);
    end if;
  end process al_data_sync;    
      
--        aligned_data_i <= a_data_i(8 downto 0);
--        aligned_data_q <= a_data_q(8 downto 0);

  --Global signals.
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off
--  data_dc_i_gbl <= data_dc_i;
--  data_dc_q_gbl <= data_dc_q;
--  data_iq_i_gbl <= data_iq_i;
--  data_iq_q_gbl <= data_iq_q;
--  barker_sync_gbl <= barker_sync;
--  symbol_synchro_int_gbl <= symbol_synchro_int;
--  dc_offset_i_gbl <= dc_offset_i;
--  dc_offset_q_gbl <= dc_offset_q;
--  d_signed_peak_i_gbl <= d_signed_peak_i;
--  d_signed_peak_q_gbl <= d_signed_peak_q;
--  correl_rst_n_gbl <= correl_rst_n;
--  equalizer_data_out_i_gbl <= equalizer_data_out_i;
--  equalizer_data_out_q_gbl <= equalizer_data_out_q;
--  a_data_i_gbl <= a_data_i;
--  a_data_q_gbl <= a_data_q;
--  remod_data_i_gbl <= remod_data_i;
--  remod_data_q_gbl <= remod_data_q;
--  mu_int_gbl <= mu_int;
--  rho_int_gbl <= rho_int;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on 

end rtl;
