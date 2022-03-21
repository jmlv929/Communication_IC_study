

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of sync_240to80 is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- First Line
  signal cca_tog_on80_ff0     : std_logic;
  signal acc_end_tog_on80_ff0 : std_logic;
  signal rx_val_tog_on80_ff0  : std_logic;
  -- 2nd Line
  signal cca_tog_on80_ff1     : std_logic;
  signal acc_end_tog_on80_ff1 : std_logic;
  signal rx_val_tog_on80_ff1  : std_logic;
  -- 3rd Line
  signal cca_tog_on80_ff2     : std_logic;
  signal acc_end_tog_on80_ff2 : std_logic;
  signal rx_val_tog_on80_ff2  : std_logic;
  -- Registers from deserializer : CCA / RDATA or RX data
  signal memo_i_reg_on80     : std_logic_vector(11 downto 0);
  signal memo_q_reg_on80     : std_logic_vector(11 downto 0);
  -- Clk_switch Req
  signal clk_switch_req_tog_on80_ff0 : std_logic;
  signal clk_switch_req_tog_on80_ff1 : std_logic;
  signal clk_switch_req_tog_on80_ff2 : std_logic;
  -- Clk_switch
  signal clk_switched_tog_on80_ff0 : std_logic;
  signal clk_switched_tog_on80_ff1 : std_logic;
  signal clk_switched_tog_on80_ff2 : std_logic;
  -- Control Signals
  signal next_data_req_tog_on80_ff0  : std_logic;
  signal switch_ant_tog_on80_ff0     : std_logic;
  signal parity_err_tog_on80_ff0     : std_logic;
  signal parity_err_cca_tog_on80_ff0 : std_logic;
  -- Prot Err
  signal prot_err_on80_ff0 : std_logic;
  signal prot_err_on80_ff1 : std_logic;
  signal prot_err_on80_ff2 : std_logic;

  

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- Different Instantiation according to the clk44_possible_g generic
  -----------------------------------------------------------------------------
  -- When the 44 MHz clock is used instead of the 80 MHz, it is not possible to
  -- sample modem A data with it, as the resynchronization will take 3 periods
  -- and the data comes with 2 or 3 periods. In this case, the falling edge of
  -- the clock is needed.

  clk44_is_possible_gen : if clk44_possible_g = 1 generate
    falling_edge_sync_p : process (pclk, reset_n)
    begin  -- process falling_edge_sync_p
      if reset_n = '0' then             -- asynchronous reset (active low)
        rx_val_tog_on80_ff1  <= '0';
      elsif pclk'event and pclk = '0' then  -- falling clock edge !!!
        rx_val_tog_on80_ff1 <= rx_val_tog_on80_ff0;
      end if;
    end process falling_edge_sync_p;   
  end generate clk44_is_possible_gen;

  clk44_no_possible_gen : if clk44_possible_g = 0 generate
    rising_edge_sync_p : process (pclk, reset_n)
    begin  -- process falling_edge_sync_p
      if reset_n = '0' then             -- asynchronous reset (active low)
        rx_val_tog_on80_ff1  <= '0';
      elsif pclk'event and pclk = '1' then  -- rising clock edge !!!
        rx_val_tog_on80_ff1 <= rx_val_tog_on80_ff0;
      end if;
    end process rising_edge_sync_p;   
  end generate clk44_no_possible_gen;

  -----------------------------------------------------------------------------
  -- Synchronize data form deserializer
  -----------------------------------------------------------------------------
  sync80_data_p: process (pclk, reset_n)
  begin  -- process sync80_data_p
    if reset_n = '0' then              
      cca_tog_on80_ff0     <= '0';
      cca_tog_on80_ff1     <= '0';
      cca_tog_on80_ff2     <= '0';
      cca_on80_o           <= '0';
      acc_end_tog_on80_ff0 <= '0';
      acc_end_tog_on80_ff1 <= '0';
      acc_end_tog_on80_ff2 <= '0';
      acc_end_on80_o       <= '0';
      rx_val_tog_on80_ff0  <= '0';
      rx_val_tog_on80_ff2  <= '0';
      memo_i_reg_on80      <= (others => '0');
      memo_q_reg_on80      <= (others => '0');
    elsif pclk'event and pclk = '1' then 
      cca_tog_on80_ff0 <= cca_tog_on240_i;
      cca_tog_on80_ff1 <= cca_tog_on80_ff0;
      cca_tog_on80_ff2 <= cca_tog_on80_ff1;

      acc_end_tog_on80_ff0 <= acc_end_tog_on240_i;
      acc_end_tog_on80_ff1 <= acc_end_tog_on80_ff0;
      acc_end_tog_on80_ff2 <= acc_end_tog_on80_ff1;

      rx_val_tog_on80_ff0 <= rx_val_tog_on240_i;
      rx_val_tog_on80_ff2 <= rx_val_tog_on80_ff1;

      -- Get value when new and stable data
      if cca_tog_on80_ff1 /= cca_tog_on80_ff2  -- new CCA
        or acc_end_tog_on80_ff1 /= acc_end_tog_on80_ff2  -- RDDATA
        or rx_val_tog_on80_ff1 /= rx_val_tog_on80_ff2 then -- new RX data
        memo_i_reg_on80 <= memo_i_reg_on240_i;
        memo_q_reg_on80 <= memo_q_reg_on240_i;
      end if;

      -- From toggle, generate pulse
      cca_on80_o     <= cca_tog_on80_ff1  xor cca_tog_on80_ff2;
      acc_end_on80_o <= acc_end_tog_on80_ff1  xor acc_end_tog_on80_ff2;
      
    end if;
  end process sync80_data_p;
  -- Keep toggle
  rx_val_tog_on80_o <= rx_val_tog_on80_ff2;

  --------------------------------------
  -- Registers or CCA Access
  --------------------------------------
  -- Read Reg Return Example (HiSS protocole)
  --          _____ _____ _____ _____ _____ _____ _____ ____
  -- rf_txi  X_d0__X_d1__X_d2__X_d3__X_d4__X_d5__X_d6__X_d7_
  --          _____ _____ _____ _____ _____ _____ _____ ____
  -- rf_txq  X_d8__X_d9__X_d10_X_d11_X_d12_X_d13_X_d14_X_d15
  --
  -- data in on MSBs of deseria_q/deseria_i
  prdata_on80_o   <= memo_q_reg_on80(11 downto 4) & memo_i_reg_on80(11 downto 4);
  cca_info_on80_o <= memo_q_reg_on80(3 downto 1) & memo_i_reg_on80(3 downto 1);
  cca_add_info_on80_o <= memo_q_reg_on80(11 downto 4) & memo_i_reg_on80(11 downto 4);

  -- Datas (to rx paths)
  rx_i_on80_o <= memo_i_reg_on80;
  rx_q_on80_o <= memo_q_reg_on80;
  
  
  -----------------------------------------------------------------------------
  -- Synchronize control signals
  -----------------------------------------------------------------------------
  sync80_p: process (pclk, reset_n)
  begin  -- process sync80_p
    if reset_n = '0' then               
      next_data_req_tog_on80_ff0  <= '0';
      next_data_req_tog_on80_o    <= '0';
      switch_ant_tog_on80_ff0     <= '0';
      switch_ant_tog_on80_o       <= '0';
      parity_err_cca_tog_on80_ff0 <= '0';
      parity_err_cca_tog_on80_o   <= '0';
      parity_err_tog_on80_ff0     <= '0';
      parity_err_tog_on80_o       <= '0';
   elsif pclk'event and pclk = '1' then
      -- First Line of synchro
      next_data_req_tog_on80_ff0  <= next_data_req_tog_on240_i;
      switch_ant_tog_on80_ff0     <= switch_ant_tog_on240_i;
      parity_err_cca_tog_on80_ff0 <= parity_err_cca_tog_on240_i;
      parity_err_tog_on80_ff0     <= parity_err_tog_on240_i;
      -- Second Line of synchro
      next_data_req_tog_on80_o   <= next_data_req_tog_on80_ff0;
      switch_ant_tog_on80_o      <= switch_ant_tog_on80_ff0;
      parity_err_cca_tog_on80_o  <= parity_err_cca_tog_on80_ff0;
      parity_err_tog_on80_o      <= parity_err_tog_on80_ff0;
    end if;
  end process sync80_p;

  -----------------------------------------------------------------------------
  -- Clock Switch toggle -> pulse
  -----------------------------------------------------------------------------
  sync80_clk_switch_req_p: process (pclk, reset_n)
  begin  -- process sync80_clk_switched_p
    if reset_n = '0' then               
      clk_switch_req_tog_on80_ff0 <= '0';
      clk_switch_req_tog_on80_ff1 <= '0';
      clk_switch_req_tog_on80_ff2 <= '0';
      clk_switch_req_on80_o       <= '0';
    
    elsif pclk'event and pclk = '1' then 
      clk_switch_req_tog_on80_ff0 <= clk_switch_req_tog_on240_i;
      clk_switch_req_tog_on80_ff1 <= clk_switch_req_tog_on80_ff0;
      clk_switch_req_tog_on80_ff2 <= clk_switch_req_tog_on80_ff1;
      if clk_switch_req_tog_on80_ff1 /= clk_switch_req_tog_on80_ff2 then
        clk_switch_req_on80_o <= '1';
      else
        clk_switch_req_on80_o <= '0';  
      end if;
    end if;
  end process sync80_clk_switch_req_p;

  -----------------------------------------------------------------------------
  -- Clock Switch toggle -> pulse
  -----------------------------------------------------------------------------
  sync80_clk_switched_p: process (pclk, reset_n)
  begin  -- process sync80_clk_switched_p
    if reset_n = '0' then               
      clk_switched_tog_on80_ff0 <= '0';
      clk_switched_tog_on80_ff1 <= '0';
      clk_switched_tog_on80_ff2 <= '0';
      clk_switched_on80_o       <= '0';
    
    elsif pclk'event and pclk = '1' then 
      clk_switched_tog_on80_ff0 <= clk_switched_tog_on240_i;
      clk_switched_tog_on80_ff1 <= clk_switched_tog_on80_ff0;
      clk_switched_tog_on80_ff2 <= clk_switched_tog_on80_ff1;
      if clk_switched_tog_on80_ff1 /= clk_switched_tog_on80_ff2 then
        clk_switched_on80_o <= '1';
      else
        clk_switched_on80_o <= '0';  
      end if;
    end if;
  end process sync80_clk_switched_p;

  -----------------------------------------------------------------------------
  -- prot_err : long pulse -> 1 pulse
  -----------------------------------------------------------------------------
  sync80_prot_err_p: process (pclk, reset_n)
  begin  -- process sync80_prot_err_p
    if reset_n = '0' then               
      prot_err_on80_ff0 <= '0';
      prot_err_on80_ff1 <= '0';
      prot_err_on80_ff2 <= '0';
      prot_err_on80_o   <= '0';
      
    elsif pclk'event and pclk = '1' then  
      prot_err_on80_ff0 <= prot_err_on240_i;
      prot_err_on80_ff1 <= prot_err_on80_ff0;
      prot_err_on80_ff2 <= prot_err_on80_ff1;
      if prot_err_on80_ff1 = '1' and prot_err_on80_ff2 = '0' then
        prot_err_on80_o <= '1';
      else
        prot_err_on80_o <= '0';
      end if;      
    end if;
  end process sync80_prot_err_p;
  
end RTL;
