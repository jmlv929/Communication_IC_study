

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of mac_interface is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type MACINT_STATE_T is (wait_ready_state, wait_data_state, send_data_state);

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal macint_state         : MACINT_STATE_T;
  signal macint_next_state    : MACINT_STATE_T;
  signal tx_data_conf_int     : std_logic;
  signal tx_start_end_req_ff  : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- This process delays tx_start_end_req_i for edge detection
  delay_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      tx_start_end_req_ff  <= '0';
    elsif clk'event and clk = '1' then
      if enable_i = '0' then
        tx_start_end_req_ff  <= '0';
      else
        tx_start_end_req_ff  <= tx_start_end_req_i;
      end if;
    end if;
  end process delay_p;


  --------------------------------------------
  -- MAC interface state machine
  --------------------------------------------

  -- This process describes a two-states FSM. The FSM is in wait_data_state
  -- when waiting for the beginning of a transmission or for the next data 
  -- to transmit. Then it goes to send_data_state and stays there until the
  -- data has been acknowledged by the next block (data_ready_i = '1').
  macint_fsm_comb_p : process (data_ready_i, macint_state, tx_data_conf_int,
                               tx_data_req_i, tx_start_end_conf_i,
                               tx_start_end_req_ff, tx_start_end_req_i)
  begin

    case macint_state is

      when wait_data_state =>
        -- tx_start_end_conf_i = '1' when the device is answering a TX request.
        -- When a data request is pending, go to send_data state.
        if tx_start_end_conf_i = '1' 
        and ( tx_data_req_i = not(tx_data_conf_int) ) then
          macint_next_state   <= send_data_state;
        else          
          macint_next_state   <= wait_data_state;
        end if;

      when send_data_state =>
        -- tx_start_end_req_i rising edge indicates the beginning of a TX
        -- -> back to wait state, to wait for tx_start_end_conf_i.
        -- data_ready_i = 1 indicates the next block is ready to receive new 
        -- data -> back to wait state, to wait for tx_data_req_i.
        if (tx_start_end_req_i = '1' and tx_start_end_req_ff = '0') then
          macint_next_state   <= wait_data_state;
        else          
          macint_next_state   <= wait_ready_state;
        end if;

      when wait_ready_state =>
        -- tx_start_end_req_i rising edge indicates the beginning of a TX
        -- -> back to wait state, to wait for tx_start_end_conf_i.
        -- data_ready_i = 1 indicates the next block is ready to receive new 
        -- data -> back to wait state, to wait for tx_data_req_i.
        if (tx_start_end_req_i = '1' and tx_start_end_req_ff = '0') then
          macint_next_state   <= wait_data_state;
        else
          if data_ready_i = '1' then
            if ( tx_data_req_i = not(tx_data_conf_int) ) then
              macint_next_state   <= send_data_state;
            else
              macint_next_state   <= wait_data_state;
            end if;
          else
            macint_next_state   <= wait_ready_state;
          end if;
        end if;

      when others =>
        macint_next_state <= wait_data_state;
        
    end case;

  end process macint_fsm_comb_p;

  -- FSM seq process
  macint_fsm_seq_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      macint_state  <= wait_data_state;
    elsif clk'event and clk = '1' then
      if enable_i = '0' then
        macint_state  <= wait_data_state;
      else
        macint_state  <= macint_next_state;
      end if;
    end if;
  end process macint_fsm_seq_p;


  -- This process updates the control signals:
  -- -> tx_data_conf_int is inverted and data_o is sent when the FSM enters
  -- send_data_state,
  -- -> data_valid_o is sent one clock cycle after data_o.
  ctrl_p: process (clk, reset_n)
  begin
    if reset_n = '0' then
      tx_data_conf_int <= '0';
      data_o           <= (others => '0');
      data_valid_o     <= '0';

    elsif clk'event and clk = '1' then

      case macint_next_state is

        when wait_data_state =>
          -- Reset tx_data_conf at the beginning of the transmission.
          if tx_start_end_req_i = '1' and tx_start_end_req_ff = '0' then
            tx_data_conf_int   <= '0';
          end if;
          
          data_valid_o  <= '0';

        when send_data_state =>
          if enable_i = '1' then 
            data_valid_o  <= '1';
            -- The FSM is about to change from wait_data_state to send_data_state:
            -- update tx_data_conf and send data_o.
            if (macint_state = wait_data_state)
              or (macint_state = wait_ready_state) then 
              tx_data_conf_int <= not(tx_data_conf_int);
              data_o           <= tx_data_i;
            end if;
          end if;

        when wait_ready_state =>
          if enable_i = '1' then 
            data_valid_o  <= '1';
          end if;

        when others => null;

      end case;
      
    end if;
  end process ctrl_p;
  tx_data_conf_o <= tx_data_conf_int;


end RTL;
