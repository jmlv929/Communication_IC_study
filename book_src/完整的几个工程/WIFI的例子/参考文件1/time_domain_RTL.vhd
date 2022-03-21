

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of time_domain is


  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Tcomb preamble mux
  signal data_ready_tcombpremux                  : std_logic;
  signal tcomb_ready_tcombpremux                 : std_logic;
  signal tcomb_data_valid                        : std_logic;
  signal start_of_symbol                         : std_logic;
  -- Frequency correction
  signal data_ready_t1t2premux_freqcorr          : std_logic;
  signal data_ready_finefreqest                  : std_logic;
  signal i_freqcorr                              : std_logic_vector(10 downto 0);
  signal q_freqcorr                              : std_logic_vector(10 downto 0);
  signal data_valid_freqcorr                     : std_logic;
  signal start_of_burst_freqcorr                 : std_logic;
  signal start_of_symbol_freqcorr                : std_logic;
  signal coarsefreq                              : std_logic_vector(23 downto 0);
  signal coarsefreq_valid                        : std_logic;
  signal finefreq                                : std_logic_vector(23 downto 0);
  signal finefreq_valid                          : std_logic;
  -- T1T2 premux
  signal data_ready_t1t2premux                   : std_logic;
  signal data_ready_finefreqest_t1t2premux       : std_logic;
  signal i_t1t2premux                            : std_logic_vector(10 downto 0);
  signal q_t1t2premux                            : std_logic_vector(10 downto 0);
  signal data_valid_t1t2premux                   : std_logic;
  signal start_of_burst_t1t2premux               : std_logic;
  signal start_of_symbol_t1t2premux              : std_logic;
  -- Sample FIFO
  signal i_samplefifo                            : std_logic_vector(10 downto 0);
  signal q_samplefifo                            : std_logic_vector(10 downto 0);
  signal data_valid_samplefifo                   : std_logic;
  signal start_of_burst_samplefifo               : std_logic;
  signal start_of_symbol_samplefifo              : std_logic;
  signal i_t1t2_finefreqest                      : std_logic_vector(10 downto 0);
  signal q_t1t2_finefreqest                      : std_logic_vector(10 downto 0);
  signal i_tcomb_finefreqest                     : std_logic_vector(10 downto 0);
  signal q_tcomb_finefreqest                     : std_logic_vector(10 downto 0);
  signal start_of_burst_finefreqest              : std_logic;
  signal data_valid_tcombpremux_finefreqest      : std_logic;
  signal data_valid_t1t2premux_finefreqest       : std_logic;
  signal start_of_symbol_tcombpremux_finefreqest : std_logic;
  signal start_of_symbol_t1t2premux_finefreqest  : std_logic;
  -- T1T2 demux
  signal data_ready_t1t2demux                    : std_logic;
  signal data_valid_finefreqest_t1t2demux        : std_logic;
  signal start_of_burst_t1t2demux                : std_logic;
  signal start_of_symbol_finefreqest_t1t2demux   : std_logic;
  signal start_of_symbol_tcombpremux_t1t2demux   : std_logic;
  signal i_t1t2demux                             : std_logic_vector(10 downto 0);
  signal q_t1t2demux                             : std_logic_vector(10 downto 0);
  signal data_valid_tcombpremux_t1t2demux        : std_logic;
  -- INIT sync 
  signal frame_start_valid                       : std_logic;
  signal autocorr_enable                         : std_logic;
  signal fast_carrier_s                          : std_logic; -- to AGC CCA
  signal carrier_s                               : std_logic; -- to AGC CA
  signal shift_param                             : std_logic_vector(2 downto 0);
  -- memory access
  signal init_sync_read                          : std_logic;
  signal init_sync_read_ptr1                     : std_logic_vector(6 downto 0);
  signal init_sync_write                         : std_logic;
  signal init_sync_write_ptr                     : std_logic_vector(6 downto 0);
  signal init_sync_wdata                         : std_logic_vector(19 downto 0);
  signal init_sync_wdata_long                    : std_logic_vector(21 downto 0);
  signal fifo_mem_data1                          : std_logic_vector(21 downto 0);
  signal fifo_mem_data2                          : std_logic_vector(21 downto 0);
  -- FINE FREQ ESTIM
  signal ffe_wdata                               : std_logic_vector(21 downto 0);
  signal ffe1_read_ptr                           : std_logic_vector(6 downto 0);
  signal ffe2_read_ptr                           : std_logic_vector(6 downto 0);
  signal ffe_write_ptr                           : std_logic_vector(6 downto 0);
  signal ffe_write                               : std_logic;
  signal ffe_read                                : std_logic;
  -- DIAG
  signal iqcomp_middle_pulse                     : std_logic;
  signal iqcomp_middle_pulse_ff1                 : std_logic;
  signal yb_o                                    : std_logic_vector(3 downto 0);
  signal ffest_state_o                           : std_logic_vector(2 downto 0);


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  -----------------------------------------------------------------------------
  -- Sample FIFO Instantiation
  -----------------------------------------------------------------------------
   sample_fifo_1 : sample_fifo
     port map (
       clk                 => clk,
       reset_n             => reset_n,
       -- 
       sync_res_n          => sync_reset_n,
       i_i                 => i_iqcomp_i,
       q_i                 => q_iqcomp_i,
       data_valid_i        => iqcomp_data_valid_i,
       timoffst_i          => sampfifo_timoffst_i,
       frame_start_valid_i => frame_start_valid,
       data_ready_i        => data_ready_t1t2premux,
       --
       i_o                 => i_samplefifo,
       q_o                 => q_samplefifo,
       data_valid_o        => data_valid_samplefifo,
       start_of_burst_o    => start_of_burst_samplefifo,
       start_of_symbol_o   => start_of_symbol_samplefifo
       );

  -----------------------------------------------------------------------------
  -- T1T2 Preamble mux instantiation
  -----------------------------------------------------------------------------
  t1t2_preamble_mux_1 : t1t2_preamble_mux
    port map (
      clk                           => clk,
      reset_n                       => reset_n,
      --
      sync_reset_n                  => sync_reset_n,
      i_i                           => i_samplefifo,
      q_i                           => q_samplefifo,
      data_valid_i                  => data_valid_samplefifo,
      data_ready_o                  => data_ready_t1t2premux,
      i_finefreqest_i               => i_t1t2_finefreqest,
      q_finefreqest_i               => q_t1t2_finefreqest,
      finefreqest_valid_i           => data_valid_t1t2premux_finefreqest,
      finefreqest_ready_o           => data_ready_finefreqest_t1t2premux,
      start_of_burst_i              => start_of_burst_samplefifo,
      start_of_symbol_samplefifo_i  => start_of_symbol_samplefifo,
      start_of_symbol_finefreqest_i => start_of_symbol_t1t2premux_finefreqest,
      data_ready_i                  => data_ready_t1t2premux_freqcorr,
      i_o                           => i_t1t2premux,
      q_o                           => q_t1t2premux,
      data_valid_o                  => data_valid_t1t2premux,
      start_of_burst_o              => start_of_burst_t1t2premux,
      start_of_symbol_o             => start_of_symbol_t1t2premux
      );

  -----------------------------------------------------------------------------
  -- Frequency correction instantiation
  -----------------------------------------------------------------------------
  freq_corr_1 : freq_corr
     port map (
       clk                     => clk,
       reset_n                 => reset_n,
       sync_reset_n            => sync_reset_n,
       i_i                     => i_t1t2premux,
       q_i                     => q_t1t2premux,
       i_o                     => i_freqcorr,
       q_o                     => q_freqcorr,
       data_valid_i            => data_valid_t1t2premux,
       data_ready_i            => data_ready_t1t2demux,
       start_of_burst_i        => start_of_burst_t1t2premux,
       start_of_symbol_i       => start_of_symbol_t1t2premux,
       t1t2premux_data_ready_o => data_ready_t1t2premux_freqcorr,
       data_valid_o            => data_valid_freqcorr,
       start_of_burst_o        => start_of_burst_freqcorr,
       start_of_symbol_o       => start_of_symbol_freqcorr,
       coarsefreq_i            => coarsefreq,
       coarsefreq_valid_i      => coarsefreq_valid,
       finefreq_i              => finefreq,
       finefreq_valid_i        => finefreq_valid,
       freq_off_est            => freq_off_est_o
       );

  -----------------------------------------------------------------------------
  -- T1_T2_DEMUX instantiation
  -----------------------------------------------------------------------------
  t1t2_demux_1 : t1t2_demux
    generic map (
      data_size_g => 11)
    port map (
      clk                        => clk,
      reset_n                    => reset_n,
      --
      sync_reset_n               => sync_reset_n,
      i_i                        => i_freqcorr,
      q_i                        => q_freqcorr,
      data_valid_i               => data_valid_freqcorr,
      start_of_burst_i           => start_of_burst_freqcorr,
      start_of_symbol_i          => start_of_symbol_freqcorr,
      ffe_data_ready_i           => data_ready_finefreqest,
      tcombmux_data_ready_i      => data_ready_tcombpremux,
      data_ready_o               => data_ready_t1t2demux,
      ffe_start_of_burst_o       => start_of_burst_t1t2demux,
      ffe_start_of_symbol_o      => start_of_symbol_finefreqest_t1t2demux,
      ffe_data_valid_o           => data_valid_finefreqest_t1t2demux,
      tcombmux_data_valid_o      => data_valid_tcombpremux_t1t2demux,
      tcombmux_start_of_symbol_o => start_of_symbol_tcombpremux_t1t2demux,
      i_o                        => i_t1t2demux,
      q_o                        => q_t1t2demux
      );

  -----------------------------------------------------------------------------
  -- TCombine Preamble Mux Instantiation
  -----------------------------------------------------------------------------
    tcombine_preamble_mux_1 : tcombine_preamble_mux
      port map (
        clk               => clk,      -- module input
        reset_n           => reset_n,       -- module input
        --
        sync_reset_n      => sync_reset_n,  -- module input
        start_of_burst_i  => start_of_burst_finefreqest,
        start_of_symbol_i => start_of_symbol_tcombpremux_t1t2demux,
        data_ready_i      => data_ready_i,
        i_i               => i_t1t2demux,
        q_i               => q_t1t2demux,
        data_valid_i      => data_valid_tcombpremux_t1t2demux,
        i_tcomb_i         => i_tcomb_finefreqest,
        q_tcomb_i         => q_tcomb_finefreqest,
        tcomb_valid_i     => data_valid_tcombpremux_finefreqest,
        --
        start_of_burst_o  => start_of_burst_o,
        start_of_symbol_o => start_of_symbol,
        data_ready_o      => data_ready_tcombpremux,
        tcomb_ready_o     => tcomb_ready_tcombpremux,
        i_o               => i_o,
        q_o               => q_o,
        data_valid_o      => tcomb_data_valid
        );

  -- Outputs
  data_valid_o      <= tcomb_data_valid;
  start_of_symbol_o <= start_of_symbol;
   
  -----------------------------------------------------------------------------
  -- Fine frequency estimation instantiation
  -----------------------------------------------------------------------------
   fine_freq_estim_1 : fine_freq_estim
      port map (
        clk                           => clk,
        reset_n                       => reset_n,
        sync_res_n                    => sync_reset_n,
        start_of_burst_i              => start_of_burst_t1t2demux,
        start_of_symbol_i             => start_of_symbol_finefreqest_t1t2demux,
        data_valid_i                  => data_valid_finefreqest_t1t2demux,
        i_i                           => i_t1t2demux,
        q_i                           => q_t1t2demux,
        data_ready_o                  => data_ready_finefreqest,
        -- memory access
        read_enable_o                 => ffe_read,
        wr_ptr_o                      => ffe_write_ptr,
        write_enable_o                => ffe_write,
        rd_ptr_o                      => ffe1_read_ptr,
        rd_ptr2_o                     => ffe2_read_ptr,
        mem1_i                        => fifo_mem_data1,
        mem2_i                        => fifo_mem_data2,
        mem_o                         => ffe_wdata,
        -- interface with t1t2premux
        data_ready_t1t2premux_i       => data_ready_finefreqest_t1t2premux,
        i_t1t2_o                      => i_t1t2_finefreqest,
        q_t1t2_o                      => q_t1t2_finefreqest,
        data_valid_t1t2premux_o       => data_valid_t1t2premux_finefreqest,
        start_of_symbol_t1t2premux_o  => start_of_symbol_t1t2premux_finefreqest,
        -- Shift Parameter from Init_Sync
        shift_param_i                 => shift_param,
        -- interface with tcombpremux
        data_ready_tcombpremux_i      => tcomb_ready_tcombpremux,
        i_tcomb_o                     => i_tcomb_finefreqest,
        q_tcomb_o                     => q_tcomb_finefreqest,
        data_valid_tcombpremux_o      => data_valid_tcombpremux_finefreqest,
        start_of_burst_tcombpremux_o  => start_of_burst_finefreqest,
        start_of_symbol_tcombpremux_o => start_of_symbol_tcombpremux_finefreqest,
        cf_freqcorr_o                 => finefreq,
        data_valid_freqcorr_o         => finefreq_valid,
        -- Internal state for debug
        ffest_state_o                 => ffest_state_o
        );

  -----------------------------------------------------------------------------
  -- Shared FIFO Instantiation
  -----------------------------------------------------------------------------
  -- The fifo is shared by the init_sync and by the fine_freq_estim. They don't
  -- access it at the same time.
  shared_fifo_mem_1: shared_fifo_mem
    generic map (
      datawidth_g       => 22,
      addrsize_g        => 6,
      depth_g           => 128)
    port map (
      -- Clock & reset
      clk                   => clk,
      reset_n               => reset_n,
      -- Init sync 
      init_sync_read_i      => init_sync_read,
      init_sync_read_ptr1_i => init_sync_read_ptr1,
      init_sync_write_i     => init_sync_write,
      init_sync_write_ptr_i => init_sync_write_ptr,
      init_sync_wdata_i     => init_sync_wdata_long,
      -- Fine frequency estimation 
      ffe_wdata_i           => ffe_wdata,
      ffe1_read_ptr_i       => ffe1_read_ptr,
      ffe2_read_ptr_i       => ffe2_read_ptr,
      ffe_write_ptr_i       => ffe_write_ptr,
      ffe_write_i           => ffe_write,
      ffe_read_i            => ffe_read,
      -- Read data
      fifo_mem_data1_o      => fifo_mem_data1,
      fifo_mem_data2_o      => fifo_mem_data2);
 
  -----------------------------------------------------------------------------
  -- Init Sync Instantiation
  -----------------------------------------------------------------------------
  autocorr_enable <= '0';

  init_sync_1 : init_sync
    generic map (
      size_n_g        => 11,
      size_rem_corr_g => 4)
    port map (
      -- Clocks & Reset
      clk                 => clk,
      reset_n             => reset_n,
      -- Signals
      sync_res_n          => sync_reset_n,
      -- Input data
      i_i                 => i_iqcomp_i,
      q_i                 => q_iqcomp_i,
      data_valid_i        => iqcomp_data_valid_i,
      autocorr_enable_i   => autocorr_enable,
      -- Calculation parameters
      -- timing acquisition correction threshold parameters
      autothr0_i          => initsync_autothr0_i,
      autothr1_i          => initsync_autothr1_i,
      -- Treshold Accumulation for carrier sense  Register
      detthr_reg_i        => detect_thr_carrier_i,
      -- interface with Mem (write port Read port + control)
      mem_o               => init_sync_wdata,
      mem1_i              => fifo_mem_data2(19 downto 0),
      wr_ptr_o            => init_sync_write_ptr,
      rd_ptr1_o           => init_sync_read_ptr1,
      write_enable_o      => init_sync_write,
      read_enable_o       => init_sync_read,
      -- coarse frequency correction increment
      cf_inc_o            => coarsefreq,
      cf_inc_data_valid_o => coarsefreq_valid,
      -- Preamble Detected
      cp2_detected_o      => cp2_detected_o,
      preamb_detect_o     => frame_start_valid,
      shift_param_o       => shift_param,
      fast_carrier_s_o    => fast_carrier_s,
      carrier_s_o         => carrier_s,
      -- Internal signal for debug from postprocessing
      yb_o                => yb_o,
      ybnb_o              => ybnb_o
      );

  -- The memory access with the shared memory is only 20 bits width.
  init_sync_wdata_long <= "00" & init_sync_wdata;

  -- output linking
  preamb_detect_o <= frame_start_valid;
  
  ---------------------------------------
  -- Diag. port
  ---------------------------------------
  time_domain_diag0 <= q_iqcomp_i(10 downto 3) & i_iqcomp_i(10 downto 3);

  time_domain_diag1 <= q_iqcomp_i(2 downto 0) & i_iqcomp_i(2 downto 0) &
                       iqcomp_middle_pulse_ff1 & yb_o & frame_start_valid;

  time_domain_diag2 <= tcomb_data_valid & 
                       data_ready_i &
                       ffest_state_o &
                       start_of_symbol;


  generate_diag_p : process(clk, reset_n)
  begin
    if reset_n = '0' then
      iqcomp_middle_pulse     <= '0';
      iqcomp_middle_pulse_ff1 <= '0';
    elsif clk'event and clk = '1' then
      -- Generation of a pulse in the middle of the input data
      iqcomp_middle_pulse     <= iqcomp_data_valid_i;
      iqcomp_middle_pulse_ff1 <= iqcomp_middle_pulse;
    end if;
  end process generate_diag_p;

  
end RTL;
