

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of fine_freq_estim is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal i_reg                      : std_logic_vector (10 downto 0);
  signal q_reg                      : std_logic_vector (10 downto 0);
  signal i_mem2                     : std_logic_vector (10 downto 0);
  signal q_mem2                     : std_logic_vector (10 downto 0);
  signal tcomb_re                   : std_logic_vector (10 downto 0);
  signal tcomb_im                   : std_logic_vector (10 downto 0);
  signal t1_re                      : std_logic_vector (10 downto 0);
  signal t1_im                      : std_logic_vector (10 downto 0);
  signal data_valid_for_cf          : std_logic;
  signal data_valid_freqcorr        : std_logic;
  signal start_of_symbol_cf_compute : std_logic;
  signal start_of_symbol_t1t2premux : std_logic;
  signal init                       : std_logic;
  signal rd_ptr                     : std_logic_vector(5 downto 0);
  signal last_data                  : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  init <= not sync_res_n;

  -----------------------------------------------------------------------------
  -- State Machines Instantiation
  -----------------------------------------------------------------------------
  ff_estim_sm_1 : ff_estim_sm
    port map (
      clk                           => clk,
      reset_n                       => reset_n,
      init_i                        => init,
      -- Markers associated with ffe-inputs (i/q)
      start_of_burst_i              => start_of_burst_i,
      start_of_symbol_i             => start_of_symbol_i,
      data_valid_i                  => data_valid_i,
      data_ready_o                  => data_ready_o,
      -- control Mem Write/Read 
      read_enable_o                 => read_enable_o,
      wr_ptr_o                      => wr_ptr_o,
      write_enable_o                => write_enable_o,
      rd_ptr_o                      => rd_ptr,
      rd_ptr2_o                     => rd_ptr2_o,
      -- start_of_symbol and start_of_burst for cf computation
      start_of_symbol_cf_compute_o  => start_of_symbol_cf_compute,
      -- valid data for cf/tcomb computation
      data_valid_for_cf_o           => data_valid_for_cf,
      last_data_o                   => last_data,
      data_valid_freqcorr_i         => data_valid_freqcorr,
      -- data from Mem (port 2) will feed t1t2premux (storage of t1t2coarse)
      i_mem2_i                      => i_mem2,
      q_mem2_i                      => q_mem2,
      -- data from tcomb-compute will feed tcombpremux (tcomb from t1t2fine)
      i_tcomb_i                     => tcomb_re,
      q_tcomb_i                     => tcomb_im,
      -- interface with t1t2premux
      i_t1t2_o                      => i_t1t2_o,
      q_t1t2_o                      => q_t1t2_o,
      data_ready_t1t2premux_i       => data_ready_t1t2premux_i,
      data_valid_t1t2premux_o       => data_valid_t1t2premux_o,
      start_of_symbol_t1t2premux_o  => start_of_symbol_t1t2premux,
      -- interface with tcombpremux
      i_tcomb_o                     => i_tcomb_o,
      q_tcomb_o                     => q_tcomb_o,
      data_ready_tcombpremux_i      => data_ready_tcombpremux_i,
      data_valid_tcombpremux_o      => data_valid_tcombpremux_o,
      start_of_burst_tcombpremux_o  => start_of_burst_tcombpremux_o,
      start_of_symbol_tcombpremux_o => start_of_symbol_tcombpremux_o,
      ffest_state_o                 => ffest_state_o
      );


  -----------------------------------------------------------------------------
  -- Computation Instantiation
  -----------------------------------------------------------------------------
  ff_estim_compute_1 : ff_estim_compute
    port map (
      clk                          => clk,
      reset_n                      => reset_n,
      init_i                       => init,
      -- data used to compute Cf/Tcomb (T1mem/T2)
      t1_re_i                      => t1_re,
      t1_im_i                      => t1_im,
      t2_re_i                      => i_i,
      t2_im_i                      => q_i,
      -- domain of validity for data 
      data_valid_4_cf_compute_i    => data_valid_for_cf,
      last_data_i                  => last_data,
      shift_param_i                => shift_param_i,
      -- Markers 
      start_of_symbol_i            => start_of_symbol_cf_compute,
      -- Cf calculation
      cf_freqcorr_o                => cf_freqcorr_o,
      data_valid_freqcorr_o        => data_valid_freqcorr,
      -- Tcomb calculation
      tcomb_re_o                   => tcomb_re,
      tcomb_im_o                   => tcomb_im
      );

  rd_ptr_o                     <= '0' & rd_ptr;
  t1_re                        <= mem1_i (21 downto 11);
  t1_im                        <= mem1_i (10 downto 0);
  i_mem2                       <= mem2_i (21 downto 11);
  q_mem2                       <= mem2_i (10 downto 0);
  mem_o                        <= i_i & q_i;
  start_of_symbol_t1t2premux_o <= start_of_symbol_t1t2premux;
  data_valid_freqcorr_o        <= data_valid_freqcorr;

end RTL;
