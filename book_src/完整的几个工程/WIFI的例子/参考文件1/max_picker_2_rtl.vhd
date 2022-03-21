
--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of max_picker_2 is

  signal index_o   : std_logic;
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  index   <= index_o;
  index_o <= '1' when (operande1 > operande0) else '0';
  max     <= operande1 when (index_o = '1') else operande0;
  
end rtl;
