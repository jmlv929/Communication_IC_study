
--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of init_sync is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- XC1
  signal xc1_re         : std_logic_vector (size_n_g-size_rem_corr_g+5-1-2 downto 0);
  signal xc1_im         : std_logic_vector (size_n_g-size_rem_corr_g+5-1-2 downto 0);
  --XB
  signal xb_re          : std_logic_vector (size_n_g-size_rem_corr_g+5-1-2 downto 0);
  signal xb_im          : std_logic_vector (size_n_g-size_rem_corr_g+5-1-2 downto 0);
  signal xb_data_valid  : std_logic;
  -- write access
  signal wr_ptr         : std_logic_vector(6 downto 0);
  signal write_enable   : std_logic;
  -- YR
  signal yr             : std_logic_vector (9 downto 0);
  signal yr_data_valid  : std_logic;
  -- AT
  signal at1            : std_logic_vector (13 downto 0); --NEW (ver 1.9). Was (12 downto 0)
  signal at0            : std_logic_vector (13 downto 0); --NEW (ver 1.9). Was (12 downto 0)
  --A16M
  signal a16_m          : std_logic_vector (13 downto 0); --NEW (ver 1.9). Was (12 downto 0)
  signal a16_data_valid : std_logic;
  -- YC1 - YC2
  signal yc1            : std_logic_vector (size_n_g-size_rem_corr_g+5-2-1 downto 0);
  signal yc2            : std_logic_vector (size_n_g-size_rem_corr_g+5-2-1 downto 0);
  -- Control Signals
  signal init           : std_logic;
  signal init_preproc   : std_logic;

  signal calc_cp       : std_logic;
  signal cp2_detected  : std_logic;
  signal preamb_detect : std_logic;

  signal dc_offset_4_corr_i   : std_logic_vector (11 downto 0); --NEW (ver 1.9)
  signal dc_offset_4_corr_q   : std_logic_vector (11 downto 0); --NEW (ver 1.9)
  
  signal detthr_reg_int       : std_logic_vector(5 downto 0);  --NEW (ver 1.10)
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  init         <= not sync_res_n;
  init_preproc <= not sync_res_n or cp2_detected; -- no need to continue when
                                                   -- cp2 detected

  -----------------------------------------------------------------------------
  -- Preprocessing Instantiation
  -----------------------------------------------------------------------------
  preprocessing_1 : preprocessing
  generic map(
    size_n_g                  => size_n_g,
    size_rem_corr_g           => size_rem_corr_g,-- nb of bits removed for correlation calc
--    use_3correlators_g        => 1,
    use_3correlators_g        => 1,
--    use_autocorrelators_g     => 0)
    use_autocorrelators_g     => 0)
    
    port map(
      clk                  => clk,
      reset_n              => reset_n,
      init_i               => init_preproc,
      -- interface with dezfilter
      i_i                  => i_i,
      q_i                  => q_i,
      data_valid_i         => data_valid_i,
      dc_offset_4_corr_i_i => dc_offset_4_corr_i, -- NEW (rev 1.9)
      dc_offset_4_corr_q_i => dc_offset_4_corr_q, -- NEW (rev 1.9)     
      autocorr_enable_i    => autocorr_enable_i,
      -- autocorrelation threshold 
      autothr0_i           => autothr0_i,
      autothr1_i           => autothr1_i,
      -- interface with Mem (write port + control)
      mem_o                => mem_o,
      wr_ptr_o             => wr_ptr,
      write_enable_o       => write_enable,
      -- XB (from CP1-correlator)
      xb_re_o              => xb_re,
      xb_im_o              => xb_im,
      xb_data_valid_o      => xb_data_valid,
      -- XC1 (from CP1-correlator)
      xc1_re_o             => xc1_re,
      xc1_im_o             => xc1_im,
      -- Y threshold 
      at0_o                => at0,
      at1_o                => at1,
      -- Y data (from CP1/CP2-correlator)
      yc1_o                => yc1,
      yc2_o                => yc2,
      -- Auto-correlation outputs
      a16_m_o              => a16_m,
      a16_data_valid_o     => a16_data_valid,
      -- Stat register
      ybnb_o               => ybnb_o
      );

  dc_offset_4_corr_i   <=(others=>'0');-- NEW (rev 1.9)
  dc_offset_4_corr_q   <=(others=>'0');-- NEW (rev 1.9)

  -----------------------------------------------------------------------------
  -- Postprocessing Instantiation
  -----------------------------------------------------------------------------

  postprocessing_1 : postprocessing
  generic map (
    xb_size_g => (size_n_g-size_rem_corr_g + 3))
  port map(
    -- ofdm clock (80 MHz)
    clk                 => clk,
    -- asynchronous negative reset
    reset_n             => reset_n,
    -- synchronous negative reset
    init_i              => init,
    xb_data_valid_i     => xb_data_valid,
    xb_re_i             => xb_re,
    xb_im_i             => xb_im,
    xc1_re_i            => xc1_re,
    xc1_im_i            => xc1_im,
    yc1_i               => yc1,
    yc2_i               => yc2,
    -- Memory Interface
    xb_from_mem_re_i    => mem1_i (2*(size_n_g-size_rem_corr_g + 3)-1 downto size_n_g-size_rem_corr_g + 3),
    xb_from_mem_im_i    => mem1_i (size_n_g-size_rem_corr_g + 3-1 downto 0),
    wr_ptr_i            => wr_ptr,
    mem_wr_enable_i     => write_enable,
    rd_ptr1_o           => rd_ptr1_o,
    read_enable_o       => read_enable_o,
    -- coarse frequency correction increment
    cf_inc_o            => cf_inc_o,
    cf_inc_data_valid_o => cf_inc_data_valid_o,
    -- Preamble Detected
    cp2_detected_o      => cp2_detected,
    preamb_detect_o     => preamb_detect,
    -- Internal signal for debug
    yb_o                => yb_o,
    peak_position_o     => open
    );

  -----------------------------------------------------------------------------
  -- Shift Parameter Instantiation
  -----------------------------------------------------------------------------
  shift_param_gen_1: shift_param_gen
    generic map (
      data_size_g => 11)
    port map (
      clk            => clk,
      reset_n        => reset_n,
      --
      init_i         => init_preproc,
      cp2_detected_i => preamb_detect,
      i_i            => i_i,
      q_i            => q_i,
      data_valid_i   => data_valid_i,
      --
      shift_param_o  => shift_param_o);

  -----------------------------------------------------------------------------
  -- Carrier Sense Detection Instantiation
  -----------------------------------------------------------------------------
  -- * detthr_reg_i INPUT of carrier_detect  is now 6 bits (requirement of
  --   modem g AGC procedure).
  --   !! TBC confirm for modem a2 !!
  --
  -- * cs_accu_en INPUT is a requirement of modem g AGC procedure.
  
  detthr_reg_int <= "00"&detthr_reg_i;
  
  carrier_detect_1: carrier_detect
    generic map (
      data_size_g => 14)-- NEW (ver 1.9). Was 13
    port map (
      clk                 => clk,
      reset_n             => reset_n,
      init_i              => init_preproc,
      autocorr_enable_i   => autocorr_enable_i,
      a16m_data_valid_i   => a16_data_valid,
      cs_accu_en          => autocorr_enable_i,
      at0_i               => at0,
      at1_i               => at1,
      a16m_i              => a16_m,
      detthr_reg_i        => detthr_reg_int,
      fast_carrier_s_o    => fast_carrier_s_o,
      fast_99carrier_s_o  => open,-- Signal used for 11g AGC procedure      
      carrier_s_o         => carrier_s_o);
    

  -----------------------------------------------------------------------------
  -- Output Linking
  -----------------------------------------------------------------------------
  wr_ptr_o            <= wr_ptr;
  write_enable_o      <= write_enable;
  preamb_detect_o     <= preamb_detect;
  cp2_detected_o      <= cp2_detected;

end RTL;
