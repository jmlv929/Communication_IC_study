

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of sample_fifo is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant FIFO_WIDTH_CT               : integer := 22; 
  constant FIFO_DEPTH_CT               : integer := 26; 
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal ctrl_data_valid   : std_logic;
  signal start_rd          : std_logic;
  signal rbuf_data_i       : std_logic_vector(i_i'length + q_i'length - 1 downto 0);
  signal rbuf_data_o       : std_logic_vector(i_o'length + q_o'length - 1 downto 0);
  signal out_data_ready_o  : std_logic;
  signal rbuf_data_valid_o : std_logic;
  signal rbuf_i_o          : std_logic_vector(10 downto 0);
  signal rbuf_q_o          : std_logic_vector(10 downto 0);
  signal init              : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  init <= not sync_res_n;
  -----------------------------------------------------------------------------
  -- Sample Fifo States Machines Instantiation
  -----------------------------------------------------------------------------
  sample_fifo_sm_1 : sample_fifo_sm
    port map (
      clk                 => clk,
      reset_n             => reset_n,
      init_i              => init,
      data_valid_i        => data_valid_i,
      timoffst_i          => timoffst_i,
      frame_start_valid_i => frame_start_valid_i,
      --
      start_rd_o          => start_rd,
      data_valid_o        => ctrl_data_valid
      );

  -----------------------------------------------------------------------------
  -- Ring Buffer Instantiation
  -----------------------------------------------------------------------------
  ring_buffer_1 : ring_buffer
    generic map (
      fifo_width_g => FIFO_WIDTH_CT,
      fifo_depth_g => FIFO_DEPTH_CT
      )
    port map (
      clk          => clk,
      reset_n      => reset_n,
      init_i       => init,
      --
      data_valid_i => ctrl_data_valid,
      data_ready_i => out_data_ready_o,
      --
      start_rd_i     => start_rd,
      rd_wr_diff   => timoffst_i,
      data_valid_o => rbuf_data_valid_o,
      data_i       => rbuf_data_i,
      data_o       => rbuf_data_o
      );

  -- I and Q are concatenated inside rbuf_data_o => split it
  rbuf_i_o    <= rbuf_data_o(rbuf_data_o'high downto rbuf_data_o'low + i_o'length);
  rbuf_q_o    <= rbuf_data_o(q_o'high downto 0);
  rbuf_data_i <= i_i & q_i;

  -----------------------------------------------------------------------------
  -- Output Modes Instantiation
  -----------------------------------------------------------------------------
  output_modes_1 : output_modes
    port map(
      clk               => clk,
      reset_n           => reset_n,
      init_i            => init,
      i_i               => rbuf_i_o,
      q_i               => rbuf_q_o,
      data_valid_i      => rbuf_data_valid_o,
      data_ready_i      => data_ready_i,
      --
      i_o               => i_o,
      q_o               => q_o,
      data_ready_o      => out_data_ready_o,
      data_valid_o      => data_valid_o,
      start_of_burst_o  => start_of_burst_o,
      start_of_symbol_o => start_of_symbol_o
      );

end RTL;
