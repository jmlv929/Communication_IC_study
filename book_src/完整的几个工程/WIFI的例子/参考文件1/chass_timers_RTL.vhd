

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of chass_timers is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal int_chassbsy        : std_logic_vector(25 downto 0);
  signal int_chasstim        : std_logic_vector(25 downto 0);
  signal channel_busy        : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  -- Assign output ports.
  reg_chassbsy <= int_chassbsy;
  reg_chasstim <= int_chasstim;
  
  -- Channel assessment counter increments every MHz when:
  -- * the low-power mode is not activated
  -- * channel assessment is enabled (reg_chassen)
  -- * it has not reached its max value
  chasstim_p: process (reset_n, clk)
  begin
    if reset_n = '0' then
      int_chasstim <= (others => '0');
    elsif clk'event and clk = '1' then

      -- Software request to reset the timer.
      if reset_chasstim = '1' then
        int_chasstim <= (others => '0');
      else
        if reg_chassen = '1' and int_chasstim /= CHASSTIM_MAX_CT
                             and enable_1mhz = '1' and mode32k = '0' then
          int_chasstim <= int_chasstim + 1;
        end if;
      end if;

    end if;
  end process chasstim_p;
  
  
  -- Channel busy condition.
  -- * ignore VCS if reg_ignvcs is HIGH.
  channel_busy <= (vcs_enable and not(reg_ignvcs))
                  or phy_cca_ind or phy_txstartend_conf;
  
  -- Channel busy counter increments every MHz when:
  -- * the low-power mode is not activated
  -- * channel assessment is enabled (reg_chassen)
  -- * chasstim has not reached its max value
  -- * the channel_busy condition is met.
  chassbsy_p: process (reset_n, clk)
  begin
    if reset_n = '0' then
      int_chassbsy <= (others => '0');

    elsif clk'event and clk = '1' then

      -- Software request to reset the timer.
      if reset_chassbsy = '1' then
        int_chassbsy <= (others => '0');
      else
        if reg_chassen = '1' and int_chasstim /= CHASSTIM_MAX_CT
                             and enable_1mhz = '1' and mode32k = '0'
                             and channel_busy = '1' then
          int_chassbsy <= int_chassbsy + 1;
        end if;
      end if;

    end if;
  end process chassbsy_p;
  
  

end RTL;
