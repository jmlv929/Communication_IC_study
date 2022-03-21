

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of abscnt_timers is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type ARRAY_SLV26 is array (natural range <>) of std_logic_vector(25 downto 0);

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal absolute_count     : std_logic_vector(num_abstimer_g-1 downto 0);
  signal absolute_count_ff1 : std_logic_vector(num_abstimer_g-1 downto 0);
  signal abstime_arr        : ARRAY_SLV26(15 downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  ------------------------------------------------------------------------------
  -- inputs and outputs
  ------------------------------------------------------------------------------
  abstime_arr(0 ) <= abstime0; 
  abstime_arr(1 ) <= abstime1; 
  abstime_arr(2 ) <= abstime2; 
  abstime_arr(3 ) <= abstime3; 
  abstime_arr(4 ) <= abstime4; 
  abstime_arr(5 ) <= abstime5; 
  abstime_arr(6 ) <= abstime6; 
  abstime_arr(7 ) <= abstime7; 
  abstime_arr(8 ) <= abstime8; 
  abstime_arr(9 ) <= abstime9; 
  abstime_arr(10) <= abstime10;
  abstime_arr(11) <= abstime11;
  abstime_arr(12) <= abstime12;
  abstime_arr(13) <= abstime13;
  abstime_arr(14) <= abstime14;
  abstime_arr(15) <= abstime15;

  ------------------------------------------------------------------------------
  -- Absolute counters.
  ------------------------------------------------------------------------------
  abscnt_gen: for i in 0 to num_abstimer_g-1 generate

    -- Comparator to detect when the BuP timer reaches the absolute counter
    -- time tag.
    absolute_count(i) <= '1' when (bup_timer = abstime_arr(i) and mode32k = '0')
      else '1' when (bup_timer(25 downto 5) = abstime_arr(i)(25 downto 5) and mode32k = '1')
      else '0';

    -- Delay absolute_count to generate a pulse of one pclk clock-cycle.
    abscount_it_p: process (clk, reset_n)
    begin
      if (reset_n = '0') then
        absolute_count_ff1(i) <= '0';
      elsif clk'event and clk = '1' then
        absolute_count_ff1(i) <= absolute_count(i);
      end if;
    end process abscount_it_p;
    abscount_it(i) <= absolute_count(i) and not absolute_count_ff1(i);

  end generate abscnt_gen;

end RTL;
