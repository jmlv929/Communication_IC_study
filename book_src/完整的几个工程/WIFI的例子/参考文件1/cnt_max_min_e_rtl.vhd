

--------------------------------------------------------------------------------
-- aRcHITecTURe decLaRaTION
--------------------------------------------------------------------------------
architecture rtl of cnt_max_min_e is


--------------------------------------------------------------------------------
-- SIGNaL decLaRaTION
--------------------------------------------------------------------------------
  signal q_o : std_logic_vector(depth_g-1 downto 0);


begin
--------------------------------------------------------------------------------
-- cONcURReNT aSSIGNMeNTS
--------------------------------------------------------------------------------

q <= q_o;
--------------------------------------------------------------------------------
-- PROceSSeS
--------------------------------------------------------------------------------

cnt : process (clk, reset_n, minval)
begin
  if reset_n = '0' then
    q_o <= (others => '0');
  elsif(clk'event and clk = '1') then
    if q_o < minval then
      q_o <= minval;
    elsif enable = '1' then
      if q_o < maxval then
        q_o <= q_o +1;
      else
        q_o <= minval;
      end if;
    end if;
  end if;
end process cnt;


end rtl;
