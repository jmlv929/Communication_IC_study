

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of channel_decoder is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal enable_control       : std_logic;
  signal enable_deintpun      : std_logic;
  signal enable_viterbi       : std_logic;
  signal enable_signal        : std_logic;
  signal enable_data          : std_logic;

  signal data_valid_gated     : std_logic;
  signal data_valid_deintpun  : std_logic;
  signal data_valid_viterbi   : std_logic;

  signal data_ready_deintpun  : std_logic;
  signal data_ready_control   : std_logic;

  signal start_of_field       : std_logic;
  signal end_of_field_viterbi : std_logic;
  signal end_of_data          : std_logic;
  
  signal soft_x_deintpun : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal soft_y_deintpun : std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
  signal data_viterbi    : std_logic;

  signal signal_field : std_logic_vector(SIGNAL_FIELD_LENGTH_CT-1 downto 0);
  signal signal_field_valid_signal : std_logic;
  signal signal_field_valid        : std_logic;
  signal qam_mode                  : std_logic_vector(1 downto 0);
  signal pun_mode                  : std_logic_vector(1 downto 0);
  signal parity_error              : std_logic;
  signal unsupported_rate          : std_logic;
  signal unsupported_length        : std_logic;
 
  signal field_length              : std_logic_vector(15 downto 0);
  signal smu_partition             : std_logic_vector(1 downto 0);
  signal smu_table_s               : std_logic_vector(15 downto 0);


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- SMU table : 0xFF99
  smu_table_s <= "1111111110011001";
  
  --------------------------------------
  -- control unit
  --------------------------------------
  channel_decoder_control_1 : channel_decoder_control
    port map (
      reset_n               => reset_n,
      clk                   => clk,
      sync_reset_n          => sync_reset_n,
      start_of_burst_i      => start_of_burst_i,
      start_of_field_o      => start_of_field,
      signal_field_valid_i  => signal_field_valid_signal,
      end_of_data_i         => end_of_data,
      signal_field_valid_o  => signal_field_valid,
      data_ready_deintpun_i => data_ready_deintpun,
      data_ready_o          => data_ready_control,
      enable_i              => enable_control,
      enable_deintpun_o     => enable_deintpun,
      enable_viterbi_o      => enable_viterbi,
      enable_signal_o       => enable_signal,
      enable_data_o         => enable_data,
      length_limit_i        => length_limit_i,
      rx_length_chk_en_i    => rx_length_chk_en_i,
      signal_field_i        => signal_field,
      smu_table_i           => smu_table_s,
      smu_partition_o       => smu_partition,
      field_length_o        => field_length,
      qam_mode_o            => qam_mode,
      pun_mode_o            => pun_mode,
      parity_error_o        => parity_error,
      unsupported_rate_o    => unsupported_rate,
      unsupported_length_o  => unsupported_length
      );

  --------------------------------------
  -- deintpun
  --------------------------------------
  deintpun_1 : deintpun
    port map (
      reset_n        => reset_n,
      clk            => clk,
      sync_reset_n   => sync_reset_n,
      enable_i       => enable_deintpun,
      data_valid_i   => data_valid_gated,
      data_valid_o   => data_valid_deintpun,
      data_ready_o   => data_ready_deintpun,
      start_field_i  => start_of_field,
      field_length_i => field_length,
      qam_mode_i     => qam_mode,
      pun_mode_i     => pun_mode,
      soft_x0_i      => soft_x0_i,
      soft_x1_i      => soft_x1_i,
      soft_x2_i      => soft_x2_i,
      soft_y0_i      => soft_y0_i,
      soft_y1_i      => soft_y1_i,
      soft_y2_i      => soft_y2_i,
      soft_x_o       => soft_x_deintpun,
      soft_y_o       => soft_y_deintpun
      );

  --------------------------------------
  -- viterbi unit
  --------------------------------------
  viterbi_1 : viterbi_boundary
    generic map (
      code_0_g           => 91,     -- Upper code vector in decimal
      code_1_g           => 121,    -- Lower code vector in decimal
      algorithm_g        => 0,      -- 0 => Register exchange algorithm.
                                    -- 1 => Trace back algorithm.
      reg_length_g       => 56,     -- Number of bits for error recovery for data field.
      short_reg_length_g => 24,     -- Number of bits for error recovery for signal field.
      datamax_g          => 5,      -- Number of soft decision input bits.
      path_length_g      => 9,      -- No of bits to code the path   metrics.
      error_check_g      => 0       -- 0 => no error check. 1 => error check
      )
    port map (
      reset_n         => reset_n,
      clk             => clk,
      sync_reset_n    => sync_reset_n,
      enable_i        => enable_viterbi, 
      data_valid_i    => data_valid_deintpun,
      data_valid_o    => data_valid_viterbi,
      start_field_i   => start_of_field,
      end_field_o     => end_of_field_viterbi,
      v0_in           => soft_x_deintpun,
      v1_in           => soft_y_deintpun,
      hard_output_o   => data_viterbi,
      field_length_i  => field_length
      );

  --------------------------------------
  -- slicing signal field info
  --------------------------------------
  channel_decoder_signal_1 : channel_decoder_signal
    port map (
      reset_n        => reset_n,
      clk            => clk,
      sync_reset_n   => sync_reset_n,
      enable_i       => enable_signal,
      data_valid_i   => data_valid_viterbi,
      data_valid_o   => signal_field_valid_signal,
      start_field_i  => start_of_field,
      end_field_i    => end_of_field_viterbi,
      data_i         => data_viterbi,
      signal_field_o => signal_field
    );

  --------------------------------------
  -- preparing data for output
  --------------------------------------
  channel_decoder_data_1 : channel_decoder_data
    port map (
      reset_n            => reset_n,
      clk                => clk,
      sync_reset_n       => sync_reset_n,
      enable_i           => enable_data,
      data_valid_i       => data_valid_viterbi,
      data_valid_o       => data_valid_o,
      start_data_field_i => start_of_field,
      start_data_field_o => start_of_burst_o,
      end_data_field_i   => end_of_field_viterbi,
      end_data_field_o   => end_of_data,
      data_i             => data_viterbi,
      data_o             => data_o
    );



  -----------------------------------------------------------------------------
  -- switch of data_valid if deintpun is not ready to take data
  -----------------------------------------------------------------------------
  data_valid_gated <= data_valid_i and data_ready_control;
  
  -----------------------------------------------------------------------------
  -- enable_control: global enable for everything
  -----------------------------------------------------------------------------
  enable_control <= data_ready_i;

  -----------------------------------------------------------------------------
  -- data_ready condition for equalizer
  -----------------------------------------------------------------------------
  data_ready_o <= data_ready_control and data_ready_i;

  -----------------------------------------------------------------------------
  -- marks last bit of burst
  -----------------------------------------------------------------------------
  end_of_data_o                   <= end_of_data;

  -----------------------------------------------------------------------------
  -- output the deinterleaver/depuncturing pattern for debugging
  -----------------------------------------------------------------------------
  soft_x_deintpun_o               <= soft_x_deintpun;
  soft_y_deintpun_o               <= soft_y_deintpun;
  data_valid_deintpun_o           <= data_valid_deintpun;
  
  -----------------------------------------------------------------------------
  -- output the sliced signal field parameter
  -----------------------------------------------------------------------------
  signal_field_valid_o              <= signal_field_valid;
  signal_field_o                    <= signal_field;
  signal_field_parity_error_o       <= parity_error;
  signal_field_unsupported_rate_o   <= unsupported_rate;
  signal_field_unsupported_length_o <= unsupported_length;
  signal_field_puncturing_mode_o    <= pun_mode;
  

end RTL;
