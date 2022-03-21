

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of postprocessing is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal yb                  : std_logic_vector (xb_size_g-1 downto 0); -- B corr magnitude
  signal peak_position       : std_logic_vector (3 downto 0);
  signal f_position          : std_logic; --  high every 16 xb
  signal cp2_detected        : std_logic; -- high when max_decision has found the CP2
  signal enable_peak_search  : std_logic;
  -- XP Buffer
  signal xp_valid            : std_logic;
  signal xp_buf0             : std_logic_vector (xb_size_g+2 downto 0);
  signal xp_buf1             : std_logic_vector (xb_size_g+2 downto 0);
  signal xp_buf2             : std_logic_vector (xb_size_g+2 downto 0);
  signal xp_buf3             : std_logic_vector (xb_size_g+2 downto 0);
  signal nb_xp_to_take       : std_logic;
  -- Coarse Freq Sync
  signal expected_peak       : std_logic; -- indicate when XB should be a peak (last index)
  signal current_peak        : std_logic; -- indicate when XB is be a peak (current index)
  signal su                  : std_logic_vector(xb_size_g+6 downto 0);  -- offset freq estimation
  signal not_su_short        : std_logic_vector(xb_size_g+6 downto 0);  -- offset freq estimation

--------------------------------------------------------------------------------
-- Architecture Bodywill_be_next_peak
--------------------------------------------------------------------------------
begin

  -- stop search when cp2 is detected
  enable_peak_search <= not cp2_detected;
  -----------------------------------------------------------------------------
  -- B Correlator Magnitude
  -----------------------------------------------------------------------------
  magnitude_gen_b: magnitude_gen
    generic map (
      size_in_g =>   xb_size_g)
    port map (
      data_in_i => xb_re_i,
      data_in_q => xb_im_i,
      mag_out   => yb);
  
  -----------------------------------------------------------------------------
  -- Peak Search
  -----------------------------------------------------------------------------
  peak_search_1 : peak_search
    generic map (
      yb_size_g => xb_size_g,
      yb_max_g  => 4)
    port map (
      clk                   => clk,
      reset_n               => reset_n,
      init_i                => init_i,
      enable_peak_search_i  => enable_peak_search,
      yb_data_valid_i       => xb_data_valid_i,
      yb_i                  => yb,
      yb_counter_i          => wr_ptr_i,
      peak_position_o       => peak_position,
      f_position_o          => f_position,
      expected_peak_o       => expected_peak,
      current_peak_o        => current_peak);

  -----------------------------------------------------------------------------
  -- Phase Computation
  -----------------------------------------------------------------------------
     
  phase_computation_1: phase_computation
    generic map (
      xb_size_g      => xb_size_g)
    port map (
      clk              => clk,
      reset_n          => reset_n,
      init_i           => init_i,
      peak_position_i  => peak_position,
      f_position_i     => f_position,
      mem_wr_ptr_i     => wr_ptr_i,
      mem_wr_enable_i  => mem_wr_enable_i,
      xb_from_mem_re_i => xb_from_mem_re_i,
      xb_from_mem_im_i => xb_from_mem_im_i,
      cp2_detected_i   => cp2_detected,
      xc1_data_valid_i => current_peak,
      xc1_re_i         => xc1_re_i,
      xc1_im_i         => xc1_im_i,
      xp_valid_o       => xp_valid,
      xp_buf0_o        => xp_buf0,
      xp_buf1_o        => xp_buf1,
      xp_buf2_o        => xp_buf2,
      xp_buf3_o        => xp_buf3,
      nb_xp_to_take_o  => nb_xp_to_take,
      read_enable_o    => read_enable_o,
      mem_rd_ptr_o     => rd_ptr1_o);

  -----------------------------------------------------------------------------
  -- Coarse Freq Sync 
  -----------------------------------------------------------------------------
  coarse_freq_sync_1: coarse_freq_sync
    generic map (
      xp_size_g => xb_size_g+3)
    port map (
      clk                 => clk,
      reset_n             => reset_n,
      init_i              => init_i,
      xp_valid_i          => xp_valid,
      xp_buf0_i           => xp_buf0,
      xp_buf1_i           => xp_buf1,
      xp_buf2_i           => xp_buf2,
      xp_buf3_i           => xp_buf3,
      nb_xp_to_take_i     => nb_xp_to_take,
      su_o                => su,
      su_data_valid_o     => cf_inc_data_valid_o);


 -- No MSB bit is added, as the max should not be reached (and if it is, the freq
 -- domain will not be able to lead such offset).

 -- cf_inc_shr <= signed(not(cf_inc)) + 5;

  not_su_short   <= -signed(su);
    
  cf_inc_o <= not_su_short & "0000000";

                    
  max_decision_1 : max_decision
    generic map (
      yb_size_g => xb_size_g)
    port map (
      clk                  => clk,
      reset_n              => reset_n,
      init_i               => init_i,
      f_position_i         => f_position,
      current_peak_i         => current_peak,
      expected_peak_i      => expected_peak,
      yb_data_valid_i      => xb_data_valid_i,
      yb_i                 => yb,
      yc1_i                => yc1_i,
      yc2_i                => yc2_i,
      cp2_detected_o       => cp2_detected,
      cp2_detected_pulse_o => preamb_detect_o);

  cp2_detected_o <= cp2_detected;

  -- Internal signal for debug
  generate_peak_param_p : process(clk, reset_n)
  begin
    if reset_n = '0' then
      peak_position_o <= (others => '0');
    elsif clk'event and clk = '1' then
      -- Keep peak position parameter value after each packet
      if expected_peak = '1' then
        peak_position_o <= peak_position;
      end if;
    end if;
  end process generate_peak_param_p;
  
  -- truncature of the 4 LSB + saturation of 2 MSB
  debug_p : process(yb)
  begin
    if yb(9 downto 8) /= "00"  then
      -- need to saturate
      yb_o <= (others => '1'); -- max value
    else
      -- no need to saturate
      yb_o <= yb(7 downto 4);
    end if;
  end process debug_p;
  

end RTL;
