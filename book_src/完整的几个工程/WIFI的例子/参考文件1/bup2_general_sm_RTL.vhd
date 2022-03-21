
--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of bup2_general_sm is

--------------------------------------------------------------------------------
-- types
--------------------------------------------------------------------------------
type BUP_STATE_TYPE is (idle_state,      -- idle state, radio is on    
                        busy_state,      -- signal received, checking it    
                        sifs_state,      -- waiting for a SIFS interval    
                        rx_state,        -- receiving a packet    
                        rxabort_state,   -- RX aborted after address1 mismatch
                        rxsifs_state,    -- waiting for a RXSIFS interval    
                        tx_state,        -- sending a packet 
                        txsifs_state);   -- waiting for a TXSIFS interval    

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
  -- Constant for rxend_stat
  constant ADDRMISMATCH_CT : std_logic_vector(1 downto 0) := "01";
  
--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------
  --------------------------------------
  -- BuP general state machine
  -------------------------------------- 
  signal bup_state         : BUP_STATE_TYPE; -- BuP state
  signal next_bup_state    : BUP_STATE_TYPE; -- Next bup_state

  --------------------------------------
  -- CCA management
  -------------------------------------- 
  signal ccabusy_it_s      : std_logic; -- pulse on cca busy
  --------------------------------------
  -- RX Start
  -------------------------------------- 
  signal phy_rxstartend_ind_ff1 : std_logic; -- Detect edge on phy_rxstartend_ind
  signal rx_start          : std_logic; -- valid packet header detected

  --------------------------------------------
  -- Flags for detection of IAC tx after the end of an SIFS period.
  --------------------------------------------
  signal iac_during_sifs   : std_logic;
  
  --------------------------------------------
  -- Signals to delay CCA busy indication.
  --------------------------------------------
  signal phy_cca_ind_ff0   : std_logic;
  signal phy_cca_ind_ff1   : std_logic;
  signal phy_cca_ind_int   : std_logic;
  signal vcs_enable_ff0    : std_logic;
  signal vcs_enable_ff1    : std_logic;
  signal vcs_enable_int    : std_logic;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------

begin

  
  --------------------------------------------
  -- Delay CCA busy and VCS indication: it must rise in the state machines two
  -- clock cycles after it rises in the timers, and fall at the same time.
  --------------------------------------------
  phy_cca_ind_dly_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      phy_cca_ind_ff0 <= '0';
      phy_cca_ind_ff1 <= '0';
      vcs_enable_ff0  <= '0';
      vcs_enable_ff1  <= '0';

    elsif hclk'event and hclk = '1' then
      phy_cca_ind_ff0 <= phy_cca_ind;
      phy_cca_ind_ff1 <= phy_cca_ind_ff0;
      vcs_enable_ff0  <= vcs_enable;
      vcs_enable_ff1  <= vcs_enable_ff0;

    end if;
  end process phy_cca_ind_dly_p;

  vcs_enable_int <= vcs_enable and vcs_enable_ff1;
  phy_cca_ind_int <= phy_cca_ind and phy_cca_ind_ff1;
  ccabusy_it <= ccabusy_it_s;
  
  ------------------------------------------------------------------------------
  -- BuP general state machine
  ------------------------------------------------------------------------------
  bup_general_sm_comb_p: process(backoff_timer_it, bup_state, bup_testmode,
                                 iac_txenable, iac_without_ifs,
                                 phy_cca_ind_int, rx_end, rx_err, rx_start,
                                 rxend_stat, sifs_timer_it, testenable, tx_end,
                                 tximmstop, vcs_enable_int)
  begin
    
    case bup_state is
      
      -- default state
      -- the radio is on, listening to its environment
      -- Priority is first to IAC TX, then to CCA busy, then to other TX
      when idle_state =>
       
        -- IAC TX: backoff timer is used in case the IAC queue is programmed
        -- with an IFS.
        if (iac_txenable = '1') and (tximmstop = '0')
           and (backoff_timer_it = '1' or iac_without_ifs = '1') then
          next_bup_state <= tx_state;
      
        elsif (phy_cca_ind_int = '1') or (vcs_enable_int = '1') then
          next_bup_state <= busy_state;
        elsif (tximmstop = '0') and 
              ( (backoff_timer_it = '1') or 
                (testenable = '1' and bup_testmode = "10") ) then
          next_bup_state <= tx_state;
        else
          next_bup_state <= idle_state;
        end if;

      -- signal detected
      -- checking if the packet is valid             
      when busy_state =>
        -- not a valid packet

        if (iac_txenable = '1') and (tximmstop = '0') then
           next_bup_state <= idle_state;
        
        elsif (phy_cca_ind_int = '0') and (vcs_enable_int = '0') then
          next_bup_state <= sifs_state;
        -- valid rx packet  
        elsif (rx_start = '1') and (phy_cca_ind_int = '1') then                        
          next_bup_state <= rx_state;
        else
          next_bup_state <= busy_state;
        end if;

      -- wait for SIFS period          
      when sifs_state =>
        -- CCA indication is taken into account during SIFS
        if (phy_cca_ind_int = '1') or (vcs_enable_int = '1') then
          next_bup_state <= busy_state;
        elsif (sifs_timer_it = '1') then               
          next_bup_state <= idle_state;
        else
          next_bup_state <= bup_state;
        end if;

      -- wait for RXSIFS or TXSIFS period          
      when rxsifs_state | txsifs_state =>
        if (sifs_timer_it = '1') then               
          next_bup_state <= idle_state;
        else
          next_bup_state <= bup_state;
        end if;

      -- receiving a packet
      when rx_state =>
        -- end of packet
        if (rx_end = '1') then
          -- RX abort on address1 mismatch.
          if rxend_stat = ADDRMISMATCH_CT then
            next_bup_state <= rxabort_state;
          -- Error from Modem  
          elsif (rx_err = '1') then                 
            next_bup_state <= busy_state;       
          else -- No auto response needed or FCS error detected
            next_bup_state <= rxsifs_state;
          end if;
        else
          next_bup_state <= rx_state;
        end if;

      -- RX abort: wait for CCA idle.
      when rxabort_state =>
        if (phy_cca_ind_int = '0') and (vcs_enable_int = '0') then
          next_bup_state <= sifs_state;
        else
          next_bup_state <= rxabort_state;
        end if;

      -- sending a packet      
      when tx_state =>
        if (tx_end = '1') then
          next_bup_state <= txsifs_state;
        else
          next_bup_state <= tx_state;
        end if;
      
      when others => 
        next_bup_state <= idle_state;

    end case;
  end process bup_general_sm_comb_p;

 
  -- Bup state machine sequencial process
  bup_general_sm_seq_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      bup_state <= idle_state;
    elsif (hclk'event and hclk = '1') then
      bup_state <= next_bup_state;
    end if;
  end process bup_general_sm_seq_p;
 
 
  bup_sm_idle <= '0' when (bup_state = busy_state) or
                          (bup_state = rx_state) or
                          (bup_state = tx_state) else
                 '1'; 



  --------------------------------------------
  -- iacaftersifs bit is set if a IAC transmission is enabled
  -- after the end of an SIFS-txstartdel period.
  --------------------------------------------
  iacaftersifs_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      iac_during_sifs <= '0';
      iacaftersifs    <= '0';
    elsif hclk'event and hclk = '1' then
      -- Acknowledge iacaftersifs sticky bit.
      if iacaftersifs_ack = '1' then
        iacaftersifs    <= '0';
      end if;

      case bup_state is

        -- wait for SIFS, RXSIFS or TXSIFS period          
        when sifs_state | rxsifs_state | txsifs_state =>
          -- Set flag if IAC TX request is received during SIFS, before the last txstartdel us.
          if (iac_txenable = '1') and (txstartdel_flag = '0') then
            iac_during_sifs <= '1';
          end if;

        -- Start transmission
        when tx_state =>
          -- Reset IAC flag.
          iac_during_sifs <= '0';
          -- In case of IAC TX, set iacaftersifs stick bit.
          if iac_txenable = '1' then
            iacaftersifs <= not(iac_during_sifs);
          end if;

        when others =>
          null;
          
      end case;
        
    end if;
  end process iacaftersifs_p;
  
  
  --------------------------------------------
  -- Address1 mismatch abort status line
  -- In case of abort due to address1 mismatch,
  -- set rxv_macaddr_match low from RX end interrupt
  -- to CCA idle.
  --------------------------------------------
  macaddr_match_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      rxv_macaddr_match <= '1';
    elsif hclk'event and hclk = '1' then
      if rx_end = '1' and rxend_stat = ADDRMISMATCH_CT then
        rxv_macaddr_match <= '0';
      elsif phy_cca_ind_int = '0' then
        rxv_macaddr_match <= '1';
      end if;
    end if;
  end process macaddr_match_p;
  
  
  --------------------------------------------
  -- Generate a pulse on RX end for the timers:
  -- After end of RX abort if the packet aborted, 
  -- else when RX end interrupt is received.
  -- This interrupt will be used to enter SIFS state in the timers.
  --------------------------------------------
  rx_abortend_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      rx_abortend <= '0';
    elsif (hclk'event and hclk = '1') then
      if ((bup_state = rx_state) or (bup_state = rxabort_state)) and
         (next_bup_state /= rx_state) and (next_bup_state /= rxabort_state) then
        rx_abortend <= '1';
      else  
        rx_abortend <= '0';
      end if;  
    end if;
  end process rx_abortend_p;



  ------------------------------------------------------------------------------
  -- TX and RX management
  ------------------------------------------------------------------------------

  -- tx_mode just indicates that the BuP is in TX mode.
  -- This is used by the TX state machine 
  -- to launch the packet transmission. 
  tx_mode_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      tx_mode <= '0';
    elsif (hclk'event and hclk = '1') then
      if (next_bup_state = tx_state) then
        tx_mode <= '1';
      else  
        tx_mode <= '0';
      end if;  
    end if;
  end process tx_mode_p;


  -- rx_mode just indicates that the BuP is in RX mode.
  -- This is used by the RX state machine 
  -- to launch the packet reception. 
  -- The right modem is also selected.
  rx_mode_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      rx_mode            <= '0';
    elsif (hclk'event and hclk = '1') then
      if (next_bup_state = rx_state) then
        rx_mode <= '1';
      else  
        rx_mode <= '0';
      end if;  
    end if;
  end process rx_mode_p;


  ------------------------------------------------------------------------------
  -- CCA interrupt pulse
  ------------------------------------------------------------------------------
  cca_it_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      ccabusy_it_s  <= '0';
      ccaidle_it    <= '0';
    elsif (hclk'event and hclk = '1') then
      if bup_state = idle_state and 
        (phy_cca_ind_int = '1' or vcs_enable_int = '1') then
        ccabusy_it_s <= '1';
      else  
        ccabusy_it_s <= '0';
      end if;  
      if bup_state = busy_state and 
        phy_cca_ind_int = '0' and vcs_enable_int = '0' then
        ccaidle_it <= '1';
      else  
        ccaidle_it <= '0';
      end if;  
    end if;
  end process cca_it_p;

  ------------------------------------------------------------------------------
  -- Reset txenable when transmition of selected queue starts
  --          1000 : IAC
  --          1001 : Beacon
  --   0000 - 0111 : ACP[0-7]
  ------------------------------------------------------------------------------
  reset_txenable_p: process (hclk, hresetn)
    variable queue_it_num_v : integer;
  begin
    if hresetn = '0' then
      reset_bcon_txen <= '0';
      reset_iac_txen  <= '0';
      reset_acp_txen  <= (others => '0');
    elsif (hclk'event and hclk = '1') then
      queue_it_num_v  := conv_integer(queue_it_num);
      reset_bcon_txen <= '0';
      reset_iac_txen  <= '0';
      reset_acp_txen  <= (others => '0');
      
      if ((iac_txenable = '1') and (bup_state = busy_state) and
          (next_bup_state = idle_state)) then
        reset_iac_txen <= '1';
      elsif ((bup_state = idle_state) and (next_bup_state = tx_state)) then
        if (iac_txenable = '1') then
          reset_iac_txen   <= '1';
        else	
          case queue_it_num_v is
            when 0 to 7 =>
              reset_acp_txen(queue_it_num_v) <= '1';
            when 8 =>
              reset_iac_txen   <= '1';
            when 9 =>
              reset_bcon_txen  <= '1';
            when others =>
          end case;
        end if;
      end if;  
    end if;
  end process reset_txenable_p;

  
  --------------------------------------
  -- RX Start
  -------------------------------------- 

  -- RX start indication from Modem.
  -- A rising edge on phy_rxstartend_ind indicates the detection of a preamble 
  -- in the received symbol stream. If the edge is skipped (e.g. the BuP was in
  -- a state where CCA ws ignored) the reception is ignored.
  rx_start_p: process (hclk, hresetn)
  begin
    if hresetn = '0' then
      phy_rxstartend_ind_ff1 <= '0';
    elsif hclk'event and hclk = '1' then
      phy_rxstartend_ind_ff1 <= phy_rxstartend_ind;      
    end if;
  end process rx_start_p;
  rx_start <= phy_rxstartend_ind and not phy_rxstartend_ind_ff1;
  
  

  -- diag
  gene_sm_diag_p : process(bup_state)
  begin
    case bup_state is
      when rxabort_state =>
        gene_sm_diag <= "000";
      when idle_state =>
        gene_sm_diag <= "001";
      when busy_state =>
        gene_sm_diag <= "010";
      when sifs_state =>
        gene_sm_diag <= "011";
      when rx_state =>
        gene_sm_diag <= "100";
      when rxsifs_state =>
        gene_sm_diag <= "101";
      when tx_state =>
        gene_sm_diag <= "110";
       when txsifs_state =>
        gene_sm_diag <= "111";
        
      when others =>
        gene_sm_diag <= "111";
        
    end case;
  end process gene_sm_diag_p;

end RTL;
