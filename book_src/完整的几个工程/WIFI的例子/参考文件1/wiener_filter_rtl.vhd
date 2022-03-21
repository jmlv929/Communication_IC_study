
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of wiener_filter is

  signal chanwien_a    : std_logic_vector(WIENER_ADDR_WIDTH_CT-1 downto 0);
  signal chanwien_do   : std_logic_vector((4*WIENER_COEFF_WIDTH_CT)-1 downto 0);
  signal chanwien_cs_n : std_logic;
  signal module_enable : std_logic;
  signal i_data1       : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_data1       : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal i_data2       : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_data2       : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal i_data3       : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_data3       : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal i_data4       : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal q_data4       : std_logic_vector(FFT_WIDTH_CT-1 downto 0);
  signal chanwien_c0   : std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
  signal chanwien_c1   : std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
  signal chanwien_c2   : std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
  signal chanwien_c3   : std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
  signal en_add_reg    : std_logic;
  signal i_add1        : std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0);
  signal q_add1        : std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0);
  signal i_add2        : std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0);
  signal q_add2        : std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0);

begin

  --------------------------------------------
  -- Multipliers and adders
  --------------------------------------------

  u_multadd_i1 : wiener_multadd2
    port map (
      clk             => clk,
      reset_n         => reset_n,
      module_enable_i => module_enable,
      data1_i         => i_data1,
      data2_i         => i_data2,
      chanwien_c0_i   => chanwien_c0,
      chanwien_c1_i   => chanwien_c1,
      en_add_reg_i    => en_add_reg,
      add_o           => i_add1
    );

  u_multadd_q1 : wiener_multadd2
    port map (
      clk             => clk,
      reset_n         => reset_n,
      module_enable_i => module_enable,
      data1_i         => q_data1,
      data2_i         => q_data2,
      chanwien_c0_i   => chanwien_c0,
      chanwien_c1_i   => chanwien_c1,
      en_add_reg_i    => en_add_reg,
      add_o           => q_add1
    );

  u_multadd_i2 : wiener_multadd2
    port map (
      clk             => clk,
      reset_n         => reset_n,
      module_enable_i => module_enable,
      data1_i         => i_data3,
      data2_i         => i_data4,
      chanwien_c0_i   => chanwien_c2,
      chanwien_c1_i   => chanwien_c3,
      en_add_reg_i    => en_add_reg,
      add_o           => i_add2
    );

  u_multadd_q2 : wiener_multadd2
    port map (
      clk             => clk,
      reset_n         => reset_n,
      module_enable_i => module_enable,
      data1_i         => q_data3,
      data2_i         => q_data4,
      chanwien_c0_i   => chanwien_c2,
      chanwien_c1_i   => chanwien_c3,
      en_add_reg_i    => en_add_reg,
      add_o           => q_add2
    );

  --------------------------------------------
  -- Controller
  --------------------------------------------
  u_ctrl : wiener_ctrl
    port map (
      clk               => clk,
      reset_n           => reset_n,
      sync_reset_n      => sync_reset_n,
      wf_window_i       => wf_window_i,
      i_i               => i_i,
      q_i               => q_i,
      data_valid_i      => data_valid_i,
      start_of_burst_i  => start_of_burst_i,
      start_of_symbol_i => start_of_symbol_i,
      data_ready_i      => data_ready_i,
      data_ready_o      => data_ready_o,
      i_o               => i_o,
      q_o               => q_o,
      data_valid_o      => data_valid_o,
      start_of_symbol_o => start_of_symbol_o,
      start_of_burst_o  => start_of_burst_o,
      -- ROM access
      chanwien_do_i     => chanwien_do,
      chanwien_a_o      => chanwien_a,
      chanwien_cs_no    => chanwien_cs_n,
      module_enable_o   => module_enable,
      -- to multadd module
      i_add1_i          => i_add1,
      q_add1_i          => q_add1,
      i_add2_i          => i_add2,
      q_add2_i          => q_add2,
      i_data1_o         => i_data1,
      q_data1_o         => q_data1,
      i_data2_o         => i_data2,
      q_data2_o         => q_data2,
      i_data3_o         => i_data3,
      q_data3_o         => q_data3,
      i_data4_o         => i_data4,
      q_data4_o         => q_data4,
      chanwien_c0_o     => chanwien_c0,
      chanwien_c1_o     => chanwien_c1,
      chanwien_c2_o     => chanwien_c2,
      chanwien_c3_o     => chanwien_c3,
      en_add_reg_o      => en_add_reg
    );

  --------------------------------------------
  -- Coeff table
  --------------------------------------------
  u_coeff : wiener_coeff
    port map (
      clk             => clk,
      reset_n         => reset_n,
      chanwien_cs_ni  => chanwien_cs_n,
      module_enable_i => module_enable,
      chanwien_a_i    => chanwien_a,
      chanwien_do_o   => chanwien_do
    );

end rtl;
