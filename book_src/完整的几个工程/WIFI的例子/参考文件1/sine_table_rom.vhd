
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: sine_table_rom.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Sine table ROM. 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/sine_table_rom/vhdl/rtl/sine_table_rom.vhd,v  
--  Log: sine_table_rom.vhd,v  
-- Revision 1.1  2003/03/13 15:26:19  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity sine_table_rom is
  port (
     addr_i   : in  std_logic_vector(9 downto 0); -- input angle
     sin_o    : out std_logic_vector(9 downto 0)  -- output sine
  );

end sine_table_rom;
