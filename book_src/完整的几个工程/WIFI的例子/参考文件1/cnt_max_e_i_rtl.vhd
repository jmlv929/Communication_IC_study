

--------------------------------------------------------------------------------
-- architecture
--------------------------------------------------------------------------------
architecture rtl of cnt_max_e_i is

  signal q_o   : std_logic_vector(depth_g-1 downto 0);

begin
  
  q <= q_o;
  termint <= '1' when q_o = maxval else '0';

  cnt : process(reset_n, clk)
  begin
    if (reset_n = '0') then
      q_o <= (others => '0');

    elsif (clk'event and clk = '1') then
      if (enable = '1') then
        if (q_o = maxval) then
          q_o <= (others => '0');
        else
          q_o <= q_o + '1';
        end if;
      end if;
    end if;
  end process cnt;

end rtl;
