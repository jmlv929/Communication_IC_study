

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of phase_estimation is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal data_i_ext   : std_logic_vector(dsize_g downto 0);
  signal data_q_ext   : std_logic_vector(dsize_g downto 0);
  signal phase_error  : std_logic_vector(esize_g-1 downto 0);
  signal error_ready  : std_logic; -- phase_error valid.


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin


  data_i_ext(dsize_g) <= data_i(dsize_g-1);
  data_q_ext(dsize_g) <= data_q(dsize_g-1);

  data_i_ext(dsize_g-1 downto 0) <= data_i;
  data_q_ext(dsize_g-1 downto 0) <= data_q;
  --------------------------------------
  -- Port map for phase error generator.
  --------------------------------------
  error_gen_1: error_gen
  generic map (
    datasize_g  => dsize_g+1,
    errorsize_g => esize_g
  )
  port map (
      -- clock and reset.
      clk                 => clk,
      reset_n             => reset_n,
      --
      symbol_sync         => symbol_sync, -- Symbol synchronization pulse.
      data_i              => data_i_ext,  -- Real data in.
      data_q              => data_q_ext,  -- Imaginary data in.
      demap_data          => demap_data,  -- Data from demapping.
      enable_error        => enable_error,
      --
      phase_error         => phase_error, -- Phase error.
      error_ready         => error_ready  -- Error ready.
      );

  --------------------------------------
  -- Port map for filter.
  --------------------------------------
  filter_1: filter
  generic map (
    esize_g     => esize_g,     -- size of error (must >= dsize_g).
    phisize_g   => phisize_g,   -- size of angle phi
    omegasize_g => omegasize_g, -- size of angle omega
    sigmasize_g => sigmasize_g, -- size of angle sigma
    tausize_g   => tausize_g    -- size of tau
  )
  port map (
      -- clock and reset.
      clk                  => clk,
      reset_n              => reset_n,
      --
      load                 => error_ready, -- Filter synchronization.
      precomp_enable       => precomp_enable,  -- Precompensation enable
      interpolation_enable => interpolation_enable, -- Interpolation enable  
      enable_error         => enable_error,-- Enable the compensation. 
      symbol_sync          => symbol_sync, -- Symbol synchronization.
      mod_type             => mod_type,    -- Modulation type (DSSS or CCK).
      phase_error          => phase_error, -- Phase error.
      rho                  => rho,         -- rho parameter value.
      mu                   => mu,          -- mu parameter value.
      --                   
      freqoffestim_stat    => freqoffestim_stat,               
      phi                  => phi,         -- phi angle.
      sigma                => sigma,       -- theta angle.
      omega                => omega,       -- omega angle.
      tau                  => tau          -- tau.
      );

  ------------------------------------------------------------------------------
  -- Global Signals for test
  ------------------------------------------------------------------------------
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off 
--  phase_error_tglobal(31 downto dsize_g-1) <= (others => phase_error(dsize_g-1));
--  phase_error_tglobal(dsize_g-1 downto 0) <= phase_error;
--  phase_error_gbl <= phase_error;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on
end RTL;
