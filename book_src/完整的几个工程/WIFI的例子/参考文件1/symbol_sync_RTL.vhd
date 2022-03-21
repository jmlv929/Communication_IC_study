

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of symbol_sync is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  --------------------------------------------
  -- Sample process.
  --------------------------------------------
  -- This process samples the Barker correlator peak output when the symbol_sync
  -- signal is received.
  sampl_pr: process (reset_n, clk)
  begin
    if reset_n = '0' then
      data_i <= (others => '0');
      data_q <= (others => '0');
    elsif clk'event and clk = '1' then
      if symbol_sync = '1' then
        data_i <= corr_i;
        data_q <= corr_q;
      end if;
    end if;
  end process sampl_pr;

end RTL;
