

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of keymix_phase1 is
  
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------  
  -- Select register input to use.
  signal sel_ttak_w        : std_logic_vector(15 downto 0);
  -- Select two bytes of temporal key to use.
  signal temp_key_b0       : std_logic_vector(15 downto 0);
  signal temp_key_b1       : std_logic_vector(15 downto 0);
  signal temp_key_b2       : std_logic_vector(15 downto 0);
  signal temp_key_b3       : std_logic_vector(15 downto 0);


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin  
  
  --------------------------------------------
  -- Phase 1 key mixing
  --------------------------------------------
  -- This process selects the byte of the temporal key to use, depending on the
  -- FSM state (even or odd).
  temp_key_pr: process(in_even_state, temp_key_w0, temp_key_w1, temp_key_w2,
                       temp_key_w3)
  begin    
    case in_even_state is
      
      -- In even states, use temporal key words lower byte.
      when '1' =>
        temp_key_b0 <= temp_key_w0(15 downto 0);
        temp_key_b1 <= temp_key_w1(15 downto 0);
        temp_key_b2 <= temp_key_w2(15 downto 0);
        temp_key_b3 <= temp_key_w3(15 downto 0);
        
      -- In odd states, use temporal key words upper byte.
      when others =>
        temp_key_b0 <= temp_key_w0(31 downto 16);
        temp_key_b1 <= temp_key_w1(31 downto 16);
        temp_key_b2 <= temp_key_w2(31 downto 16);
        temp_key_b3 <= temp_key_w3(31 downto 16);
        
    end case;
  end process temp_key_pr;
  
  -- This process controls the S-Boxes address lines depending on the FSM state
  -- (even or odd). It also defines the value to add in the TTAK register.
  sbox_addr_pr: process(keymix_reg_w0, keymix_reg_w1, keymix_reg_w2,
                        keymix_reg_w3, keymix_reg_w4, loop_cnt, state_cnt,
                        temp_key_b0, temp_key_b1, temp_key_b2, temp_key_b3)
  begin    
    case loop_cnt is
      
      when "000" =>
        sbox_addr  <= keymix_reg_w4 xor temp_key_b0;
        sel_ttak_w <= keymix_reg_w0;
      when "001" =>
        sbox_addr  <= keymix_reg_w0 xor temp_key_b1;
        sel_ttak_w <= keymix_reg_w1;
      when "010" =>
        sbox_addr  <= keymix_reg_w1 xor temp_key_b2;
        sel_ttak_w <= keymix_reg_w2;
      when "011" =>
        sbox_addr  <= keymix_reg_w2 xor temp_key_b3;
        sel_ttak_w <= keymix_reg_w3;
      when others =>
        sbox_addr  <= keymix_reg_w3 xor temp_key_b0;
        sel_ttak_w <= keymix_reg_w4 + state_cnt;
                
    end case;
  end process sbox_addr_pr;
  
  -- At each step, accumulate the S-Box output in TTAK registers.
  next_keymix_reg_w <= sel_ttak_w + sbox_data;  

end RTL;
