

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of tx_activ_gen is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- signals for generating tx_activated
  signal tx_acti_tx_path_ff0 : std_logic;
  signal activate_counter    : std_logic_vector(7 downto 0); 


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  -- The tx_activate from the tx_path_core must be prolongated by the delay of
  -- the front-end.
  --
  --                 __________________________          
  -- tx_acti_tx_path                           \____________________
  --                    _________________________
  -- tx_acti_tx_path_ff0                         \__________________
  --                   ___________________________ _ _ _ _ ___________
  -- activate_counter  ___________0_______________X4X3X2X1X_____0_____
  --                   _____________________________________
  -- tx_activate_long                                       \_________
  
  tx_activated_p: process (hclk, hresetn)
  begin  -- process tx_activated_p
    if hresetn = '0' then
      tx_acti_tx_path_ff0 <= '0';
      tx_activated_long   <= '0';
      activate_counter    <= (others => '0');
    elsif hclk'event and hclk = '1' then
      tx_acti_tx_path_ff0 <= tx_acti_tx_path;
      -- *** Counter *** 
      if tx_acti_tx_path = '0' and tx_acti_tx_path_ff0 = '1' then
        -- last data has been sent => init with max val
        activate_counter <= txenddel_reg;
      elsif activate_counter /= "00000" then
        -- count down
        activate_counter <= activate_counter - '1';        
      end if;

      -- *** tx_activated gen ***
      if tx_acti_tx_path = '1' or tx_acti_tx_path_ff0 = '1'
        or activate_counter /= "00000" then
        tx_activated_long <= '1';
      else
        tx_activated_long <= '0';
      end if;
    end if;
  end process tx_activated_p;



end RTL;
