

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of rx_equ_instage0 is

  signal z_re_int    : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal z_im_int    : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal h_re_int    : std_logic_vector(CHMEM_WIDTH_CT-1 downto 0);
  signal h_im_int    : std_logic_vector(CHMEM_WIDTH_CT-1 downto 0);
  signal cormani_int : std_logic_vector(CORMAN_PROD_WIDTH_CT-1 downto 0);

begin

  -- if mode= bpsk only softx0 is different from 0, 
  -- then cormani doesn't make sense
  cormani_o <= (others => '0') when 
    burst_rate_i(QAM_LEFT_BOUND_CT downto QAM_RIGHT_BOUND_CT) = BPSK_CT
  else cormani_int;

  ctr_1 : rx_equ_instage0_ctr 
  port map (
    clk                => clk,
    reset_n            => reset_n,
    module_enable_i    => module_enable_i,
    sync_reset_n       => sync_reset_n,
    pipeline_en_i      => pipeline_en_i,
    cumhist_en_i       => cumhist_en_i,
    current_symb_i     => current_symb_i,
    i_i                => i_i,
    q_i                => q_i,
    i_saved_i          => i_saved_i,
    q_saved_i          => q_saved_i,
    ich_i              => ich_i,
    qch_i              => qch_i,
    ich_saved_i        => ich_saved_i,
    qch_saved_i        => qch_saved_i,
    ctr_input_i        => ctr_input_i,
    burst_rate_i       => burst_rate_i,

    z_re_o             => z_re_int,
    z_im_o             => z_im_int,
    h_re_o             => h_re_int,
    h_im_o             => h_im_int,

    burst_rate_o       => burst_rate_o,
    cumhist_valid_o    => cumhist_valid_o,
    current_symb_o     => current_symb_o,
    data_valid_o       => data_valid_o
  );

  -- real part
  cormanr_1 : rx_equ_instage0_corman 
  generic map (complex_part_g => 0)
  port map (
    clk               => clk,
    reset_n           => reset_n,
    module_enable_i   => module_enable_i,
    pipeline_en_i     => pipeline_en_i,

    z_re_i            => z_re_int,
    z_im_i            => z_im_int,
    h_re_i            => h_re_int,
    h_im_i            => h_im_int,

    corman_o          => cormanr_o
  );

  -- imaginary part
  cormani_1 : rx_equ_instage0_corman 
  generic map (complex_part_g => 1)
  port map (
    clk               => clk,
    reset_n           => reset_n,
    module_enable_i   => module_enable_i,
    pipeline_en_i     => pipeline_en_i,

    z_re_i            => z_re_int,
    z_im_i            => z_im_int,
    h_re_i            => h_re_int,
    h_im_i            => h_im_int,

    corman_o          => cormani_int
  );


  hpowman_1 : rx_equ_instage0_hpowman 
  port map (
    clk               => clk,
    reset_n           => reset_n,
    module_enable_i   => module_enable_i,
    pipeline_en_i     => pipeline_en_i,
    cumhist_en_i      => cumhist_en_i,

    h_re_i            => h_re_int,
    h_im_i            => h_im_int,

    hpowman_o         => hpowman_o
  );

end rtl;
