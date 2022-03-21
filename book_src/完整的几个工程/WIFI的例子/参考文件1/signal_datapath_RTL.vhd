

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of signal_datapath is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal signal_field : std_logic_vector (SIGNAL_FIELD_LENGTH_CT-1 downto 0);


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  --------------------------------------
  -- Data valid process
  --------------------------------------
  datavalid_sequential_p : process (clk, reset_n)
  begin
    if (reset_n = '0') then                 -- asynchronous reset (active low)
      signal_field  <= (others => '0');

    elsif (clk = '1') and (clk'event) then  -- rising clock edge

      if sync_reset_n = '0' then            -- synchronous reset (active low)
        signal_field  <= (others => '0');
      elsif enable_i = '1' then             -- enable condition (active high)
        signal_field <= data_i & 
                                signal_field(SIGNAL_FIELD_LENGTH_CT-1 downto 1);
      end if;

    end if;
  end process datavalid_sequential_p;

  output_signal_field : signal_field_o <= signal_field;
  
end RTL;
