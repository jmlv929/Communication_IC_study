

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of shift_param_gen is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Absolute Value
  signal i_abs       : std_logic_vector (data_size_g-1 downto 0);
  signal q_abs       : std_logic_vector (data_size_g-1 downto 0);
  signal max_abs     : std_logic_vector (data_size_g-1 downto 0);
  signal max_val_reg : std_logic_vector (data_size_g-1 downto 0);


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- Get Absolute Value
  -----------------------------------------------------------------------------
  i_abs <= i_i when i_i(i_i'high) = '0'
      else (-signed(i_i)); 

  q_abs <= q_i when q_i(q_i'high) = '0'
      else (-signed(q_i));

  max_abs <= i_abs when i_abs > q_abs
        else q_abs;

  -----------------------------------------------------------------------------
  -- Memorize the biggest value
  -----------------------------------------------------------------------------
  get_max_p: process (clk, reset_n)
  begin  -- process get_max_p
    if reset_n = '0' then              
      max_val_reg <= (others => '0');
    elsif clk'event and clk = '1' then  
      if init_i = '1' then
        max_val_reg <= (others => '0');
      elsif data_valid_i = '1' then
        if max_abs > max_val_reg then
          max_val_reg <= max_abs; -- this is the new max.    
        end if;  
      end if;
    end if;
  end process get_max_p;

  -----------------------------------------------------------------------------
  -- Generate shift_parameter
  -----------------------------------------------------------------------------
  shift_param_p: process (clk, reset_n)
  begin  -- process shift_param_p
    if reset_n = '0' then               
      shift_param_o <= (others => '0');
    elsif clk'event and clk = '1' then  
      if cp2_detected_i = '1' then
        -- time to analyze the max_val_reg
        if max_val_reg(max_val_reg'high downto max_val_reg'high-5)= "000000" then
          shift_param_o <= "000"; -- no LSB to remove
        elsif max_val_reg(max_val_reg'high downto max_val_reg'high-4)= "00000" then
          shift_param_o <= "001"; -- 1 LSB to remove
        elsif max_val_reg(max_val_reg'high downto max_val_reg'high-3)= "0000" then
          shift_param_o <= "010"; -- 2 LSB to remove
        elsif max_val_reg(max_val_reg'high downto max_val_reg'high-2)= "000" then
          shift_param_o <= "011"; -- 3 LSB to remove
        elsif max_val_reg(max_val_reg'high downto max_val_reg'high-1)= "00" then
          shift_param_o <= "100"; -- 4 LSB to remove
        else
          shift_param_o <= "101"; -- 5 LSB to remove
        end if;
      end if;
    end if;
  end process shift_param_p;
end RTL;
