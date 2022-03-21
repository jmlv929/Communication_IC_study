

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of pilot_scr is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Signals for the pseudo-noise generator
  signal next_pn_shift   : std_logic_vector(6 downto 0); -- Register next value.
  signal pn_shift        : std_logic_vector(6 downto 0); -- Shift register.
  signal pilot_ready_ff  : std_logic; -- Store pilot_ready_i for edge detection.
  signal pilot_scrambled : std_logic; -- Shift register input value.


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  pilot_scrambled <= pn_shift(6) xor pn_shift(3);
  -- Pilot scrambler input data is always '1'.
  pilot_scr_o     <= not(pilot_scrambled);
  
  -- Data shift.
  shift_comb_p : process (init_pilot_scr_i, pilot_ready_ff, pilot_ready_i,
                          pilot_scrambled, pn_shift)
  begin
    -- On init_pilot_scr_i, init the shift register with all '1'.
    if init_pilot_scr_i = '1' then
      next_pn_shift <= (others => '1');
    -- Shift on pilot_ready_i rise
    elsif (pilot_ready_i = '1' and pilot_ready_ff = '0') then
      next_pn_shift <= pn_shift(5 downto 0) & pilot_scrambled;
    else -- Keep value.
      next_pn_shift <= pn_shift;
    end if;
  end process shift_comb_p;

  -- Registers.
  seq_pr : process (clk, reset_n)
  begin
    if reset_n = '0' then
      pn_shift       <= (others => '1');
      pilot_ready_ff <= '0';
    elsif clk'event and clk = '1' then
      if enable_i = '0' then
        pn_shift       <= (others => '1');
        pilot_ready_ff <= '0';
      else
        pn_shift       <= next_pn_shift;
        pilot_ready_ff <= pilot_ready_i;
      end if;
    end if;
  end process seq_pr;

end RTL;
