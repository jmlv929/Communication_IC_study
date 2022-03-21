

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of bup2_timers is

  --------------------------------------------
  -- Constants
  --------------------------------------------
  constant LP_STEP_131072HZ_CT   : std_logic_vector(11 downto 0)
                                 := conv_std_logic_vector(1289, 12);
  constant LP_STEP_32KHZ_CT      : std_logic_vector(11 downto 0)
                                 := conv_std_logic_vector(128, 12);
  constant LP_STEP_32768HZ_CT    : std_logic_vector(11 downto 0)
                                 := conv_std_logic_vector(265, 12);
  -- Compensate 4 low-power clock periods: 2*7 + 2*8
  constant ADJUST_131072HZ_CT    : std_logic_vector(26 downto 0)
                                 := conv_std_logic_vector(30, 27);
  -- Compensate 4 low-power clock periods: 3*31 + 32
  constant ADJUST_32kHZ_CT       : std_logic_vector(26 downto 0)
                                 := conv_std_logic_vector(125, 27);                             
  -- Compensate 4 low-power clock periods: 2*30 + 2*31
  constant ADJUST_32768HZ_CT     : std_logic_vector(26 downto 0)
                                 := conv_std_logic_vector(122, 27);
  -- Main step of the BuP timer in low-power mode
  constant STEP_32KHZ_CT         : std_logic_vector(26 downto 0)
                                 := conv_std_logic_vector(31, 27);
  constant STEP_32768HZ_CT       : std_logic_vector(26 downto 0)
                                 := conv_std_logic_vector(30, 27);
  constant STEP_131072HZ_CT      : std_logic_vector(26 downto 0)
                                 := conv_std_logic_vector(7, 27);
                         
  -- Constants for clk32sel decoding
  constant SEL_32KHZ_CT       : std_logic_vector(1 downto 0) := "00";
  constant SEL_32768HZ_CT     : std_logic_vector(1 downto 0) := "01";
  constant SEL_131072HZ_CT    : std_logic_vector(1 downto 0) := "10";

  --------------------------------------------
  -- Types
  --------------------------------------------
  type SIFS_COUNTER_SM_TYPE is (idle_state, sifs_count_state, wait_state);
  type ARRAY_SLV10 is array (natural range <>) of std_logic_vector(9 downto 0);
  type ARRAY_SLV4 is array (natural range <>) of std_logic_vector(3 downto 0);
  
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------

  signal int_bup_timer     : std_logic_vector(25 downto 0); -- BuP timer.  
  signal all_zero          : std_logic_vector(31 downto 0); -- 
  
  signal vcs_count         : std_logic; -- '1' when vcs count reached.
  signal vcs_count_ff1     : std_logic; -- vcs_count delayed of 1 pclk cc.
  
  signal reset_vcs_o       : std_logic; -- pulse on reset of vcs

  signal ackto_timer_on    : std_logic; -- High while ACK time-out timer is running.
  
  -- SIFS counter
  signal sifs_counter         : std_logic_vector(5 downto 0);
  signal sifs_counter_next    : std_logic_vector(5 downto 0);
  signal sifs_counter_it      : std_logic;
  signal sifs_counter_sm      : SIFS_COUNTER_SM_TYPE; -- sm
  signal sifs_counter_next_sm : SIFS_COUNTER_SM_TYPE;
  signal in_sifs_state        : std_logic;
  signal sifs_end             : std_logic;
  signal sifs_end_bcon        : std_logic;
  signal sifs_end_acp         : std_logic;
  
  -- array of backoff counters
  signal reg_backoff          : ARRAY_SLV10(9 downto 0);
  signal backoff_timer        : ARRAY_SLV10(9 downto 0);
  signal ifs                  : ARRAY_SLV4(9 downto 0);
  signal write_backoff        : std_logic_vector(9 downto 0);
  signal backenable           : std_logic_vector(9 downto 0);
  signal txenable             : std_logic_vector(9 downto 0);
  signal txenable_acp         : std_logic; -- OR of ACP TX enables for diag
  
  signal backoff_it           : std_logic_vector(9 downto 0);
  signal tx_without_backoff   : std_logic_vector(9 downto 0);
  signal global_backoff_it    : std_logic;
  signal backoff_timer_it_s   : std_logic;
  signal last_slot            : std_logic_vector(9 downto 0);
  signal global_last_slot     : std_logic;

  -- Signals to adjust BuP timer count in low-power mode.
  signal mode32k_ff           : std_logic;
  signal lwpw_cnt             : std_logic_vector(11 downto 0);
  signal lwpw_cnt_step        : std_logic_vector(11 downto 0);
  signal lwpw_cnt_trunc       : std_logic_vector(10 downto 0);
  signal adjust_step          : std_logic_vector(26 downto 0);
  signal buptimer_step        : std_logic_vector(26 downto 0);
  signal buptimer_carry       : std_logic;
  
  -- Signals to delay context switching if a transmission is about to start
  signal reg_cntxtsel_ff1     : std_logic; -- reg_cntxtsel delayed by one cycle.
  signal context_change       : std_logic; -- Pulse when reg_cntxtsel toggles.
  signal cntxtsel_dly         : std_logic; -- Delayed context selection.
  
  signal tx_end_int: std_logic;
  signal rx_end_int: std_logic;
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  diag_p: process(txenable)
    variable i      : integer;
    variable temp_v : std_logic;
  begin
    temp_v := '0';
    diag_loop: for i in 2 to 9 loop
      temp_v := temp_v or txenable(i);
    end loop diag_loop;
    txenable_acp <= temp_v;
  end process diag_p;
  
  --------------------------------------------
  -- Diagnostic ports
  --------------------------------------------
  bup_timers_diag <= enable_1mhz &          -- 7
                     txenable(1) &          -- 6 Beacon TX enable
                     txenable_acp &         -- 5
                     ackto_timer_on &       -- 4
                     in_sifs_state &        -- 3
                     "000";                 -- 2:0
  
  tx_end_int  <= tx_end;
  rx_end_int  <= rx_end;
  
  --------------------------------------------
  -- General assignements
  --------------------------------------------
  bup_timer        <= int_bup_timer;
  all_zero         <= (others => '0');
  sifs_timer_it    <= sifs_counter_it;
  backoff_timer_it <= backoff_timer_it_s;
  iac_without_ifs  <= '1' when ifs_iac = 0 else '0';
  
  reg_backoff(0) <= (others => '0');
  reg_backoff(1) <= reg_backoff_bcon;
  reg_backoff(2) <= reg_backoff_acp0;
  reg_backoff(3) <= reg_backoff_acp1;
  reg_backoff(4) <= reg_backoff_acp2;
  reg_backoff(5) <= reg_backoff_acp3;
  reg_backoff(6) <= reg_backoff_acp4;
  reg_backoff(7) <= reg_backoff_acp5;
  reg_backoff(8) <= reg_backoff_acp6;
  reg_backoff(9) <= reg_backoff_acp7;
  
  backoff_timer_bcon <= backoff_timer(1);
  backoff_timer_acp0 <= backoff_timer(2);
  backoff_timer_acp1 <= backoff_timer(3);
  backoff_timer_acp2 <= backoff_timer(4);
  backoff_timer_acp3 <= backoff_timer(5);
  backoff_timer_acp4 <= backoff_timer(6);
  backoff_timer_acp5 <= backoff_timer(7);
  backoff_timer_acp6 <= backoff_timer(8);
  backoff_timer_acp7 <= backoff_timer(9);

  write_backoff(0) <= write_backoff_iac;
  write_backoff(1) <= write_backoff_bcon;
  write_backoff(2) <= write_backoff_acp0;
  write_backoff(3) <= write_backoff_acp1;
  write_backoff(4) <= write_backoff_acp2;
  write_backoff(5) <= write_backoff_acp3;
  write_backoff(6) <= write_backoff_acp4;
  write_backoff(7) <= write_backoff_acp5;
  write_backoff(8) <= write_backoff_acp6;
  write_backoff(9) <= write_backoff_acp7;

  backenable(0) <= '1';
  backenable(1) <= backenable_bcon and not cntxtsel_dly;
  backenable(2) <= backenable_acp0 and cntxtsel_dly;
  backenable(3) <= backenable_acp1 and cntxtsel_dly;
  backenable(4) <= backenable_acp2 and cntxtsel_dly;
  backenable(5) <= backenable_acp3 and cntxtsel_dly;
  backenable(6) <= backenable_acp4 and cntxtsel_dly;
  backenable(7) <= backenable_acp5 and cntxtsel_dly;
  backenable(8) <= backenable_acp6 and cntxtsel_dly;
  backenable(9) <= backenable_acp7 and cntxtsel_dly;
  
  -- All queues enables are gated by forcetxdis HIGH.
  txenable(0) <= txenable_iac; -- already done in registers.
  txenable(1) <= txenable_bcon and not cntxtsel_dly and not (forcetxdis);
  txenable(2) <= txenable_acp0 and cntxtsel_dly and not (forcetxdis);
  txenable(3) <= txenable_acp1 and cntxtsel_dly and not (forcetxdis);
  txenable(4) <= txenable_acp2 and cntxtsel_dly and not (forcetxdis);
  txenable(5) <= txenable_acp3 and cntxtsel_dly and not (forcetxdis);
  txenable(6) <= txenable_acp4 and cntxtsel_dly and not (forcetxdis);
  txenable(7) <= txenable_acp5 and cntxtsel_dly and not (forcetxdis);
  txenable(8) <= txenable_acp6 and cntxtsel_dly and not (forcetxdis);
  txenable(9) <= txenable_acp7 and cntxtsel_dly and not (forcetxdis);
  
  sifs_end_bcon <= sifs_end and not cntxtsel_dly;
  sifs_end_acp  <= sifs_end and cntxtsel_dly;
  
  ifs(0) <= ifs_iac;
  ifs(1) <= ifs_bcon;
  ifs(2) <= ifs_acp0;
  ifs(3) <= ifs_acp1;
  ifs(4) <= ifs_acp2;
  ifs(5) <= ifs_acp3;
  ifs(6) <= ifs_acp4;
  ifs(7) <= ifs_acp5;
  ifs(8) <= ifs_acp6;
  ifs(9) <= ifs_acp7;
    
  --------------------------------------------
  -- If a backoff counter has already generated a pulse on backoff_it(i),
  -- delay context switch to let time to the bup2_timers to start the
  -- transmission.
  --------------------------------------------
  cntxt_sel_delay_p: process (pclk, reset_n)
  begin
    if reset_n = '0' then
      reg_cntxtsel_ff1 <= '0';
      cntxtsel_dly <= '0';
    elsif pclk'event and pclk = '1' then
      reg_cntxtsel_ff1 <= reg_cntxtsel;
      if (context_change = '1') then
        -- At time of switch, switch only if no TX on-going between backoff2*
        -- and bup2_timers modules.
        if ( (cntxtsel_dly = '0') and (backoff_it(1) = '0') ) or          -- Beacon TX
           ( (cntxtsel_dly = '1') and (backoff_it(9 downto 2) = 0) ) then -- ACPx TX
          cntxtsel_dly <= reg_cntxtsel;
        end if;
      else -- cntxtsel_dly follows reg_cntxtsel.
        cntxtsel_dly <= reg_cntxtsel;        
      end if;
    end if;
  end process cntxt_sel_delay_p;
  -- Detect context switch.
  context_change <= reg_cntxtsel xor reg_cntxtsel_ff1;

  --------------------------------------------
  -- Generate the global backoff interrupt.
  -- This is an OR of the queues backoff interrupts.
  -- The backoff interrupt is gated by the selected context (ACP or Beacon)
  --------------------------------------------
  global_backoff_it_p : process(backoff_it, cntxtsel_dly)
    variable i : integer;
    variable temp_it_v : std_logic;
  begin
    temp_it_v := '0';
    for i in 2 to num_queues_g + 1 loop
      temp_it_v := temp_it_v or backoff_it(i);
    end loop;
    global_backoff_it <= (temp_it_v and cntxtsel_dly)
                       or (backoff_it(1) and not cntxtsel_dly)
                       or backoff_it(0);
  end process global_backoff_it_p;
  

  
  --------------------------------------------
  -- Generate the global last slot signal.
  -- This is an OR of the backoff last slot signals.
  --------------------------------------------
  global_last_slot_p : process(last_slot)
    variable i : integer;
    variable temp_it_v : std_logic;
  begin
    temp_it_v := '0';
    for i in 0 to num_queues_g + 1 loop
      temp_it_v := temp_it_v or last_slot(i);
    end loop;
    global_last_slot <= temp_it_v;
  end process global_last_slot_p;
  

  
  --------------------------------------------
  -- This process provides which queue has 
  -- generated the backoff interrupt
  --------------------------------------------
  queue_it_num_p : process(pclk, reset_n)
    variable i : integer;
  begin
    if (reset_n = '0') then
      queue_it_num <= (others => '0');
    elsif (pclk'event and pclk = '1') then
      if (bup_sm_idle = '1') and (txenable_iac = '1') then
        -- IAC
        queue_it_num <= "1000";
      elsif (backoff_it(num_queues_g+1 downto 0) /= 0) and
            (bup_sm_idle = '1') and (backoff_timer_it_s = '0') then
        -- Beacon
        if (backoff_it(1) = '1') and (cntxtsel_dly = '0') then
          queue_it_num <= "1001";
        -- ACP
        elsif (cntxtsel_dly = '1') then
          for i in num_queues_g+1 downto 2 loop
            if (backoff_it(i) = '1') then
              queue_it_num <= conv_std_logic_vector(i-2,4);
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process queue_it_num_p;
    

  ------------------------------------------------------------------------------
  -- BuP timer.
  ------------------------------------------------------------------------------
  -- This process decodes the reg_clk32sel value and defines the steps for the
  -- BuP timer count in low-power mode:
  --   buptimer_step  : BuPtimer increment at each clock cycle
  --   lwpw_cnt_step  : Carry counter increment at each clock cycle
  --   lwpw_cnt_trunc : Useful part of the carry counter (mod 512 or mod 2048)
  --   buptimer_carry : Bit of the carry counter used to detect the carry
  --   adjust_step    : Timer correction when going to low-power mode
  frequency_setup_p: process(lwpw_cnt, reg_clk32sel)
  begin
    case reg_clk32sel is
      when SEL_32KHZ_CT   =>
        buptimer_step  <= STEP_32KHZ_CT;
        lwpw_cnt_step  <= LP_STEP_32KHZ_CT;
        lwpw_cnt_trunc <= "00" & lwpw_cnt(8 downto 0);
        buptimer_carry <= lwpw_cnt(9); -- modulo 512 counter
        adjust_step    <= ADJUST_32KHZ_CT;
        
      when SEL_32768HZ_CT =>
        buptimer_step  <= STEP_32768HZ_CT;
        lwpw_cnt_step  <= LP_STEP_32768HZ_CT;
        lwpw_cnt_trunc <= "00" & lwpw_cnt(8 downto 0);
        buptimer_carry <= lwpw_cnt(9); -- modulo 512 counter
        adjust_step    <= ADJUST_32768HZ_CT;

      when others         => -- SEL_131072HZ_CT
        buptimer_step  <= STEP_131072HZ_CT;
        lwpw_cnt_step  <= LP_STEP_131072HZ_CT;
        lwpw_cnt_trunc <= lwpw_cnt(10 downto 0);
        buptimer_carry <= lwpw_cnt(11); -- modulo 2048 counter
        adjust_step    <= ADJUST_131072HZ_CT;

    end case;
  end process frequency_setup_p;
  
  -- This process updates the timer value every us by incrementing the timer
  -- value or with the APB write result.
  -- The timewrap interrupt is sent when the timer wraps around to 0.
  bup_timer_p: process (buptimer_clk, reset_n)
    variable new_bup_timer_v : std_logic_vector(26 downto 0);
    variable add_bup_timer_v : std_logic_vector(26 downto 0);
  begin
    if reset_n = '0' then
      new_bup_timer_v     := (others => '0'); -- Reset the timer.
      add_bup_timer_v     := (others => '0'); -- Reset the timer.
      int_bup_timer       <= (others => '0'); -- Reset the timer.
      timewrap_interrupt  <= '0';             -- Reset timewrap interrupt.
      write_buptimer_done <= '0';             -- Reset write control signal.
      lwpw_cnt            <= (others => '0');
      mode32k_ff          <= '0';
    elsif buptimer_clk'event and buptimer_clk = '1' then      
      write_buptimer_done <= '0';      -- write_buptimer_done is a pulse.
      timewrap_interrupt  <= '0';      -- Reset timewrap interrupt.
      mode32k_ff          <= mode32k;

      -- Compute value to add to timer.
      -- low power mode
      if (mode32k = '1') then
         -- Detect first low-power period
        if mode32k_ff = '0' then
          -- Compensate delay between lowpower clock used and mode32k HIGH.
          add_bup_timer_v := adjust_step;

        else
          
          -- During the low power mode, the bup_timer should continue to count us.
          -- lwpw_cnt implements a fractional modulo-2048 or 512 counter. When it
          -- wraps, the bup_timer is incremented by its main step + 1. This gives
          -- a us period in average. See functional spec for details.
          lwpw_cnt <= lwpw_cnt_trunc + lwpw_cnt_step;
          add_bup_timer_v := buptimer_step + buptimer_carry;

        end if;

        -- Compute next timer value.
        new_bup_timer_v := ('0' & int_bup_timer) + add_bup_timer_v;
        -- Detect timer wrap around
        if (new_bup_timer_v(new_bup_timer_v'high) = '1') then
          timewrap_interrupt <= '1';  -- Interrupt on buptimer wrapping around.
        end if;
        -- Update register.
        int_bup_timer <= new_bup_timer_v(25 downto 0);

      -- 1 MHz enable running on fast clock
      elsif enable_1mhz = '1' then   
        lwpw_cnt         <= (others => '0');
        add_bup_timer_v  := conv_std_logic_vector(1, 27);

        -- Compute next timer value.
        new_bup_timer_v := ('0' & int_bup_timer) + add_bup_timer_v;
        -- Detect timer wrap around
        if (new_bup_timer_v(new_bup_timer_v'high) = '1') then
          timewrap_interrupt <= '1';  -- Interrupt on buptimer wrapping around.
        end if;
        -- Update register.
        int_bup_timer <= new_bup_timer_v(25 downto 0);
      end if;
      
      -- timer written by the software
      if ((enable_1mhz = '1') or (mode32k = '1')) and (write_buptimer = '1') then 
        int_bup_timer       <= reg_buptimer; -- Update timer.
        write_buptimer_done <= '1';
        timewrap_interrupt  <= '0';      -- Reset potential timewrap interrupt.
      end if;

    end if;
  end process bup_timer_p;
    
  
  ------------------------------------------------------------------------------
  -- Absolute counters.
  ------------------------------------------------------------------------------
  abscnt_timers_1: abscnt_timers
    generic map (
      num_abstimer_g => num_abstimer_g
      )
    port map (
      --------------------------------------
      -- Clocks & Reset
      --------------------------------------
      reset_n              => reset_n,
      clk                  => pclk,
      --------------------------------------
      -- Controls
      --------------------------------------
      mode32k              => mode32k,
      bup_timer            => int_bup_timer,
      --------------------------------------
      -- Timers time tags
      --------------------------------------
      abstime0             => reg_abstime0,
      abstime1             => reg_abstime1,
      abstime2             => reg_abstime2,
      abstime3             => reg_abstime3,
      abstime4             => reg_abstime4,
      abstime5             => reg_abstime5,
      abstime6             => reg_abstime6,
      abstime7             => reg_abstime7,
      abstime8             => reg_abstime8,
      abstime9             => reg_abstime9,
      abstime10            => reg_abstime10,
      abstime11            => reg_abstime11,
      abstime12            => reg_abstime12,
      abstime13            => reg_abstime13,
      abstime14            => reg_abstime14,
      abstime15            => reg_abstime15,
      --------------------------------------
      -- Timers interrupts
      --------------------------------------
      abscount_it          => abscount_it
      );
      
      
  --------------------------------------------
  -- VCS counter
  --------------------------------------------
  -- Comparator to detect when the BuP timer reaches the vcs counter
  -- time tag.
  vcs_count <= '1' when int_bup_timer = vcs else '0';
  -- Delay vcs_count to generate a pulse of one pclk clock-cycle.
  vcs_pulse_p: process (pclk, reset_n)
  begin
    if (reset_n = '0') then
      vcs_count_ff1 <= '0';
    elsif pclk'event and pclk = '1' then
      vcs_count_ff1 <= vcs_count;
    end if;
  end process vcs_pulse_p;
  reset_vcs_o <= vcs_count and not vcs_count_ff1;
  reset_vcs   <= reset_vcs_o;
  
  
  --------------------------------------------
  -- SIFS counter state machine
  --------------------------------------------
  -- combinational part
  sifs_counter_sm_comb_p : process (bup_sm_idle, enable_1mhz,
                                    global_backoff_it, phy_cca_ind,
                                    reg_txstartdel, rx_end_int,
                                    sifs_counter_next, sifs_counter_sm,
                                    tx_end_int, tx_without_backoff, vcs_enable)
  begin
    case sifs_counter_sm is
      when idle_state =>
        -- we start the SIFS counter when end of reception or end of 
        -- transmission or when the medium is not reserved and the
        -- CCA is idle
        if ((rx_end_int = '1') or (tx_end_int = '1') or
            ( (vcs_enable = '0') and (phy_cca_ind = '0') and 
              (bup_sm_idle = '1') )) then
          sifs_counter_next_sm <= sifs_count_state;
        else
          sifs_counter_next_sm <= idle_state;
        end if; 
         
      when sifs_count_state =>
        -- Stop SIFS count if a CCA busy or VCS is detected in BuP state machines.
        if (bup_sm_idle = '0') then
          sifs_counter_next_sm <= idle_state;
        else
          if (enable_1mhz = '1') and 
             ((sifs_counter_next = 0) or 
              ((sifs_counter_next <= ext(reg_txstartdel, sifs_counter_next'high)) and 
               ( (global_backoff_it = '1') or (tx_without_backoff /= 0) ))) then
            -- end of SIFS period
            sifs_counter_next_sm <= wait_state;
          else
            sifs_counter_next_sm <= sifs_count_state;
          end if;
        end if;

      when wait_state =>
        -- wait for a packet being processed
        if (bup_sm_idle = '0') then
          sifs_counter_next_sm <= idle_state;
        else
          sifs_counter_next_sm <= wait_state;
        end if;
          
      when others =>
        sifs_counter_next_sm <= idle_state;
    end case;
  end process sifs_counter_sm_comb_p;

  -- sequencial part
  sifs_counter_sm_p : process (pclk, reset_n)
  begin
    if reset_n = '0' then
      sifs_counter_sm <= idle_state;
    elsif pclk'event and pclk = '1' then
      sifs_counter_sm <= sifs_counter_next_sm;
    end if;
  end process sifs_counter_sm_p;

  
  --------------------------------------------
  -- SIFS counter
  --------------------------------------------
  --combinational part
  sifs_counter_comb_p : process (enable_1mhz, sifs_counter, sifs_counter_sm)
  begin
    if (enable_1mhz = '1') and (sifs_counter_sm = sifs_count_state) then
      sifs_counter_next <= sifs_counter - '1';
    else
      sifs_counter_next <= sifs_counter;
    end if;
  end process sifs_counter_comb_p;
  
  -- sequencial part of sifs counter and control part of sm
  sifs_counter_p : process (pclk, reset_n)
  begin
    if reset_n = '0' then
      backoff_timer_it_s  <= '0';
      sifs_counter        <= (others => '0');
      sifs_counter_it     <= '0';
      in_sifs_state       <= '0';
      sifs_end            <= '0';
      txstartdel_flag     <= '0';
    elsif pclk'event and pclk = '1' then
      case sifs_counter_sm is
        -- idle state
        when idle_state =>
          in_sifs_state       <= '0'; 
          sifs_end            <= '0'; 
          sifs_counter_it     <= '0'; 
          backoff_timer_it_s  <= '0'; 
          txstartdel_flag     <= '0'; 

          -- initialize SIFS counter
          if (rx_end_int = '1') then
            if (rx_packet_type = '0') then
              sifs_counter  <= reg_rxsifsb; -- modem b rxsifs
            else
              sifs_counter  <= reg_rxsifsa; -- modem a rxsifs
            end if;
          elsif (tx_end_int = '1') then
            if (tx_packet_type = '0') then
              sifs_counter  <= reg_txsifsb; -- modem b txsifs
            else
              sifs_counter  <= reg_txsifsa; -- modem a txsifs
            end if;
          else
            sifs_counter  <= reg_sifs;
          end if;

        -- sifs state
        when sifs_count_state =>
          sifs_counter  <= sifs_counter_next;
          in_sifs_state <= '1';
          
          -- Set txstartdel_flag when the SIFS counter is counting the txstartdel last us.
          if ( (sifs_counter_next <= ext(reg_txstartdel, sifs_counter_next'high)) 
           and (sifs_counter_next /= 0) ) then
            txstartdel_flag  <= '1';
          else
            txstartdel_flag  <= '0';
          end if;
          
          -- generate SIFS interrupt when SIFS count is over.
          if (sifs_counter_next_sm = wait_state) then
            sifs_counter_it <= '1';
            sifs_end        <= '1'; -- this is a flag
            
            -- if a backoff timer has elapsed, generate backoff interrupt
            if (global_backoff_it = '1') then
              backoff_timer_it_s <= '1';
            end if;
          else
            sifs_counter_it <= '0';
          end if;

        when wait_state =>
          sifs_counter_it <= '0';
          txstartdel_flag <= '0';
          -- A backoff timer interrupt is generated as soon as
          -- a backoff period has elapsed.
          if (global_backoff_it = '1') then
            backoff_timer_it_s <= '1';
          end if;

        when others =>                         
          sifs_counter_it <= '0';
          sifs_end        <= '0';
          in_sifs_state   <= '0';         
          sifs_counter    <= (others => '0');  
          txstartdel_flag <= '0';
      end case;                                
    end if;
  end process sifs_counter_p;
  

  --------------------------------------------
  -- IAC backoff counter
  --------------------------------------------
  iac_1 : backoff2
    port map (
      --------------------------------------------
      -- clock and reset
      --------------------------------------------
      reset_n             => reset_n,
      pclk                => pclk,

      --------------------------------------------
      -- Port for 1 Mhz enable.
      --------------------------------------------
      enable_1mhz         => enable_1mhz,

      --------------------------------------------
      -- Backoff Timer Control.
      --------------------------------------------
      reg_backoff         => reg_backoff(0),
      write_backoff       => write_backoff(0),
      -- BuPbackoff register when read
      backoff_timer       => backoff_timer(0),
      backoff_timer_end   => backoff_it(0),
      tx_without_backoff  => tx_without_backoff(0),
      last_slot           => last_slot(0),
      -- 
      context_change      => all_zero(0), -- No IAC context
      global_last_slot    => global_last_slot,
      reg_vcs             => all_zero(0),
      cca_busy            => phy_cca_ind,
      backenable          => backenable(0), -- '1'
      tx_enable           => txenable(0),
      tximmstop_sm        => tximmstop_sm,
      sifs_end            => sifs_end,
      bup_sm_idle         => bup_sm_idle,
      global_backoff_it   => global_backoff_it,
      ackto_timer_on      => ackto_timer_on,

      reg_macslot         => reg_macslot,
      reg_ifs             => ifs(0),

      txstartdel          => reg_txstartdel
      );
  
  --------------------------------------------
  -- Beacon backoff counter
  --------------------------------------------
  beacon_1 : backoff2
    port map (
      --------------------------------------------
      -- clock and reset
      --------------------------------------------
      reset_n             => reset_n,
      pclk                => pclk,

      --------------------------------------------
      -- Port for 1 Mhz enable.
      --------------------------------------------
      enable_1mhz         => enable_1mhz,

      --------------------------------------------
      -- Backoff Timer Control.
      --------------------------------------------
      reg_backoff         => reg_backoff(1),
      write_backoff       => write_backoff(1),
      -- BuPbackoff register when read
      backoff_timer       => backoff_timer(1),
      backoff_timer_end   => backoff_it(1),
      tx_without_backoff  => tx_without_backoff(1),
      last_slot           => last_slot(1),
      -- 
      context_change      => context_change,
      global_last_slot    => global_last_slot,
      reg_vcs             => vcs_enable,
      cca_busy            => phy_cca_ind,
      backenable          => backenable(1),
      tx_enable           => txenable(1),
      tximmstop_sm        => tximmstop_sm,
      sifs_end            => sifs_end_bcon,
      bup_sm_idle         => bup_sm_idle,
      global_backoff_it   => global_backoff_it,
      ackto_timer_on      => ackto_timer_on,

      reg_macslot         => reg_macslot,
      reg_ifs             => ifs(1),

      txstartdel          => reg_txstartdel
      );

  --------------------------------------------
  -- ACP backoff counters
  --------------------------------------------
  acp_gen : for j in 1 to num_queues_g generate
    acp_i : backoff2
      port map (
        --------------------------------------------
        -- clock and reset
        --------------------------------------------
        reset_n             => reset_n,
        pclk                => pclk,

        --------------------------------------------
        -- Port for 1 Mhz enable.
        --------------------------------------------
        enable_1mhz         => enable_1mhz,

        --------------------------------------------
        -- Backoff Timer Control.
        --------------------------------------------
        reg_backoff         => reg_backoff(j+1),
        write_backoff       => write_backoff(j+1),
        -- BuPbackoff register when read
        backoff_timer       => backoff_timer(j+1),
        backoff_timer_end   => backoff_it(j+1),
        tx_without_backoff  => tx_without_backoff(j+1),
        last_slot           => last_slot(j+1),
        -- 
        context_change      => context_change,
        global_last_slot    => global_last_slot,
        reg_vcs             => vcs_enable,
        cca_busy            => phy_cca_ind,
        backenable          => backenable(j+1),
        tx_enable           => txenable(j+1),
        tximmstop_sm        => tximmstop_sm,
        sifs_end            => sifs_end_acp,
        bup_sm_idle         => bup_sm_idle,
        global_backoff_it   => global_backoff_it,
        ackto_timer_on      => ackto_timer_on,

        reg_macslot         => reg_macslot,
        reg_ifs             => ifs(j+1),

        txstartdel          => reg_txstartdel
        );
  end generate acp_gen;
  
  --------------------------------------------
  -- Set signals for unused queues
  --------------------------------------------
  nb_queue_gen : if num_queues_g+2 <= 9 generate
    no_queue_gen : for k in num_queues_g+2 to 9 generate
      backoff_timer(k)      <= (others => '0');
      backoff_it(k)         <= '0';
      tx_without_backoff(k) <= '0';
      last_slot(k)          <= '0';
    end generate no_queue_gen;
  end generate nb_queue_gen;
  
      
  --------------------------------------------
  -- Channel assessment timers
  --------------------------------------------
  chass_timers_1: chass_timers
    port map (
      --------------------------------------------
      -- Clock and reset
      --------------------------------------------
      reset_n             => reset_n,
      clk                 => pclk,
      enable_1mhz         => enable_1mhz,
      mode32k             => mode32k,
      --------------------------------------------
      -- Controls
      --------------------------------------------
      vcs_enable          => vcs_enable,
      phy_cca_ind         => phy_cca_ind,
      phy_txstartend_conf => phy_txstartend_conf,
      reg_chassen         => reg_chassen,
      reg_ignvcs          => reg_ignvcs,
      reset_chassbsy      => reset_chassbsy,
      reset_chasstim      => reset_chasstim,
      --------------------------------------
      -- Channel assessment timers
      --------------------------------------
      reg_chassbsy        => reg_chassbsy,
      reg_chasstim        => reg_chasstim
      );


  ackto_timer_1: ackto_timer
    port map (
      --------------------------------------------
      -- Clock and reset
      --------------------------------------------
      reset_n             => reset_n,
      clk                 => pclk,
      enable_1mhz         => enable_1mhz,
      mode32k             => mode32k,
      --------------------------------------------
      -- Controls
      --------------------------------------------
      ackto_count         => ackto_count,
      ackto_en            => ackto_en,
      reg_ackto_en        => reg_ackto_en,
      txstart_it          => txstart_it,
      txend_it            => txend_it,
      rxstart_it          => rxstart_it,
      --------------------------------------------
      -- ACK time-out interrupt
      --------------------------------------------
      ackto_it            => ackto_it,
      ackto_timer_on      => ackto_timer_on
      );
      

end RTL;
