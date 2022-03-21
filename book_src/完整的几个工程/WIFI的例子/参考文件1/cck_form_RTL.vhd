

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of cck_form is

  ------------------------------------------------------------------------------
  -- Type
  ------------------------------------------------------------------------------
  type CCK_STATE is  ( idle,          -- idle phase
                       wait_req,      -- wait for a phy_data_req
                       wait_pulse,    -- wait for the shift_pulse bef memo
                       memo1,         -- memorization 1st byte
                       count1,        -- count between tranfers
                       memo2,         -- memorization 2nd byte
                       count2         -- count between tranfers
                         );    
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal cck_8bits_reg      : std_logic_vector (7 downto 0);
  --                          registered input from the buffer 
  signal cck_4bits          : std_logic_vector (3 downto 0);
  --                          4 bits to modulate (5.5Mbit/s mode) (1st or 2nd)
  signal wait_count         : std_logic_vector (2 downto 0);
  --                          counter to determine the 4 bits to send (1 or 2)
  signal phy_data_conf_int  : std_logic; -- internal value of phy_data_conf
  signal memo_phy_data_req  : std_logic; -- memorize phy_data_req
  signal trans_part         : std_logic; -- part of 5.5Mb/s trans : 0=1st  1=2nd 
  signal cck_cur_state      : CCK_STATE;
  signal cck_next_state     : CCK_STATE;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  ------------------------------------------------------------------------------
  -- State Machine
  ------------------------------------------------------------------------------
  cck_next_state_p : process (cck_cur_state, cck_form_activate, cck_speed,
                              memo_phy_data_req, phy_data_req, shift_pulse,
                              wait_count, txv_immstop)
  begin
    case cck_cur_state is

      -- idle State: the cck_form is disabled
      when idle => 
        if cck_form_activate = '1' and txv_immstop = '0' then
          cck_next_state  <= wait_req;   
        else
          cck_next_state  <= idle;
        end if;

      -- wait_req State: wait for phy_data_req
      when wait_req =>        
        if cck_form_activate = '0' or txv_immstop = '1' then
          cck_next_state  <= idle;   
        elsif phy_data_req /= memo_phy_data_req then
          if shift_pulse = '1' then
            cck_next_state  <= memo1;
          else
            cck_next_state <= wait_pulse;
          end if;
        else
          cck_next_state  <= wait_req;
        end if;

      -- wait for the shift pulse before memorization
      when wait_pulse =>
        if txv_immstop = '1' then
          cck_next_state  <= idle;
        elsif shift_pulse = '1' then
          cck_next_state <= memo1;
        else
          cck_next_state <= wait_pulse;
        end if;

      -- memo State: memorization 
      when memo1 =>
        if txv_immstop = '1' then
          cck_next_state  <= idle;
        else
          cck_next_state  <= count1;
          -- if the block is disabled, it finishes the last byte.
        end if;
 
      -- count State: store data during 8 or 16 periods
      when count1 =>
        if txv_immstop = '1' then
          cck_next_state  <= idle;
        elsif wait_count = "0000" and shift_pulse = '1'  then
          if cck_speed = '0' then
              cck_next_state  <= memo2;
          elsif cck_form_activate = '1' then
            if memo_phy_data_req /= phy_data_req  then
              -- a new ask of transfer
              cck_next_state  <= memo1;
            else
              cck_next_state  <= wait_req;
            end if;
          else
            cck_next_state   <= idle;
          end if;
        else
          cck_next_state  <= count1;
          -- even if the block is disabled, it finishes the last byte.  
        end if;
        
      when memo2 =>
        if txv_immstop = '1' then
          cck_next_state  <= idle;
        else
          cck_next_state  <= count2;
          -- if the block is disabled, it finishes the last byte.  
        end if;
        
      -- count State: store data during 8 or 16 periods
      when count2 =>
        if txv_immstop = '1' then
          cck_next_state  <= idle;
        elsif wait_count = "0000" and shift_pulse = '1'  then
          if cck_form_activate = '1' then
            if memo_phy_data_req /= phy_data_req  then
              -- a new ask of transfer
              cck_next_state  <= memo1;
            else
              cck_next_state  <= wait_req;
            end if;
          else
            cck_next_state   <= idle;
          end if;
        else
          cck_next_state  <= count2;
          -- if the block is disabled, it finishes the last byte.  
        end if;
        
      when others =>
        cck_next_state   <= idle;
    end case;
  end process cck_next_state_p;
  ------------------------------------------------------------------------------
  state_p : process (clk, resetn)
  begin
    if (resetn = '0') then
      cck_cur_state <= idle;
    elsif clk'event and clk = '1' then
      cck_cur_state <= cck_next_state;
    end if;
  end process state_p;
  
  ------------------------------------------------------------------------------
  -- Data Memorisation Process  + phy_data_conf answer
  --  For 5.5 Mbits/s : alternate data 4bits <--> 4bits 
  ------------------------------------------------------------------------------
  data_req_proc : process (clk, resetn)
  begin
    if resetn = '0' then
      wait_count        <= (others => '0');
      cck_8bits_reg     <= (others => '0');
      phy_data_conf_int <= '0';
      memo_phy_data_req <= '0';
      scramb_reg        <= '0';
      new_data          <= '0';
      first_data        <= '0';
      shift_mapping     <= '0';
      trans_part        <= '0';
      fol_bl_activate   <= '0';
      
    elsif (clk'event and clk = '1') then
      scramb_reg    <= '0';
      new_data      <= '0';
      first_data    <= '0';
      shift_mapping <= '0';
      trans_part    <= '0';
      fol_bl_activate <= '1';

      case cck_next_state is
        when idle =>
          -- following blocks are enabled when the cck_form works 
          --   (+1 per to finish sending data) 
          fol_bl_activate   <= '0';
          phy_data_conf_int <= '0';

        when wait_req =>
          phy_data_conf_int <= '0';
          memo_phy_data_req <= '0';     -- set the 1st value to compare
          first_data <= '1';

        when memo1 =>
          wait_count        <= "111";         
          -- memorisation
          cck_8bits_reg     <= cck_form_in;
          phy_data_conf_int <= not phy_data_conf_int;
          scramb_reg        <= '1';
          memo_phy_data_req <= phy_data_req;
          new_data          <= '1';

        when memo2 =>
          wait_count <= "111";
          new_data   <= '1';
          trans_part <= '1';

        when count1 =>
          if shift_pulse = '1' then
            if wait_count (2 downto 0) = "111"  then
              -- last data to save in mapping block
              -- before a new data arrives (1000 or 0000) 
              shift_mapping <= '1';
            end if;
            wait_count <= wait_count - 1;
          end if;

        when count2 =>
          trans_part <= '1';
          if shift_pulse = '1' then
            if wait_count (2 downto 0) = "111"  then
              -- last data to save in mapping block
              -- before a new data arrives (1000 or 0000) 
              shift_mapping <= '1';
            end if;
            wait_count <= wait_count - 1;
          end if;

        when others => null;
      end case;
    end if;
  end process;

  phy_data_conf <= phy_data_conf_int;
  
  -- data for 5.5Mbits/s transmission: 
  cck_4bits <= cck_8bits_reg (3 downto 0) when 
                    trans_part = '0' -- first part of 5.5 Mb/s transmission
          else cck_8bits_reg (7 downto 4); -- second part
  
  -- output data: 
  cck_form_out <= cck_8bits_reg when cck_speed = '1'                 --11 Mb/s
             else '0' &cck_4bits(3) & "001" & cck_4bits (2 downto 0);--5.5 Mb/s
  
 
end RTL;
