

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of tx_rx_iq_comp is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Muxed Signals
  signal phase_muxed        : std_logic_vector(phase_width_g-1 downto 0);
  signal ampl_muxed         : std_logic_vector(ampl_width_g-1 downto 0);
  signal data_valid_i_muxed : std_logic;      -- high when a new data is available
  signal i_in_muxed         : std_logic_vector(iq_i_width_g-1 downto 0);
  signal q_in_muxed         : std_logic_vector(iq_i_width_g-1 downto 0);
  -- IQ Compensation Output
  signal i_out              : std_logic_vector(iq_o_width_g-1 downto 0);
  signal q_out              : std_logic_vector(iq_o_width_g-1 downto 0);
  signal data_valid_out     : std_logic;  -- high/toggle when a new data is available
  -- IQ Compensation Output saturated
  signal i_out_sat          : std_logic_vector(iq_o_width_g-3 downto 0);
  signal q_out_sat          : std_logic_vector(iq_o_width_g-3 downto 0);
  signal i_out_sat_round    : std_logic_vector(iq_o_width_g-4 downto 0);
  signal q_out_sat_round    : std_logic_vector(iq_o_width_g-4 downto 0);
  


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  -----------------------------------------------------------------------------
  -- Mux data inputs
  -----------------------------------------------------------------------------
  phase_muxed           <= tx_phase_i when tx_rxn_select = '1'
                     else rx_phase_i;

  ampl_muxed            <= tx_ampl_i when tx_rxn_select = '1'
                     else rx_ampl_i;

  data_valid_i_muxed    <= '0' when tx_rxn_select = '1'
                     else rx_data_valid_i;
  
  i_in_muxed            <= sxt(tx_i_in &'0',iq_i_width_g) when tx_rxn_select = '1'
                     else rx_i_in;

  q_in_muxed            <= sxt(tx_q_in &'0',iq_i_width_g) when tx_rxn_select = '1'
                     else rx_q_in;
  
  -----------------------------------------------------------------------------
  -- Instantiate IQ Compensation block
  -----------------------------------------------------------------------------
  iq_compensation_1: iq_compensation
    generic map (
      iq_i_width_g  => iq_i_width_g,    -- IQ inputs width.
      iq_o_width_g  => iq_o_width_g,    -- IQ outputs width.
      phase_width_g => phase_width_g,   -- Phase parameter width.
      ampl_width_g  => ampl_width_g,    -- Amplitude parameter width.
      toggle_in_g   => toggle_in_g,     -- when 1 the data_valid_i toggles
      toggle_out_g  => toggle_out_g)    -- when 1 the data_valid_o toggles
    port map (
      clk          => clk,                -- [in]  Module clock. 60 MHz
      reset_n      => reset_n,            -- [in]  Asynchronous reset.
      sync_reset_n => sync_reset_n,       -- [in]  Block enable.
      phase_i      => phase_muxed,        -- [in]
      ampl_i       => ampl_muxed,         -- [in]
      data_valid_i => data_valid_i_muxed, -- [in]  high when a new data is available
      data_valid_o => data_valid_out,     -- [out] high/toggle when a new data is available
      i_in         => i_in_muxed,         -- [in]
      q_in         => q_in_muxed,         -- [in]
      i_out        => i_out,              -- [out]
      q_out        => q_out);             -- [out]

  -----------------------------------------------------------------------------
  -- Mux data outputs
  -----------------------------------------------------------------------------
  -- set to '0' when path is not selected for power consumption matters

  -- rx path
  rx_i_out <= i_out when tx_rxn_select = '0'
                else (others => '0');
  
  rx_q_out <= q_out when tx_rxn_select = '0'
                else (others => '0');

  -- Reduce size of the tx output (must be 8 bits):

  -- saturate (remove 2 bits)
  i_out_sat <= sat_signed_slv(i_out,2);
  q_out_sat <= sat_signed_slv(q_out,2);

  -- round (remove 1 bit)
  i_out_sat_round <= i_out_sat(i_out_sat'high downto 1) + i_out_sat(0);
  q_out_sat_round <= q_out_sat(i_out_sat'high downto 1) + q_out_sat(0);
  
  -- tx path
  tx_i_out <= i_out_sat_round when tx_rxn_select = '1'
                else (others => '0');
  
  tx_q_out <= q_out_sat_round when tx_rxn_select = '1'
                else (others => '0');
  
  rx_data_valid_o <= data_valid_out when tx_rxn_select = '0'
                else '0';
  
  
end RTL;
