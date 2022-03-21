
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of mon_sto_cpe is

  constant PI_CT : std_logic_vector(nbit_sto_cpe_g-1 downto 0)
         := "00110010010001000";    -- pi 17 Bit , 13 Bit fraction

  constant TIMER_MAX_CT : std_logic_vector(3 downto 0) := "1100";
  constant TIMER_THR_CT : std_logic_vector(3 downto 0) := "1000";
  
  signal   timer_cpe    : std_logic_vector(3 downto 0);
  -- absolute value of cpe_i
  signal   abs_cpe      : std_logic_vector(nbit_sto_cpe_g-1 downto 0);

begin

  abs_cpe <= cpe_i when cpe_i(cpe_i'high) = '0' else
             not(cpe_i) + '1';
             
  mon_p : process (clk, reset_n)
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
      skip_cpe_o <= (others => '0');
      timer_cpe  <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if sync_reset_n = '0' then
        skip_cpe_o  <= (others => '0');
        timer_cpe   <= (others => '0');
      else
        if data_valid_i = '1' then
          if (abs_cpe > PI_CT) and (timer_cpe > TIMER_THR_CT) then
            timer_cpe   <= (others => '0');
            if cpe_i(cpe_i'high) = '0' then
              skip_cpe_o  <= "10"; -- PI will be substracted
            else
              skip_cpe_o  <= "01"; -- PI will be added
            end if;
            
          else
            
            skip_cpe_o  <= "00";
            if timer_cpe /= TIMER_MAX_CT then
              timer_cpe <= timer_cpe + '1';
            end if;
            
          end if;
        end if;
        
        if start_of_burst_i = '1' then
          skip_cpe_o <= (others => '0');
          timer_cpe  <= (others => '0');
        end if;
      end if;

    end if;
  end process mon_p;


end rtl;
