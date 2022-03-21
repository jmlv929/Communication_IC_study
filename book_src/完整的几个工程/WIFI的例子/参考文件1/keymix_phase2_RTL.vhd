

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of keymix_phase2 is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- Detect when the last 16bit word has been updated.
  constant MAX_LOOP_CT : std_logic_vector(2 downto 0) := "101";
  
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Signals to compute the next value to register.
  signal add_ppk_w              : std_logic_vector(15 downto 0);
  signal ppk_rot_w              : std_logic_vector(15 downto 0);
  signal sel_ppk_w              : std_logic_vector(15 downto 0);
  signal int_next_keymix_reg_w  : std_logic_vector(15 downto 0);
  

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  --------------------------------------------
  -- Phase 2 key mixing
  --------------------------------------------

  -- This process controls the S-Boxes address lines depending on the FSM state
  -- loop counter. It also defines signals used to add in the PPK register.
  sel_ppk_pr : process(keymix_reg_w0, keymix_reg_w1, keymix_reg_w2,
                       keymix_reg_w3, keymix_reg_w4, keymix_reg_w5, loop_cnt,
                       temp_key_w0, temp_key_w1, temp_key_w2, temp_key_w3)
    variable ppk_rot_v : std_logic_vector(15 downto 0);
  begin
    case loop_cnt  is
      when "000" =>
        sbox_addr <= keymix_reg_w5 xor temp_key_w0(15 downto 0);
        ppk_rot_v := keymix_reg_w5 xor temp_key_w3(15 downto 0);
        ppk_rot_w <= ppk_rot_v(0) & ppk_rot_v(15 downto 1);
        sel_ppk_w <= keymix_reg_w0;
      when "001" =>
        sbox_addr <= keymix_reg_w0 xor temp_key_w0(31 downto 16);
        ppk_rot_v := keymix_reg_w0 xor temp_key_w3(31 downto 16);
        ppk_rot_w <= ppk_rot_v(0) & ppk_rot_v(15 downto 1);
        sel_ppk_w <= keymix_reg_w1;
      when "010" =>
        sbox_addr <= keymix_reg_w1 xor temp_key_w1(15 downto 0);
        ppk_rot_w <= keymix_reg_w1(0) & keymix_reg_w1(15 downto 1);
        sel_ppk_w <= keymix_reg_w2;
      when "011" =>
        sbox_addr <= keymix_reg_w2 xor temp_key_w1(31 downto 16);
        ppk_rot_w <= keymix_reg_w2(0) & keymix_reg_w2(15 downto 1);
        sel_ppk_w <= keymix_reg_w3;
      when "100" =>
        sbox_addr <= keymix_reg_w3 xor temp_key_w2(15 downto 0);
        ppk_rot_w <= keymix_reg_w3(0) & keymix_reg_w3(15 downto 1);
        sel_ppk_w <= keymix_reg_w4;
      when others =>
        sbox_addr <= keymix_reg_w4 xor temp_key_w2(31 downto 16);
        ppk_rot_w <= keymix_reg_w4(0) & keymix_reg_w4(15 downto 1);
        sel_ppk_w <= keymix_reg_w5;
    end case;
  end process sel_ppk_pr;

  with in_even_state select
    add_ppk_w <= 
      sbox_data when '1',
      ppk_rot_w when others;
      
  -- At each step, accumulate the S-Box output or ppk_rot_w in PPK registers.
  int_next_keymix_reg_w <= sel_ppk_w + add_ppk_w;
  next_keymix_reg_w     <= int_next_keymix_reg_w;
  
    
  -- Assign output ports.
  tkip_key_w3 <= keymix_reg_w5 & keymix_reg_w4;
  tkip_key_w2 <= keymix_reg_w3 & keymix_reg_w2;
  tkip_key_w1 <= keymix_reg_w1 & keymix_reg_w0;
  
  -- Register tkip_key_w0 (not directly taken from internal registers).
  rc4key0_pr: process (clk, reset_n)
    variable tkip_key_w0_msb_v : std_logic_vector(15 downto 0);
  begin
    if reset_n = '0' then
      tkip_key_w0_msb_v := (others => '0');
      tkip_key_w0 <= (others => '0');
    elsif clk'event and clk = '1' then
      if in_even_state = '0' and loop_cnt = MAX_LOOP_CT then
        tkip_key_w0_msb_v := int_next_keymix_reg_w xor temp_key_w0(15 downto 0);
        tkip_key_w0 <= tkip_key_w0_msb_v(8 downto 1)
                      & tsc_lsb(7 downto 0)
                      & '0' & tsc_lsb(14) & '1'& tsc_lsb(12 downto 8)
                      & tsc_lsb(15 downto 8);        
      end if;
    end if;
  end process rc4key0_pr;

end RTL;
