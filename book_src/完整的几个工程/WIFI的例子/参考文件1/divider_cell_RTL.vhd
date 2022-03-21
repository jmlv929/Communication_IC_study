

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of divider_cell is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal substr : std_logic_vector(dsize_g downto 0);


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  substr_pr: process(z_in, d_in)
    variable d_in_v : std_logic_vector(dsize_g downto 0);
  begin
    d_in_v := '0' & d_in;
    substr <= z_in - d_in_v;
  end process substr_pr;
  
  with substr(substr'high) select
    s_out <=
      z_in   when '1',
      substr when others;

  q_out <= not(substr(substr'high));

end RTL;
