

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of data_datapath is


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  --------------------------------------
  -- Delay data process
  --------------------------------------
  delay_data_p : process (clk, reset_n)
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
      data_o  <= '0';
    elsif clk = '1' and clk'event then  -- rising clock edge
      if enable_i = '1' then            --  enable condition (active high)
        data_o <= data_i;
      end if;
    end if;
  end process delay_data_p;

end RTL;
