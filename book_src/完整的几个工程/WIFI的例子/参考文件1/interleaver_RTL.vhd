

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of interleaver is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Signals for memory interface.
  signal addr      : std_logic_vector(4 downto 0); -- address.
  signal mask_wr   : std_logic_vector(5 downto 0); -- write mask.
  signal rd_wrn    : std_logic; -- '1' means read, '0' means write.
  signal msb_lsbn  : std_logic; -- '1' to read the MSB, '0' to read the LSB.
  signal data_p1   : std_logic_vector(5 downto 0); -- First permutated data.


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  --------------------------------------
  -- Interleaver control block.
  --------------------------------------
  interl_ctrl_1 : interl_ctrl
    port map (
      -- Clocks & Reset
      clk               => clk,             -- Module clock.
      reset_n           => reset_n,         -- Asynchronous reset.
      -- Controls
      enable_i          => enable_i,        -- TX path enable.
      data_valid_i      => data_valid_i,
      data_ready_i      => data_ready_i,
      qam_mode_i        => qam_mode_i,
      marker_i          => marker_i,
      --
      pilot_ready_o     => pilot_ready_o,
      start_signal_o    => start_signal_o,  -- 'start of signal' marker.
      end_burst_o       => end_burst_o,      -- 'end of burst' marker.
      data_valid_o      => data_valid_o,
      data_ready_o      => data_ready_o,
      null_carrier_o    => null_carrier_o,  -- '1' data for null carriers.
      qam_mode_o        => qam_mode_o,      -- coding rate.
      -- Memory interface
      data_p1_i         => data_p1,         -- First permutated data.
      --
      addr_o            => addr,            -- Memory address.
      mask_wr_o         => mask_wr,         -- memory write mask.
      rd_wrn_o          => rd_wrn,          -- '1' to read, '0' to write.
      msb_lsbn_o        => msb_lsbn,        -- '1' to read MSB, '0' to read LSB.
      -- Data
      pilot_scr_i       => pilot_scr_i,     -- Data for the 4 pilot carriers.
      --
      data_o            => data_o           -- Interleaved data.
    
      );


  --------------------------------------
  -- Memory for permutation 1.
  --------------------------------------
  interl_mem_1 : interl_mem
    port map (
      -- Clocks & Reset
      clk               => clk,             -- Module clock.
      reset_n           => reset_n,         -- Asynchronous reset.
      -- Controls
      enable_i          => enable_i,        -- TX path enable.
      addr_i            => addr,            -- Memory address.
      mask_wr_i         => mask_wr,         -- Memory write mask.
      rd_wrn_i          => rd_wrn,          -- '1' to read, '0' to write.
      msb_lsbn_i        => msb_lsbn,
      -- Data
      x_i               => x_i,             -- x data from puncturer.
      y_i               => y_i,             -- y data from puncturer.
      --
      data_p1_o         => data_p1          -- First permutated data.
      );


end RTL;
