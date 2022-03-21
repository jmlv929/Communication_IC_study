
--------------------------------------------------------------------------------
-- architecture
--------------------------------------------------------------------------------
architecture rtl of cnt_sr_e_i is

  constant ALL_ONE_CT : std_logic_vector(depth_g-1 downto 0) := (others => '1');
  signal q_o   : std_logic_vector(depth_g-1 downto 0);
  
begin

  q <= q_o;
  termint <= '1' when q_o = ALL_ONE_CT else '0';

  cnt : process(clk, reset_n)
  begin
    if (reset_n = '0') then
      q_o <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (sreset = '1') then
        q_o <= (others => '0');
      elsif (enable = '1') then
        q_o <= q_o +  '1';
      end if;
    end if;
  end process cnt;

end rtl;
