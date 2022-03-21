
--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of fa is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal c_0, c_1, s_0 : std_logic;
  
begin  -- rtl

  ha_0 : ha
    port map (
      x => x,
      y => y,
      c => c_0,
      s => s_0);
     
  ha_1 : ha
    port map (
      x => s_0,
      y => c_in,
      c => c_1,
      s => s);

  c_out <= c_0 or c_1;

end rtl;
