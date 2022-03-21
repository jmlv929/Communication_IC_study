

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of peak_detect is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- Constants for synopsys
  constant ACCU_PLUS1_CT : integer := accu_size_g+1;
  constant ACCU_PLUS2_CT : integer := accu_size_g+2;
  -- This value is used to count up to 43. (44 MHz -> 1MHz)
  constant COUNT_DSSS_CT  : std_logic_vector(5 downto 0) := "101011";
  -- This value is used to count up to 31. (44 MHz -> 1.375MHz)
  constant COUNT_CCK_CT   : std_logic_vector(5 downto 0) := "011111";
  -- This value is used as the symbol cyclic synchronization signal.
  constant SYNC_SYMBOL_CT : std_logic_vector(5 downto 0) := "000000";
  
  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type ArrayOfSLV is array (natural range <>) of 
                                     std_logic_vector(accu_size_g-1 downto 0);

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Truncate correlator square module.
  signal abs_2_corr_trunc : std_logic_vector(13 downto 0);
  -- Signals for the three max values in the register bank.
  signal max_value1       : std_logic_vector(accu_size_g-1 downto 0);
  -- Index corresponding to the max value.
  signal max_index        : std_logic_vector(4 downto 0);
  -- Synchronization index, i.e. max index over a symbol.
  signal synch_index      : std_logic_vector(4 downto 0);
  -- This signal indicates when synch_index has been updated for CCK modulation.
  signal update_sync      : std_logic;
  -- Accumulator bank of registers.
  signal accu_bank        : ArrayOfSLV(21 downto 0);
  -- Register bank input value.
  signal accu_add         : std_logic_vector(accu_size_g-1 downto 0);
  -- Detect overflow in accumulated values.
  signal accu_ov          : std_logic;
  signal accu_ov_mem      : std_logic;
  -- Signals for the symbol counter (counts 1 MHz in DSSS, 1.375 MHz in CCK).
  signal symbol_count     : std_logic_vector(5 downto 0);
  signal count_end        : std_logic_vector(5 downto 0); -- counter max value.
  signal symbol_sync_int  : std_logic; -- Internal symbol synchronization.
  signal mod_change       : std_logic; -- Indicates when mod_type is taken into account.

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
--  accu_add_tglobal(31 downto accu_size_g)    <= (others => '0');
--  accu_add_tglobal(accu_size_g-1 downto 0)   <= accu_add(accu_size_g-1 downto 0);
--  max_value1_tglobal(31 downto accu_size_g)  <= (others => '0');
--  max_value1_tglobal(accu_size_g-1 downto 0) <= max_value1(accu_size_g-1 downto 0);
--  synch_index_tglobal                        <= synch_index;
--  abs_2_corr_trunc_tglobal                   <= abs_2_corr_trunc;
--  symbol_sync_tglobal                        <= symbol_sync_int;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on

  -- Barker correlator is resynchronized on 22 MHz edge not used in this block.
  barker_sync <= symbol_count(0);

  -- The abs_2_corr value (square module of the correlator complex output) must
  -- be truncated to the closest value. This way the error is not always
  -- positive.
  truncate_pr: process(abs_2_corr)
  begin
    case abs_2_corr(1) is
      when '0' => 
        abs_2_corr_trunc <= abs_2_corr(15 downto 2);
      when others =>
        abs_2_corr_trunc <= abs_2_corr(15 downto 2) + '1';
    end case;
  end process truncate_pr;

  -- Accumulator bank input value.
  -- Seven values must be accumulated without overflow.
  accu_add <= accu_bank(21) + abs_2_corr_trunc;
  -- Detect overflow not yet processed.
  accu_ov  <= '1' when ( (accu_add(accu_size_g-1 downto accu_size_g-2) /= "00")
                     and (accu_ov_mem = '0') )
    else '0';
  
  -- Memorize overflow to process it.
  overflow_mem_p: process (reset_n, clk)
  begin
    if reset_n = '0' then
      accu_ov_mem <= '0';
    elsif clk'event and clk = '1' then
      if accu_resetn = '0' then -- Reset the accumulator.
        accu_ov_mem <= '0';

      elsif symbol_count(0) = '0' and synchro_en = '1' then -- 22 MHz signal.
        accu_ov_mem <= accu_ov;
      end if; 
    end if;
  end process overflow_mem_p;
  
  
  --------------------------------------------
  -- Register bank update process.
  --------------------------------------------
  -- This process accumulates the absolute values in a shift register bank.
  shift_accu_pr: process (reset_n, clk)
    variable init_loop_step_v  : integer;
    variable reset_loop_step_v : integer;
    variable div_loop_step_v   : integer;
  begin
    if reset_n = '0' then
      
      -- Reset accumulator bank.
      init_loop: for init_loop_step_v in accu_bank'high downto accu_bank'low loop
        accu_bank(init_loop_step_v) <= (others => '0');
      end loop init_loop;

    elsif clk'event and clk = '1' then

      if accu_resetn = '0' then -- Reset the accumulator.
        -- Reset accumulator bank.
        reset_loop: for reset_loop_step_v in accu_bank'high downto accu_bank'low loop
          accu_bank(reset_loop_step_v) <= (others => '0');
        end loop reset_loop;
      
      elsif symbol_count(0) = '0' and synchro_en = '1' then -- 22 MHz signal.
        -- Shift the accumulator bank.
        if accu_ov_mem = '1' then -- Overflow detected, divide accu values.
          div_loop: for div_loop_step_v in 20 downto 0 loop
            accu_bank(div_loop_step_v+1) <= '0' & accu_bank(div_loop_step_v)(accu_size_g-1 downto 1);
          end loop div_loop;
          accu_bank(0) <= '0' & accu_add(accu_size_g-1 downto 1);
        else
          -- Left shift of accumulator register bank.
          accu_bank(21 downto 1) <= accu_bank(20 downto 0);
          -- Store new input value.
          accu_bank(0) <= accu_add;
        end if;

      end if; -- 22 MHz.
      
    end if;
  end process shift_accu_pr;
  

  --------------------------------------------
  -- Peak detection process.
  --------------------------------------------
  -- This process detects the three maximum accumulated values over a symbol
  -- period. The synchronization is done on SYNC_SYMBOL_CT, as for the
  -- index.
  max_detect_pr: process (reset_n, clk)
  begin
    if reset_n = '0' then
      -- Reset max values.
      max_value1  <= (others => '0'); 
      -- Reset max index.
      max_index   <= (others => '0'); 
    elsif clk'event and clk = '1' then

      if accu_resetn = '0' then -- Reset the accumulator.
        -- Reset max values.
        max_value1  <= (others => '0'); 
        -- Reset max index.
        max_index   <= (others => '0'); 
        
      -- Reset max values every Symbol period. At the same time, max_value1 is
      -- updated with the current accu bank input (first max value of the next
      -- period).
      elsif (symbol_count = SYNC_SYMBOL_CT) then
        if (accu_ov_mem = '1') then
          max_value1  <= '0' & accu_add(accu_size_g-1 downto 1);
        else  
          max_value1  <= accu_add; 
        end if;
        -- Reset max index.
        max_index   <= (others => '0'); 

      elsif ( (symbol_count(0) = '0') and (synchro_en = '1') ) then  -- 22 MHz.

        -- The data input to the register bank is compared to the three max
        -- values. If it is greater than one of those, it is inserted in the
        -- corresponding register and the others max values or reordered.
        -- 
        --  new value range| < max3 | [max3, max2[ | [max2, max1[ | >= max1
        --  --------------------------------------------------------------- 
        --     next_max1   |  max1  |     max1     |     max1     |   new 
        --     next_max2   |  max2  |     max2     |     new      |   max1
        --     next_max3   |  max3  |     new      |     max2     |   max2

        -- If the data takes the same value twice, keep the last index (use >=).
        if (accu_add >= max_value1) then          -- Max of maxima detected.
          max_index <= symbol_count(5 downto 1);  -- Load new index.
          -- An overflow is detected, the max values are divided.
          if (accu_ov_mem = '1') then
            max_value1 <= '0' & accu_add(accu_size_g-1 downto 1);
          else                                    -- No overflow,
            max_value1 <= accu_add;               -- Load new max values.
          end if;
          
        else                            -- No maximum detected.
          if (accu_ov_mem = '1') then
            max_value1 <= '0' & max_value1(accu_size_g-1 downto 1);
          end if;
        end if;
      end if;  -- 22 MHz.

    end if;
  end process max_detect_pr;


 

  -- Keep max index over a symbol.
  -- When timing synchronization is disabled, freeze synch_index.
  sync_index_pr: process (reset_n, clk)
  begin
    if reset_n = '0' then
      synch_index <= (others => '0');
      update_sync <= '0';
      
    elsif clk'event and clk = '1' then
      if accu_resetn = '0' then -- Reset the accumulator.
        synch_index     <= (others => '0');
        update_sync     <= '0';
      
      elsif synchro_en = '1' then -- Timing synchronization enabled.
        update_sync <= '0';
        if symbol_count = SYNC_SYMBOL_CT then -- Symbol period over.
          synch_index     <= max_index;       -- Store max index over period.
        end if;
      elsif mod_change = '1' then -- Change from DSSS to CCK modulation.
        synch_index <= COUNT_CCK_CT(5 downto 1);
        update_sync <= '1';
      end if;
    end if;
  end process sync_index_pr;

  -- Send peak synchronization signal at time detected in synch_index.
  sync_pr: process (reset_n, clk)
  begin
    if reset_n = '0' then
      symbol_sync_int <= '0';
    elsif clk'event and clk = '1' then
      if accu_resetn = '0' then -- Reset the accumulator.
        symbol_sync_int <= '0';

      elsif (synch_index & '0') = symbol_count then
        symbol_sync_int <= '1';
      else
        symbol_sync_int <= '0';      
      end if;
    end if;
  end process sync_pr;
  
  symbol_sync <= symbol_sync_int;

  mod_change <= symbol_sync_int and mod_type and not(update_sync);
  

  --------------------------------------------
  -- Counter process.
  --------------------------------------------
  -- This counter is used to obtain from the 44 Mhz clock:
  --   a 1 Mhz sampling in DSSS mode (counts up to 43)
  --   a 1.375 Mhz sampling in CCK mode (counts up to 31).
  symbol_count_pr: process (clk, reset_n)                              
  begin                                                              
    if reset_n = '0' then
      symbol_count  <= (others => '1');
      count_end     <= COUNT_DSSS_CT;
      
    elsif clk'event and clk = '1' then
      if accu_resetn = '0' then -- Reset the accumulator.
        symbol_count  <= (others => '1');
        count_end     <= COUNT_DSSS_CT;
      else

        -- Timing synchronization is enabled during the preamble (DSSS modulation)
        if synchro_en = '1' then
          count_end  <= COUNT_DSSS_CT;
        end if;

        -- Symbol counter operation.
        if mod_change = '1' then -- When mod_type changes for CCK, reset counter.
          count_end    <= COUNT_CCK_CT;
          symbol_count <= "000000";
        elsif symbol_count = count_end then -- Count up to 31 or 43
          symbol_count <= (others => '0');
        else  
          symbol_count <= symbol_count + '1';
        end if;
      
      end if; -- End of synchronous reset.
    end if;                                                          
  end process symbol_count_pr; 

  
end RTL;
