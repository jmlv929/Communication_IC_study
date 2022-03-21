
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: tx_activ_gen.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Generate the tx_activate : add a delay of txenddel_reg clock cycles
-- from the tx_activated of the tx_path_core.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/modem_sm_b/vhdl/rtl/tx_activ_gen.vhd,v  
--  Log: tx_activ_gen.vhd,v  
-- Revision 1.1  2003/11/03 15:07:52  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity tx_activ_gen is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    hresetn             : in  std_logic; -- AHB reset line.
    hclk                : in  std_logic; -- AHB clock line.
    --------------------------------------
    -- Signals
    --------------------------------------
    txenddel_reg        : in  std_logic_vector(7 downto 0);
    tx_acti_tx_path     : in  std_logic; -- tx_activate from tx_path_core
    tx_activated_long   : out std_logic  -- tx_activate longer of txenddel_reg periods
    
  );

end tx_activ_gen;
