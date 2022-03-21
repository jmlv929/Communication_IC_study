
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of freq_domain is

  type INVERTER_STATE_T is (idle_state, invert_state);
  
  signal zero_vector      : std_logic_vector(63 downto 0);
  signal one_vector       : std_logic_vector(15 downto 0);

  signal data_ready_o_s           : std_logic;
  
  -------------------------------------------------------------------------------
  -- from preamble demux
  -------------------------------------------------------------------------------
  signal data_ready_predmx             : std_logic;
  -- output of preamble demux after shifting :
  signal i_predmx                      : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_predmx                      : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  -- output of preamble demux before shifting :
  signal i_predmx2                     : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_predmx2                     : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  -- output of preamble demux after saturation
  signal i_predmx_presat               : std_logic_vector(FFT_WIDTH_CT+1 downto 0);
  signal q_predmx_presat               : std_logic_vector(FFT_WIDTH_CT+1 downto 0);
  --
  signal data_valid_predmx             : std_logic;
  signal start_of_burst_predmx         : std_logic;
  signal start_of_symbol_predmx        : std_logic; 
  signal wie_data_valid_predmx         : std_logic;
  signal wie_start_of_burst_predmx     : std_logic;
  signal wie_start_of_symbol_predmx    : std_logic;
  signal pilot_valid                   : std_logic;
  -------------------------------------------------------------------------------
  -- from wiener filter
  -------------------------------------------------------------------------------
  signal data_ready_wie            : std_logic;
  signal i_wie                     : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_wie                     : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal data_valid_wie            : std_logic;
  signal start_of_burst_wie        : std_logic;
  signal start_of_symbol_wie       : std_logic;
  signal wie_coeff_data_valid      : std_logic;
  signal wie_coeff_data_ready      : std_logic;
  signal wie_coeff_rd_ptr          : std_logic_vector(5 downto 0);
  signal wie_coeff_wr_ptr          : std_logic_vector(5 downto 0);
  signal wie_coeff_wr_ptr_enable   : std_logic;
  signal i_wie_coeff_table         : WIE_COEFF_ARRAY_T;
  signal q_wie_coeff_table         : WIE_COEFF_ARRAY_T;
  signal i_wie_coeff               : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_wie_coeff               : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal start_of_symbol_wie_or_eq : std_logic;
  --------------------------------------------
  -- For pilot tracking
  --------------------------------------------
  signal start_of_symbol_plt_track    : std_logic;
  -- pilots
  signal pilot_p21_i_i           : std_logic_vector(11 downto 0);
  signal pilot_p21_q_i           : std_logic_vector(11 downto 0);
  signal pilot_p7_i_i            : std_logic_vector(11 downto 0);
  signal pilot_p7_q_i            : std_logic_vector(11 downto 0);
  signal pilot_m21_i_i           : std_logic_vector(11 downto 0);
  signal pilot_m21_q_i           : std_logic_vector(11 downto 0);
  signal pilot_m7_i_i            : std_logic_vector(11 downto 0);
  signal pilot_m7_q_i            : std_logic_vector(11 downto 0);
  -- channel response for the pilot subcarriers
  signal ch_m21_coef_i_i         : std_logic_vector(11 downto 0);
  signal ch_m21_coef_q_i         : std_logic_vector(11 downto 0);
  signal ch_m7_coef_i_i          : std_logic_vector(11 downto 0);
  signal ch_m7_coef_q_i          : std_logic_vector(11 downto 0);
  signal ch_p7_coef_i_i          : std_logic_vector(11 downto 0);
  signal ch_p7_coef_q_i          : std_logic_vector(11 downto 0);
  signal ch_p21_coef_i_i         : std_logic_vector(11 downto 0);
  signal ch_p21_coef_q_i         : std_logic_vector(11 downto 0);
  -- equalizer coefficients 1/(channel response)
  signal eq_p21_i_i              : std_logic_vector(11 downto 0);
  signal eq_p21_q_i              : std_logic_vector(11 downto 0);
  signal eq_p7_i_i               : std_logic_vector(11 downto 0);
  signal eq_p7_q_i               : std_logic_vector(11 downto 0);
  signal eq_m21_i_i              : std_logic_vector(11 downto 0);
  signal eq_m21_q_i              : std_logic_vector(11 downto 0);
  signal eq_m7_i_i               : std_logic_vector(11 downto 0);
  signal eq_m7_q_i               : std_logic_vector(11 downto 0);
  signal pilot_coeffs_valid      : std_logic;                      
  signal estimate_done_o         : std_logic;                      
  signal sto_o                   : std_logic_vector(16 downto 0);  
  signal cpe_o                   : std_logic_vector(16 downto 0);  
  signal inv_matrix_done         : std_logic;
  --------------------------------------------
  -- Phase ramp rotator
  --------------------------------------------
  signal start_of_burst_ramp      : std_logic;
  signal start_of_symbol_ramp     : std_logic;
  signal data_ready_ramp          : std_logic;
  signal data_valid_ramp          : std_logic;
  signal i_ramp                   : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_ramp                   : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  -------------------------------------------------------------------------------
  -- from equalizer
  -------------------------------------------------------------------------------
  signal data_ready_equ          : std_logic;
  signal chtrack_data_ready_equ  : std_logic;
  signal soft_x0_equ             : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_x1_equ             : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_x2_equ             : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y0_equ             : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y1_equ             : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y2_equ             : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0); 
  signal data_valid_equ          : std_logic;
  signal start_of_burst_equ      : std_logic;
  signal start_of_symbol_equ     : std_logic;
  -------------------------------------------------------------------------------
  -- from channel decoder
  -------------------------------------------------------------------------------
  signal data_ready_chdec                   : std_logic;
  signal data_valid_chdec                   : std_logic;
  signal data_chdec                         : std_logic;
  signal signal_field_chdec                 : std_logic_vector (SIGNAL_FIELD_LENGTH_CT-1 downto 0);
  signal signal_field_valid_chdec           : std_logic;           
  signal start_of_burst_chdec               : std_logic;
  -------------------------------------------------------------------------------
  -- from descrambler
  -------------------------------------------------------------------------------
  signal data_ready_descr                   : std_logic;

  -------------------------------------------------------------------------------
  -- signals from service field (qam, burst rate, burst length)
  -------------------------------------------------------------------------------
  signal qam_mode_int        : std_logic_vector(1 downto 0); --to be modified: when the package is update: use the definition above
  signal burst_rate_int      : std_logic_vector(3 downto 0); --to be modified: when the package is update: use the definition above
  signal burst_length_int    : std_logic_vector(11 downto 0); --to be modified: when the package is update: use the definition above
  signal burst_res_bit_int   : std_logic;

  -------------------------------------------------------------------------------
  -- diag port
  -------------------------------------------------------------------------------
  signal signal_field_parity_error          : std_logic;
  signal signal_field_unsupported_rate      : std_logic;
  signal signal_field_unsupported_length    : std_logic;
  signal descr_data_o                       : std_logic;

begin
  
  zero_vector       <= (others => '0');
  one_vector        <= (others => '1');
  
  -------------------------------------------------------------------------------
  -- signals from service field (qam, burst rate, burst length)
  -------------------------------------------------------------------------------
  qam_mode_int      <= signal_field_chdec(signal_field_chdec'low + 1 downto signal_field_chdec'low);

  burst_rate_int	  <= signal_field_chdec(signal_field_chdec'low + 3 downto signal_field_chdec'low);
  burst_length_int	<= signal_field_chdec(signal_field_chdec'high -1  downto signal_field_chdec'high - 12);
  burst_res_bit_int	<= signal_field_chdec(signal_field_chdec'low + 4);

  data_ready_o      <= data_ready_o_s;
  
  
  --------------------------------------------
  -- Preamble demux
  --------------------------------------------
  rx_predmx_1 : rx_predmx
    port map (
      clk                          => clk,                             
      reset_n                      => reset_n,        
      sync_reset_n                 => sync_reset_n,    
      i_i                          => i_i,    
      q_i                          => q_i,   
      data_valid_i                 => data_valid_i,
      wie_data_ready_i             => data_ready_wie,
      equ_data_ready_i             => data_ready_ramp,
      start_of_burst_i             => start_of_burst_i,
      start_of_symbol_i            => start_of_symbol_i,
      data_ready_o                 => data_ready_o_s,
      i_o                          => i_predmx2,
      q_o                          => q_predmx2,
      wie_data_valid_o             => wie_data_valid_predmx,
      equ_data_valid_o             => data_valid_predmx,
      pilot_valid_o                => pilot_valid,
      inv_matrix_done_i            => inv_matrix_done,
      wie_start_of_burst_o         => wie_start_of_burst_predmx,
      wie_start_of_symbol_o        => wie_start_of_symbol_predmx,  
      equ_start_of_burst_o         => start_of_burst_predmx,
      equ_start_of_symbol_o        => start_of_symbol_predmx,
      plt_track_start_of_symbol_o  => start_of_symbol_plt_track
      );

  i_predmx_presat <= i_predmx2 & "00";
  q_predmx_presat <= q_predmx2 & "00";
  i_predmx        <= sat_signed_slv(i_predmx_presat, 2);
  q_predmx        <= sat_signed_slv(q_predmx_presat, 2);

  start_of_symbol_wie_or_eq <= wie_start_of_symbol_predmx or 
                               start_of_symbol_ramp;
                               
  --------------------------------------------
  -- Wiener filter
  --------------------------------------------
  wiener_1: wiener_filter
    port map (
      clk               => clk,
      reset_n           => reset_n,
      sync_reset_n      => sync_reset_n,
      wf_window_i       => wf_window_i,
      i_i               => i_predmx,
      q_i               => q_predmx,
      data_valid_i      => wie_data_valid_predmx,
      data_ready_o      => data_ready_wie,
      start_of_burst_i  => wie_start_of_burst_predmx,
      start_of_symbol_i => wie_start_of_symbol_predmx,
      data_ready_i      => one_vector(0),
      i_o               => i_wie,
      q_o               => q_wie,
      data_valid_o      => data_valid_wie,
      start_of_symbol_o => start_of_symbol_wie,
      start_of_burst_o  => start_of_burst_wie
      );

  --------------------------------------------
  -- Wiener coeffs memory
  --------------------------------------------
  wie_mem_1 : wie_mem
    port map (
      clk               => clk,
      reset_n           => reset_n,
      sync_reset_n      => sync_reset_n,
      i_i               => i_wie,
      q_i               => q_wie,
      data_valid_i      => data_valid_wie,
      data_ready_i      => wie_coeff_data_ready,
      start_of_burst_i  => wie_start_of_burst_predmx,
      --
      start_of_symbol_i => start_of_symbol_wie_or_eq,
      --                 
      i_o               => i_wie_coeff,
      q_o               => q_wie_coeff,
      data_ready_o      => open,
      data_valid_o      => wie_coeff_data_valid,
      start_of_burst_o  => open,
      --
      start_of_symbol_o => open,
      -- pilots coeffs
      pilot_ready_o     => pilot_coeffs_valid,
      eq_p21_i_o        => ch_p21_coef_i_i,
      eq_p21_q_o        => ch_p21_coef_q_i,
      eq_p7_i_o         => ch_p7_coef_i_i,
      eq_p7_q_o         => ch_p7_coef_q_i,
      eq_m21_i_o        => ch_m21_coef_i_i,
      eq_m21_q_o        => ch_m21_coef_q_i,
      eq_m7_i_o         => ch_m7_coef_i_i,
      eq_m7_q_o         => ch_m7_coef_q_i
      );

      
  -- pilots assignment
  pilot_p21_i_i           <= i_i(21)(FFT_WIDTH_CT-3 downto 0) & "00";
  pilot_p21_q_i           <= q_i(21)(FFT_WIDTH_CT-3 downto 0) & "00";
  pilot_p7_i_i            <= i_i( 7)(FFT_WIDTH_CT-3 downto 0) & "00";
  pilot_p7_q_i            <= q_i( 7)(FFT_WIDTH_CT-3 downto 0) & "00";
  pilot_m21_i_i           <= i_i(43)(FFT_WIDTH_CT-3 downto 0) & "00";
  pilot_m21_q_i           <= q_i(43)(FFT_WIDTH_CT-3 downto 0) & "00";
  pilot_m7_i_i            <= i_i(57)(FFT_WIDTH_CT-3 downto 0) & "00";
  pilot_m7_q_i            <= q_i(57)(FFT_WIDTH_CT-3 downto 0) & "00";

    
  ------------------------------------------------------------------------------
  -- Pilot tracking
  ------------------------------------------------------------------------------
  pilot_tracking_1 : pilot_tracking
    port map (
      clk                     => clk,
      reset_n                 => reset_n,
      sync_reset_n            => sync_reset_n,
      start_of_burst_i        => start_of_burst_i,
      start_of_symbol_i       => start_of_symbol_plt_track,
      ch_valid_i              => pilot_coeffs_valid,
      -- pilots
      pilot_p21_i_i           => pilot_p21_i_i,
      pilot_p21_q_i           => pilot_p21_q_i,
      pilot_p7_i_i            => pilot_p7_i_i,
      pilot_p7_q_i            => pilot_p7_q_i,
      pilot_m21_i_i           => pilot_m21_i_i,
      pilot_m21_q_i           => pilot_m21_q_i,
      pilot_m7_i_i            => pilot_m7_i_i,
      pilot_m7_q_i            => pilot_m7_q_i,
      -- channel response for the pilot subcarriers
      ch_m21_coef_i_i         => ch_m21_coef_i_i,
      ch_m21_coef_q_i         => ch_m21_coef_q_i,
      ch_m7_coef_i_i          => ch_m7_coef_i_i,
      ch_m7_coef_q_i          => ch_m7_coef_q_i,
      ch_p7_coef_i_i          => ch_p7_coef_i_i,
      ch_p7_coef_q_i          => ch_p7_coef_q_i,
      ch_p21_coef_i_i         => ch_p21_coef_i_i,
      ch_p21_coef_q_i         => ch_p21_coef_q_i,
      -- equalizer coefficients 1/(channel response)
      eq_p21_i_i              => eq_p21_i_i,
      eq_p21_q_i              => eq_p21_q_i,
      eq_p7_i_i               => eq_p7_i_i,
      eq_p7_q_i               => eq_p7_q_i,
      eq_m21_i_i              => eq_m21_i_i,
      eq_m21_q_i              => eq_m21_q_i,
      eq_m7_i_i               => eq_m7_i_i,
      eq_m7_q_i               => eq_m7_q_i,
      skip_cpe_o              => open,
      estimate_done_o         => estimate_done_o,
      sto_o                   => sto_o,
      cpe_o                   => cpe_o,
      --
      inv_matrix_done_dbg     => inv_matrix_done
      );

  eq_p21_i_i     <= (others => '0');
  eq_p21_q_i     <= (others => '0');
  eq_p7_i_i      <= (others => '0');
  eq_p7_q_i      <= (others => '0');
  eq_m21_i_i     <= (others => '0');
  eq_m21_q_i     <= (others => '0');
  eq_m7_i_i      <= (others => '0');
  eq_m7_q_i      <= (others => '0');

  
  --------------------------------------------
  -- Phase ramp rotator 
  --------------------------------------------
  ramp_phase_rot_1 : ramp_phase_rot  
    port map (
      clk                 => clk,
      reset_n             => reset_n,
      sync_reset_n        => sync_reset_n,
      --
      data_i_i            => i_predmx,
      data_q_i            => q_predmx,
      start_of_burst_i    => start_of_burst_predmx,
      start_of_symbol_i   => start_of_symbol_predmx, 
      data_valid_i        => data_valid_predmx,
      pilot_valid_i       => pilot_valid,
      data_ready_o        => data_ready_ramp,
      data_i_o            => i_ramp,
      data_q_o            => q_ramp,
      start_of_burst_o    => start_of_burst_ramp,
      start_of_symbol_o   => start_of_symbol_ramp,
      data_valid_o        => data_valid_ramp,
      data_ready_i        => data_ready_equ,
      cpe_i               => cpe_o,
      sto_i               => sto_o,
      estimate_done_i     => estimate_done_o,
      signal_valid_i      => signal_field_valid_chdec
      );


  --------------------------------------------
  -- Equalizer
  --------------------------------------------
  rx_equ_1 : rx_equ  
    port map (
      clk                       => clk,
      reset_n                   => reset_n,
      sync_reset_n              => sync_reset_n,
      --
      i_i                       => i_ramp,
      q_i                       => q_ramp,
      data_valid_i              => data_valid_ramp,
      data_ready_o              => data_ready_equ,
      ich_i                     => i_wie_coeff,
      qch_i                     => q_wie_coeff,
      data_valid_ch_i           => wie_coeff_data_valid,
      data_ready_ch_o           => wie_coeff_data_ready,
      soft_x0_o                 => soft_x0_equ,
      soft_x1_o                 => soft_x1_equ,
      soft_x2_o                 => soft_x2_equ,
      soft_y0_o                 => soft_y0_equ,
      soft_y1_o                 => soft_y1_equ,
      soft_y2_o                 => soft_y2_equ,
      burst_rate_i              => burst_rate_int,
      signal_field_valid_i      => signal_field_valid_chdec,
      data_valid_o              => data_valid_equ,
      data_ready_i              => data_ready_chdec,
      start_of_burst_i          => wie_start_of_burst_predmx,
      start_of_symbol_i         => start_of_symbol_ramp, 
      start_of_burst_o          => start_of_burst_equ,
      start_of_symbol_o         => start_of_symbol_equ,
      --
      histoffset_54_i           => histoffset_54_i,
      histoffset_48_i           => histoffset_48_i,
      histoffset_36_i           => histoffset_36_i,
      histoffset_24_i           => histoffset_24_i,
      histoffset_18_i           => histoffset_18_i,
      histoffset_12_i           => histoffset_12_i,
      histoffset_09_i           => histoffset_09_i,
      histoffset_06_i           => histoffset_06_i,
      --
      satmaxncarr_54_i          => satmaxncarr_54_i,
      satmaxncarr_48_i          => satmaxncarr_48_i,
      satmaxncarr_36_i          => satmaxncarr_36_i,
      satmaxncarr_24_i          => satmaxncarr_24_i,
      satmaxncarr_18_i          => satmaxncarr_18_i,
      satmaxncarr_12_i          => satmaxncarr_12_i,
      satmaxncarr_09_i          => satmaxncarr_09_i,
      satmaxncarr_06_i          => satmaxncarr_06_i,
      --
      reducerasures_i           => reducerasures_i
      );


  --------------------------------------------
  -- Channel decoder
  --------------------------------------------
  channel_decoder_1 : channel_decoder
    port map (
      -- Clock & Reset Interface
      reset_n                         => reset_n,
      clk                             => clk,
      sync_reset_n                    => sync_reset_n,
      -- Interface Synchronization
      data_valid_i                    => data_valid_equ,
      data_ready_o                    => data_ready_chdec,
      --
      data_valid_o                    => data_valid_chdec,
      data_ready_i                    => data_ready_descr,
      -- Datapath interface
      soft_x0_i                       => soft_x0_equ,
      soft_x1_i                       => soft_x1_equ,
      soft_x2_i                       => soft_x2_equ,
      soft_y0_i                       => soft_y0_equ,
      soft_y1_i                       => soft_y1_equ,
      soft_y2_i                       => soft_y2_equ,
      --
      data_o                          => data_chdec,
      -- Register
      length_limit_i                  => length_limit_i,
      rx_length_chk_en_i              => rx_length_chk_en_i,
      -- Control info interface
      signal_field_o                    => signal_field_chdec,
      signal_field_parity_error_o       => signal_field_parity_error,
      signal_field_unsupported_rate_o   => signal_field_unsupported_rate,
      signal_field_unsupported_length_o => signal_field_unsupported_length,
      signal_field_puncturing_mode_o    => open,
      signal_field_valid_o              => signal_field_valid_chdec,
      --
      start_of_burst_i                => start_of_burst_equ,
      start_of_burst_o                => start_of_burst_chdec,
      --
      end_of_data_o                   => end_of_data_o,
      -- Debugging Ports
      soft_x_deintpun_o               => open,
      soft_y_deintpun_o               => open,
      data_valid_deintpun_o           => open
      );

  signal_field_o                    <= signal_field_chdec;
  signal_field_valid_o              <= signal_field_valid_chdec;
  signal_field_parity_error_o       <= signal_field_parity_error;
  signal_field_unsupported_rate_o   <= signal_field_unsupported_rate;
  signal_field_unsupported_length_o <= signal_field_unsupported_length;


  --------------------------------------------
  -- Descrambling
  --------------------------------------------
  rx_descr_1 : rx_descr
    port map (
      clk                      => clk,
      reset_n                  => reset_n,
      sync_reset_n             => sync_reset_n,
      data_i                   => data_chdec,
      data_valid_i             => data_valid_chdec,
      data_ready_i             => data_ready_i,
      start_of_burst_i         => start_of_burst_chdec,
      --
      data_ready_o             => data_ready_descr,
      data_o                   => descr_data_o,
      data_valid_o             => data_valid_o,
      rxv_service_o            => rxv_service_o,
      rxv_service_ind_o        => rxv_service_ind_o,
      start_of_burst_o         => start_of_burst_o 
      );

  data_o <= descr_data_o;


  ---------------------------------------
  -- Diag. port
  ---------------------------------------
  freq_domain_diag <= signal_field_parity_error &
                      signal_field_unsupported_rate &
                      signal_field_unsupported_length &
                      signal_field_valid_chdec &
                      data_chdec &
                      data_valid_chdec &
                      descr_data_o;


end rtl;
