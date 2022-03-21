
--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of dec_sr_e_i is

  constant ALL_ZERO_CT  : std_logic_vector(depth_g-1 downto 0) := (others => '0');
  constant ALL_ONE_CT   : std_logic_vector(depth_g-1 downto 0) := (others => '1');
  signal q_o            : std_logic_vector(depth_g-1 downto 0);

begin
  
  q <= q_o;
  termint <= '1' when q_o = ALL_ZERO_CT else '0';

  cnt : process(reset_n, clk)
  begin
    if (reset_n = '0') then
      q_o <= (others => '0');

    elsif (clk'event and clk = '1') then
      if (sreset = '1') then
        q_o <= ALL_ZERO_CT;
      elsif (enable = '1') then
        if (q_o /= ALL_ZERO_CT) then
          q_o <= q_o + ALL_ONE_CT; -- counter - 1
        else
          q_o <= maxval;
        end if;
      end if;
    end if;
  end process cnt;

end rtl;
