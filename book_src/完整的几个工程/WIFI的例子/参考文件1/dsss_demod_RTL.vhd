

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of dsss_demod is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant BARKER_SEQ_CT : std_logic_vector (10 downto 0)  
                        := "01001000111"; -- (right bit first)
                        -- +1-1+1+1-1+1+1+1-1-1-1   (802.11 b spec)
                        
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Internal barker register.
  signal barker_int        : std_logic_vector(10 downto 0);
  -- Signals for accumulator of complex input values.
  signal accu_i            : std_logic_vector(dsize_g+3 downto 0);
  signal accu_q            : std_logic_vector(dsize_g+3 downto 0);
  -- This counter is used to obtain a 11 Mhz sampling from the 44 Mhz clock.
  signal count_11mhz       : std_logic_vector(1 downto 0);  

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  ------------------------------------------------------------------------------
  -- Global Signals for test (probe intrenal signals for Matlab bit-true checks)
  ------------------------------------------------------------------------------
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off
  -- Values sent to the testbench for probing.
--  accu_i_tglobal(31 downto dsize_g+4) <= (others => '0');
--  accu_i_tglobal(dsize_g+3 downto 0)  <= accu_i;
--  accu_q_tglobal(31 downto dsize_g+4) <= (others => '0');
--  accu_q_tglobal(dsize_g+3 downto 0)  <= accu_q;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on

  --------------------------------------------
  -- Demodulation process.
  --------------------------------------------
  -- The input values sampled at a 11 Mhz rate are correlated with the Barker
  -- sequence and accumulated.
  -- The accumulator is reset at each synchronization signal.
  accu_pr: process (reset_n, clk)
    variable barker_xi_v  : std_logic_vector(dsize_g+3 downto 0);
    variable barker_xq_v  : std_logic_vector(dsize_g+3 downto 0);
  begin
    if reset_n = '0' then
      barker_xi_v := (others => '0');
      barker_xq_v := (others => '0');

      barker_int  <= BARKER_SEQ_CT;   -- Load Barker sequence.
      accu_i      <= (others => '0'); -- Reset accumulator.
      accu_q      <= (others => '0');
      
    elsif clk'event and clk = '1' then

      if symbol_sync = '1' then         -- Synchronization signal received:

        barker_int  <= BARKER_SEQ_CT;   -- Load Barker sequence,
        accu_i      <= (others => '0'); -- Reset accumulator.
        accu_q      <= (others => '0');
        
      elsif count_11mhz = "00" then    -- New input value to accumulate.
        -- Rotative shift of barker sequence.
        barker_int <= barker_int(9 downto 0) & barker_int (10);

        -- Choose value to accumulate.
        case barker_int (10) is
          when '0' =>     -- '0' means '+1'.
            barker_xi_v := sxt(x_i, dsize_g+4);
            barker_xq_v := sxt(x_q, dsize_g+4);
          when others =>  -- '1' means '-1'.
            barker_xi_v := not(sxt(x_i, dsize_g+4)) + '1';
            barker_xq_v := not(sxt(x_q, dsize_g+4)) + '1';
        end case;
        
        accu_i <= accu_i + barker_xi_v;
        accu_q <= accu_q + barker_xq_v;
              
      end if;
    end if;
  end process accu_pr;


  -- Drive output line when 1 MHz synchronization received.
  demod_out_pr: process (reset_n, clk)
  begin
    if reset_n = '0' then
      demod_i    <= (others => '0');
      demod_q    <= (others => '0');
    elsif clk'event and clk = '1' then
      if symbol_sync = '1' then  -- Synchronization signal received:
        demod_i     <= accu_i;   -- Drive output lines.
        demod_q     <= accu_q;
      end if;
    end if;
  end process demod_out_pr;


  --------------------------------------------
  -- Counter process.
  --------------------------------------------
  -- This counter is used to obtain a 11 Mhz sampling from the 44 Mhz clock.
  -- It is reset with the synchronization signal and used to sample the inputs
  -- and shift the Barker sequence.
  count_11mhz_pr: process (clk, reset_n)                              
  begin                                                              
    if reset_n = '0' then
      count_11mhz <= (others => '0');
 
    elsif clk'event and clk = '1' then

      if symbol_sync = '1' then            -- Synchronization signal,
        count_11mhz <= (others => '0');    -- Reset counter.
      else                            -- Count wraps over every 4 clock cycles.
        count_11mhz <= count_11mhz + "01";
      end if;

    end if;                                                          
  end process count_11mhz_pr; 
  

end RTL;
