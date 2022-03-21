

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of bup2_intgen is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Internal signals for interrupt sources
  signal int_genirq_src   : std_logic; -- software interrupt.
  signal int_timewrap_src : std_logic; -- wrapping around of buptime.
  signal int_ccabusy_src  : std_logic; -- ccabusy.
  signal int_ccaidle_src  : std_logic; -- ccaidle.
  signal int_rxstart_src  : std_logic; -- rx packet start.
  signal int_rxend_src    : std_logic; -- rx packet end.
  signal int_txend_src    : std_logic; -- tx packet end.
  signal int_txstartirq_src  : std_logic; -- tx packet start.
  signal int_txstartfiq_src  : std_logic; -- tx packet start (fast interrupt).
  signal int_ackto_src    : std_logic; -- ACK packet time-out.
  -- Internal signal for absolute count interrupt sources
  signal int_abscnt_src      : std_logic_vector(num_abstimer_g-1 downto 0);
  signal int_abscntirq_src   : std_logic_vector(num_abstimer_g-1 downto 0);
  signal int_abscntfiq_src   : std_logic_vector(num_abstimer_g-1 downto 0);
  signal glob_abscntirq_src  : std_logic;
  signal glob_abscntfiq_src  : std_logic;
  -- Signals for IRQ and FIQ generation
  signal next_bup_irq     : std_logic;
  signal next_bup_fiq     : std_logic;
         
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- Assign interrupt source register outputs.
  reg_genirq_src   <= int_genirq_src  ;
  reg_timewrap_src <= int_timewrap_src;
  reg_ccabusy_src  <= int_ccabusy_src ;
  reg_ccaidle_src  <= int_ccaidle_src ;
  reg_rxstart_src  <= int_rxstart_src ;
  reg_rxend_src    <= int_rxend_src   ;
  reg_txend_src    <= int_txend_src   ;
  reg_txstartirq_src  <= int_txstartirq_src ;
  reg_txstartfiq_src  <= int_txstartfiq_src ;
  reg_ackto_src    <= int_ackto_src ;
  reg_abscntirq_src <= glob_abscntirq_src;
  reg_abscntfiq_src <= glob_abscntfiq_src;


  -- Assign absolute count interrupts source register outputs.
  abs_gen: for i in 0 to num_abstimer_g-1 generate
    reg_abscnt_src(i)   <= int_abscnt_src(i);

    abscnt_src_pr: process (clk, reset_n)
    begin
      if reset_n = '0' then
        int_abscnt_src(i)    <= '0';
      elsif clk'event and clk = '1' then
        -- Absolute count interrupt.
        if reg_abscnt_ack(i) = '1' then 
          int_abscnt_src(i)    <= '0';
        elsif (abscount_it(i) and reg_abscnt_en(i)) = '1' then
          int_abscnt_src(i)    <= '1';
        end if;
      end if;
    end process abscnt_src_pr;
    
    int_abscntirq_src(i) <= int_abscnt_src(i) and reg_abscnt_irqsel(i);
    int_abscntfiq_src(i) <= int_abscnt_src(i) and not(reg_abscnt_irqsel(i));

  end generate abs_gen;

  -- Generate global IRQ signal from absolute count interrupts
  glob_abscntirq_p: process(int_abscntirq_src)
    variable glob_abscntirq_src_v : std_logic;
  begin
    glob_abscntirq_src_v := '0';
    irq_loop: for i in 0 to num_abstimer_g-1 loop
      glob_abscntirq_src_v := glob_abscntirq_src_v or int_abscntirq_src(i);
    end loop irq_loop;
    glob_abscntirq_src <= glob_abscntirq_src_v;
  end process glob_abscntirq_p;
  
  -- Generate global fiq signal from absolute count interrupts
  glob_abscntfiq_p: process(int_abscntfiq_src)
    variable glob_abscntfiq_src_v : std_logic;
  begin
    glob_abscntfiq_src_v := '0';
    fiq_loop: for i in 0 to num_abstimer_g-1 loop
      glob_abscntfiq_src_v := glob_abscntfiq_src_v or int_abscntfiq_src(i);
    end loop fiq_loop;
    glob_abscntfiq_src <= glob_abscntfiq_src_v;
  end process glob_abscntfiq_p;
  

  -- Interrupt source generation process.
  -- If an interrupt input is active and the corresponding enable high, the
  -- interrupt source register is set. For some interrupts the interrupt time 
  -- tag registers is also set. Each interrupt source register bit is reset
  -- when the corresponding interrupt is acknowledged by software, or when the 
  -- BuP is disabled.
  int_src_pr: process (clk, reset_n)
  begin
    if reset_n = '0' then
      -- Reset interrupt sources.
      int_genirq_src    <= '0';
      int_timewrap_src  <= '0';
      int_ccabusy_src   <= '0';
      int_ccaidle_src   <= '0';
      int_rxstart_src   <= '0';
      int_rxend_src     <= '0';
      int_txend_src     <= '0';
      int_txstartirq_src <= '0';
      int_txstartfiq_src <= '0';
      int_ackto_src     <= '0';
      -- Reset interrupt time tag.
      reg_inttime       <= (others => '0');

    elsif clk'event and clk = '1' then

      -- Software interrupt.
      if reg_genirq_ack = '1' then 
        int_genirq_src    <= '0';
      elsif sw_irq = '1' then
        int_genirq_src    <= '1';
      end if;
      
      -- Wrapping around of BupTime.
      if reg_timewrap_ack = '1' then 
        int_timewrap_src  <= '0';
      elsif (timewrap and reg_timewrap_en) = '1' then
        int_timewrap_src  <= '1';
      end if;
      
      -- Interrupt on cca busy.
      if reg_ccabusy_ack = '1' then 
        int_ccabusy_src  <= '0';
      elsif (ccabusy_it and reg_ccabusy_en) = '1' then
        int_ccabusy_src  <= '1';
        reg_inttime      <= reg_buptime;         
      end if;

      -- Interrupt on cca idle.
      if reg_ccaidle_ack = '1' then 
        int_ccaidle_src  <= '0';
      elsif (ccaidle_it and reg_ccaidle_en) = '1' then
        int_ccaidle_src  <= '1';
        reg_inttime      <= reg_buptime;         
      end if;

      -- Interrupt on reception start.
      if reg_rxstart_ack = '1' then 
        int_rxstart_src  <= '0';
      elsif (rxstart_it and reg_rxstart_en) = '1' then
        int_rxstart_src  <= '1';
      end if;
      -- update inttime if rxstart it occurs and rxend OR rxstart it is enabled
      if (rxstart_it and (reg_rxend_en or reg_rxstart_en )) = '1' then
        reg_inttime      <= reg_buptime;         
      end if;
      
      -- Interrupt on reception end or error.
      if reg_rxend_ack = '1' then 
        int_rxend_src     <= '0';
      elsif (rxend_it and reg_rxend_en) = '1' then
        int_rxend_src   <= '1';
      end if;
        
      -- Interrupt on transmission start.
      if reg_txstartirq_ack = '1' then 
        int_txstartirq_src  <= '0';
      elsif (txstart_it and reg_txstartirq_en) = '1' then
        int_txstartirq_src  <= '1';
        reg_inttime         <= reg_buptime;         
      end if;

      -- Fast interrupt on transmission start.
      if reg_txstartfiq_ack = '1' then 
        int_txstartfiq_src  <= '0';
      elsif (txstart_it and reg_txstartfiq_en) = '1' then
        int_txstartfiq_src  <= '1';
        reg_inttime         <= reg_buptime;         
      end if;

      -- Interrupt on transmission end.
      if reg_txend_ack = '1' then 
        int_txend_src  <= '0';
      elsif (txend_it and reg_txend_en) = '1' then
        int_txend_src  <= '1';
        reg_inttime    <= reg_buptime;         
      end if;
        
      -- Interrupt on ACK packet time-out.
      if reg_ackto_ack = '1' then 
        int_ackto_src  <= '0';
      elsif (ackto_it and reg_ackto_en) = '1' then
        int_ackto_src  <= '1';
      end if;
        
        
    end if;
  end process int_src_pr;
  
  
  --------------------------------------------
  -- Interrupts generation.
  --------------------------------------------

  -- All interrupt sources generate an IRQ, except reception of a packet, 
  -- absolute timer interrupt and the tx_start interrupt when txstartfiq_en
  -- is set.
  next_bup_irq <= int_genirq_src or int_timewrap_src or glob_abscntirq_src 
               or int_ccabusy_src or int_ccaidle_src or int_rxstart_src
               or int_txend_src or int_txstartirq_src;

  next_bup_fiq <= int_txstartfiq_src or glob_abscntfiq_src or int_rxend_src
               or int_ackto_src;
  
  
  interrupt_seq_pr: process (clk, reset_n)
  begin
    if reset_n = '0' then
      bup_irq <= '0';
      bup_fiq <= '0';
    elsif clk'event and clk = '1' then
      bup_irq <= next_bup_irq;
      bup_fiq <= next_bup_fiq;
    end if;
  end process interrupt_seq_pr;
  
  
  
end RTL;
