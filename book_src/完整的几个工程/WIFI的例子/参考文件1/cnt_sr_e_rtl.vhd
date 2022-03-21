

--------------------------------------------------------------------------------
-- architecture
--------------------------------------------------------------------------------
architecture rtl of cnt_sr_e is

  signal q_o   : std_logic_vector(depth_g-1 downto 0);
  
begin

  q <= q_o;
  
  cnt : process(reset_n, clk)
  begin
    if (reset_n = '0') then
      q_o <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (sreset = '1') then
        q_o <= (others => '0');
      elsif (enable = '1') then
        q_o <= q_o + '1';
      end if;
    end if;
  end process cnt;

end rtl;
