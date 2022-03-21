

--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of sp_registers is

----------------------------------------------------------- Constant declaration
-- These constants define the addresses of the internal registers.
constant STRPVERS_ADDR_CT     : std_logic_vector( 2 downto 0) := "000";-- 00'H
constant STRPCNTL_ADDR_CT     : std_logic_vector( 2 downto 0) := "001";-- 04'H
constant STRPCSTRUCT0_ADDR_CT : std_logic_vector( 2 downto 0) := "010";-- 08'H
constant STRPCSTRUCT1_ADDR_CT : std_logic_vector( 2 downto 0) := "011";-- 0C'H
constant STRPINTMASK_ADDR_CT  : std_logic_vector( 2 downto 0) := "100";-- 10'H
constant STRPINTACK_ADDR_CT   : std_logic_vector( 2 downto 0) := "101";-- 14'H
constant STRPSTAT_ADDR_CT     : std_logic_vector( 2 downto 0) := "110";-- 18'H

constant STRP_BUILD_CT     : std_logic_vector(15 downto 0)
                           := "0000000000000000"; -- d'0
constant STRP_RELEASE_CT   : std_logic_vector( 7 downto 0) := "00000010"; -- d'2
constant STRP_UPGRADE_CT   : std_logic_vector( 7 downto 0) := "00000001"; --d'0

--------------------------------------------------- End of Constant declaration

------------------------------------------------------------- Signal declaration
signal last_cs         : std_logic; -- Indicates which cs was processed last.
signal select_cs0      : std_logic; -- Use control structure 0 when high.
-- Internal Registers.
signal int_comply_d6_d4n:std_logic; -- Low for MIC IV compliancy with D4.0.
signal int_crc_debug   : std_logic; -- Enable CRC written to control structure.
signal int_startop1    : std_logic; -- Start operation for control struct 1.
signal int_startop0    : std_logic; -- Start operation for control struct 0.
-- This signals reset the memorized 'startop' once it is taken into account.
signal reset_startop0  : std_logic; -- Reset after control structure 0 started.
signal reset_startop1  : std_logic; -- Reset after control structure 1 started.
signal int_cstruct0    : std_logic_vector(31 downto 0); -- Pointer to CS0.
signal int_cstruct1    : std_logic_vector(31 downto 0); -- Pointer to CS1.
signal int_strpcsaddr  : std_logic_vector(31 downto 0); -- Pointer to CS in use.
-- Siagnls for interrupts.
signal process_done_ff : std_logic; -- Process_done delayed in 1 clk.
signal done_pulse      : std_logic; -- Pulse indicating processing is over.
signal int_intmask1    : std_logic; -- Mask interrupt from control struct 1.
signal int_intmask0    : std_logic; -- Mask interrupt from control struct 0.
signal int_intack1     : std_logic; -- Acknowledge interrupt from cstruct 1.
signal int_intack0     : std_logic; -- Acknowledge interrupt from cstruct 0.
signal interrupt0      : std_logic; -- Stream Processor interrupt from CS0.
signal interrupt1      : std_logic; -- Stream Processor interrupt from CS1.
-- Status register.
signal int_micerr1     : std_logic; -- MIC error during CS1 processing.
signal int_flowerr1    : std_logic; -- AHB error during CS1 processing.
signal int_crcerr1     : std_logic; -- CRC error during CS1 processing.
signal int_micerr0     : std_logic; -- MIC error during CS0 processing.
signal int_flowerr0    : std_logic; -- AHB error during CS0 processing.
signal int_crcerr0     : std_logic; -- CRC error during CS0 processing.
-- Interrupts received.
signal crcerr1         : std_logic; -- CRC interrupt from CS1.
signal micerr1         : std_logic; -- MIC interrupt from CS1.
signal dataflowerr1    : std_logic; -- AHB interrupt from CS1.
signal crcerr0         : std_logic; -- CRC interrupt from CS0.
signal micerr0         : std_logic; -- MIC interrupt from CS0.
signal dataflowerr0    : std_logic; -- AHB interrupt from CS0.
-- Combinational signal for prdata bus.
signal next_prdata     : std_logic_vector(31 downto 0);
------------------------------------------------------ End of Signal declaration

begin
  
  -- Diagnostic port.
  reg_diag(7 downto 3) <= (others => '0');
  reg_diag(2 downto 0) <= select_cs0 & int_startop1 & int_startop0;

  int_strpcsaddr <= int_cstruct0 when select_cs0 = '1' else int_cstruct1;
  strpcsaddr     <= int_strpcsaddr;
  crc_debug      <= int_crc_debug;
  comply_d6_d4n  <= int_comply_d6_d4n;

  strpkaddr(31 downto 2) <= int_strpcsaddr(31 downto 2) + 10;
  strpkaddr(1 downto 0)  <= int_strpcsaddr(1 downto 0);

  stopop <= crcerr or micerr or dataflowerr;

  -- Link received interrupts to the active control structure.
  crcerr1      <= crcerr       when select_cs0 = '0' else '0';
  micerr1      <= micerr       when select_cs0 = '0' else '0';
  dataflowerr1 <= dataflowerr  when select_cs0 = '0' else '0';
  crcerr0      <= crcerr       when select_cs0 = '1' else '0';
  micerr0      <= micerr       when select_cs0 = '1' else '0';
  dataflowerr0 <= dataflowerr  when select_cs0 = '1' else '0';

  ------------------------------------------------ Process_Done Pulse Generation
  -- This process generates a pulse when the signal process_done indicates that
  -- the encryption/decryption has finished.
  done_pr: process (pclk, presetn)
  begin
    if (presetn = '0') then
      process_done_ff <= '1';
    elsif (pclk'event) and (pclk = '1') then
      process_done_ff <= process_done;
    end if;
  end process done_pr;
  -- Generate a pulse when processing is over.
  done_pulse <= process_done and not (process_done_ff);
  
  -- last_cs is used to store which control structure was processed last. It is
  -- updated on done_pulse.
  last_cs_pr: process (pclk, presetn)
  begin
    if (presetn = '0') then
      last_cs <= '0';
    elsif (pclk'event and pclk = '1') then
      if (done_pulse = '1') then
        last_cs <= not(select_cs0);
      end if;
    end if;
  end process last_cs_pr;
  ----------------------------------------- End of Process_Done Pulse Generation

  --------------------------------------------------- Stream Processor Interrupt
  -- This process generates the interrupt from both control structure. The
  -- interrupt line is set to 1 when the encryption/decryption is finished
  -- and reset when the interrupt acknowledge is received. When the interrupt
  -- mask is set to 0, the interrupt generation is disabled.
  
  interrupt_pr: process (pclk, presetn)
    variable interrupt0_v : std_logic; -- Interrupt from control structure 0.
    variable interrupt1_v : std_logic; -- Interrupt from control structure 1.
  begin
    if presetn = '0' then
      -- Reset interrupt lines.
      interrupt    <= '0';
      interrupt0   <= '0';
      interrupt1   <= '0';
      -- Reset variables.
      interrupt0_v := '0';
      interrupt1_v := '0';

    elsif (pclk'event and pclk = '1') then

      -- Interrupt 0 handling.
      if (int_intack0 = '1') then
        interrupt0_v := '0';
      elsif ( (int_intmask0 = '1') and 
           (done_pulse = '1') and (select_cs0 = '1') ) then
        interrupt0_v := '1';
      end if;

      -- Interrupt 1 handling.
      if (int_intack1 = '1') then
        interrupt1_v := '0';
      elsif ( (int_intmask1 = '1') and 
           (done_pulse = '1') and (select_cs0 = '0') ) then
        interrupt1_v := '1';
      end if;

      -- Generate interrupt lines.
      interrupt0 <= interrupt0_v;
      interrupt1 <= interrupt1_v;
      interrupt  <= interrupt0_v or interrupt1_v;

    end if;
  end process interrupt_pr;
  
  -------------------------------------------- End of Stream Processor Interrupt

  --------------------------------------------------------- 'startop' generation
  -- This process generates the 'startop' signal sent to the stream processor
  -- state machine. If control structures 0 and 1 are launched together, 
  -- priority is given to the control structure 0. 'starop' signals from each
  -- control structure are memorized until they can be sent to the state
  -- machine.
  startop_pr: process (pclk, presetn)
  begin
    if presetn = '0' then
      select_cs0     <= '1';
      reset_startop1 <= '0';
      reset_startop0 <= '0';
      startop        <= '0';
    elsif pclk'event and pclk = '1' then
      startop        <= '0';
      -- Handle reset signals (pulses).
      reset_startop0 <= '0';
      reset_startop1 <= '0';
      -- Check if a new operation is required, and which control structure
      -- should be used.
      if process_done = '1' then
        -- Priority to startop0 operation.
        if int_startop0 = '1' then 
          startop        <= '1';
          select_cs0     <= '1';
          reset_startop0 <= '1'; -- Acknowledge startop0.
        elsif int_startop1 = '1'then
          startop        <= '1';
          select_cs0     <= '0';
          reset_startop1 <= '1'; -- Acknowledge startop1.
        end if;
      end if;
    end if;
  end process startop_pr;
  -------------------------------------------------- End of 'startop' generation
  
  -------------------------------------------------------------- APB Write Cycle
  -- The write cycle follows the timing shown in page 5-5 of the AMBA
  -- Specification.
  writeregisters_pr : process(pclk, presetn)
  variable address_reg_v : std_logic_vector(2 downto 0);
  begin
    if (presetn = '0') then             -- Reset state of all the registers is 0
      -- Reset STPRCNTL.
      int_comply_d6_d4n <= '0';
      int_crc_debug   <= '0';
      int_startop1    <= '0';
      int_startop0    <= '0';
      -- Reset STRPCSTRUCT0.
      int_cstruct0    <= (others => '0');
      -- Reset STRPCSTRUCT1.
      int_cstruct1    <= (others => '0');
      -- Reset STRPINTMASK.
      int_intmask1    <= '0';
      int_intmask0    <= '0';
      -- Reset STRPINTACK.
      int_intack1     <= '0';
      int_intack0     <= '0';
      -- Reset STRPSTAT.
      int_micerr1     <= '0';
      int_flowerr1    <= '0';
      int_crcerr1     <= '0';
      int_micerr0     <= '0';
      int_flowerr0    <= '0';
      int_crcerr0     <= '0';
    elsif (pclk'event) and (pclk = '1') then

      -- Detect errors from control structure 1 processing.
      if micerr1 = '1' then          -- MIC error.
        int_micerr1 <= '1';
      elsif int_intack1 = '1' then   -- Acknowledged.
        int_micerr1 <= '0';
      end if;
      if dataflowerr1 = '1' then     -- AHB error.
        int_flowerr1 <= '1';
      elsif int_intack1 = '1' then   -- Acknowledged.
        int_flowerr1 <= '0';
      end if;
      if crcerr1 = '1' then          -- CRC error.
        int_crcerr1 <= '1';
      elsif int_intack1 = '1' then   -- Acknowledged.
        int_crcerr1 <= '0';
      end if;

      -- Detect errors from control structure 0 processing.
      if micerr0 = '1' then          -- MIC error.
        int_micerr0 <= '1';
      elsif int_intack0 = '1' then   -- Acknowledged.
        int_micerr0 <= '0';
      end if;
      if dataflowerr0 = '1' then     -- AHB error.
        int_flowerr0 <= '1';
      elsif int_intack0 = '1' then   -- Acknowledged.
        int_flowerr0 <= '0';
      end if;
      if crcerr0 = '1' then          -- CRC error.
        int_crcerr0 <= '1';
      elsif int_intack0 = '1' then   -- Acknowledged.
        int_crcerr0 <= '0';
      end if;
      
      -- Reset startop0 signal.
      if reset_startop1 = '1' then
        int_startop1 <= '0';
      end if;
      -- Reset startop0 signal.
      if reset_startop0 = '1' then
        int_startop0 <= '0';
      end if;      

      -- APB write cycle.
      if (psel = '1') and (pwrite = '1') and (penable = '1') then
        address_reg_v := paddr(4 downto 2);
        case address_reg_v is
          when STRPCNTL_ADDR_CT =>      -- Write cycle in the STRPCNTL register.
            int_comply_d6_d4n<= pwdata(17);
            int_crc_debug    <= pwdata(16);
            int_startop1     <= pwdata(1);
            int_startop0     <= pwdata(0);
          when STRPCSTRUCT0_ADDR_CT =>  -- Write cycle in the STRPCSTRUCT0 reg.
            int_cstruct0     <= pwdata;
          when STRPCSTRUCT1_ADDR_CT =>  -- Write cycle in the STRPCSTRUCT1 reg.
            int_cstruct1     <= pwdata;
          when STRPINTMASK_ADDR_CT =>   -- Write cycle in the STRPINTMASK reg.
            int_intmask1     <= pwdata(1);
            int_intmask0     <= pwdata(0);
          when STRPINTACK_ADDR_CT =>    -- Write cycle in the STRPINTACK reg.
            int_intack1      <= pwdata(1);
            int_intack0      <= pwdata(0);
          when others => 
            null;
        end case;
      else
        int_intack1   <= '0';          -- Reset Interrupt Acknowledge.
        int_intack0   <= '0';          -- Reset Interrupt Acknowledge.
      end if;
    end if;
  end process writeregisters_pr;  
  ------------------------------------------------------- End of APB Write Cycle

  --------------------------------------------------------------- APB Read Cycle
  -- The read cycle follows the time diagram shown in page 5-6 of the AMBA
  -- Specification.
  -- psel is used to detect the beginning of the two-clock-cycle-long APB
  -- read access. This way, the second cycle can be used to register prdata
  -- and comply with interfaces timing requirements.
  readregisters_comb_p : process (int_comply_d6_d4n, int_crc_debug,
                                  int_crcerr0, int_crcerr1, int_cstruct0,
                                  int_cstruct1, int_flowerr0, int_flowerr1,
                                  int_intmask0, int_intmask1, int_micerr0,
                                  int_micerr1, interrupt0, interrupt1, last_cs,
                                  paddr, psel)
    variable address_reg_v : std_logic_vector(2 downto 0);
  begin

    next_prdata <= (others => '0');

    if (psel='1') then
      address_reg_v := paddr(4 downto 2);
      case address_reg_v is

        when STRPVERS_ADDR_CT =>
          next_prdata <= STRP_BUILD_CT & STRP_RELEASE_CT & STRP_UPGRADE_CT;

        when STRPCNTL_ADDR_CT =>        -- Read cycle in the STRPCNTL register.
          next_prdata(17) <= int_comply_d6_d4n;
          next_prdata(16) <= int_crc_debug;
          
        when STRPCSTRUCT0_ADDR_CT =>    -- Read cycle in the STRPCSTRUCT0 reg.
          next_prdata <= int_cstruct0;

        when STRPCSTRUCT1_ADDR_CT =>    -- Read cycle in the STRPCSTRUCT1 reg.
          next_prdata <= int_cstruct1;

        when STRPINTMASK_ADDR_CT =>     -- Read cycle in the STRPRINTMASK reg.
          next_prdata(1) <= int_intmask1;
          next_prdata(0) <= int_intmask0;

        when STRPSTAT_ADDR_CT =>        -- Read cycle in the STRPRSTAT reg.
          next_prdata(24) <= last_cs;
          next_prdata(21) <= interrupt1;
          next_prdata(18) <= int_micerr1;
          next_prdata(17) <= int_flowerr1;
          next_prdata(16) <= int_crcerr1;
          next_prdata(5)  <= interrupt0;
          next_prdata(2)  <= int_micerr0;
          next_prdata(1)  <= int_flowerr0;
          next_prdata(0)  <= int_crcerr0;
          
        when others =>
          next_prdata <= (others => '0');

      end case;
    else
      next_prdata <= (others => '0');
    end if;
  end process readregisters_comb_p;

  -- Register prdata output.
  readregisters_seq_p: process (pclk, presetn)
  begin
    if presetn = '0' then
      prdata <= (others => '0');      
    elsif pclk'event and pclk = '1' then
      if psel = '1' then
        prdata <= next_prdata;
      end if;
    end if;
  end process readregisters_seq_p;

  -------------------------------------------------------- End of APB Read Cycle

end RTL;
