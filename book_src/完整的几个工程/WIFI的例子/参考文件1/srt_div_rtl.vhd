
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of srt_div is


  constant NULL_CT : std_logic_vector(nbit_quotient_g-1 downto 0) := 
              (others => '0');
  
  signal step            : integer range nbit_quotient_g+3 downto 0;

begin

  --------------------------------------------
  -- This process counts the processing steps of
  -- the SRT algorithm
  --------------------------------------------
  step_p : process (clk, reset_n)
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
      step   <= nbit_quotient_g+3;
    elsif clk'event and clk = '1' then  -- rising clock edge
      if start = '1'   then
        step <= 0;
      end if;
      if step <= nbit_quotient_g+2 then
        step  <= step + 1;
      end if;
    end if;
  end process step_p;

  --------------------------------------------
  -- SRT algorithm
  --------------------------------------------
  srt_p : process (clk, reset_n)
    variable p_remind         : std_logic_vector(nbit_input_g-1 downto 0);  -- partial remainder at j
    variable partial_quotient : std_logic_vector(nbit_quotient_g downto 0);
    variable quotient_buf     : std_logic_vector(nbit_quotient_g downto 0);
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
      p_remind         := (others => '0');
      quotient_buf     := (others => '0');
      partial_quotient := (others => '0');
      quotient         <= (others => '0');
      value_ready      <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      value_ready      <= '0';
      if step = 0 then                  -- initial step
        p_remind                                     := dividend;
        quotient_buf                                 := (others => '0');
        partial_quotient(nbit_quotient_g)            := '1';
        partial_quotient(nbit_quotient_g-1 downto 0) := NULL_CT;
      elsif step <= (nbit_quotient_g+1) then
        -- compute next quotient digit
        if p_remind(p_remind'high downto p_remind'high-1) = "01" then  -- pr >= 0.5
          -- compute next partial remainder
          p_remind := p_remind - divisor;
          p_remind := SHL(p_remind, "01");
          -- compute quotient
          quotient_buf:= quotient_buf + partial_quotient;
        elsif p_remind(p_remind'high downto p_remind'high-1) = "10" then -- pr < -0.5
          -- compute next partial remainder
          p_remind := p_remind + divisor;
          p_remind := SHL(p_remind, "01");
          -- compute quotient
          quotient_buf:= quotient_buf - partial_quotient;
        else
          -- compute next partial remainder
          p_remind   := SHL(p_remind, "01");
        end if;

        -- shift partial quotient
        partial_quotient := SHR(partial_quotient, "01");

      end if;
      if step = nbit_quotient_g+1 then
        if p_remind(p_remind'high) = '1' then -- final reminder is < 0
          quotient_buf := quotient_buf - '1';
          quotient     <= quotient_buf(quotient_buf'high downto 1);
        else
          quotient     <= quotient_buf(quotient_buf'high downto 1);
        end if;
        
        -- SRT quotient is available
        value_ready <= '1';
      end if;
    end if;
  end process srt_p;

end rtl;
