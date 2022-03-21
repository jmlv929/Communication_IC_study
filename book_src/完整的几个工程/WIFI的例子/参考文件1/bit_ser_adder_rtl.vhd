

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------


architecture rtl of bit_ser_adder is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal c_in_reg : std_logic;
  signal c_out    : std_logic;
  
begin  -- rtl

  fa_0 : fa
    port map (
      x     => x_in,
      y     => y_in,
      c_in  => c_in_reg,
      s     => sum_out,
      c_out => c_out);
  
  carry_reg: process (clk, reset_n)
  begin  -- process carry_reg
    if reset_n = '0' then               -- asynchronous reset (active low)
      c_in_reg <= '0';  
    elsif clk'event and clk = '1' then  -- rising clock edge

      if sync_reset = '1' then
        c_in_reg <= '0';
      else
        c_in_reg <= c_out;    
      end if;

    end if;
  end process carry_reg;

end rtl;
