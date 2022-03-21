
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: magnitude_gen.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.3  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Generate Magnitude
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/preprocessing/vhdl/rtl/magnitude_gen.vhd,v  
--  Log: magnitude_gen.vhd,v  
-- Revision 1.3  2004/05/28 09:49:43  Dr.C
-- Change < to <=.
--
-- Revision 1.2  2003/06/25 17:02:19  Dr.B
-- change name of the process.
--
-- Revision 1.1  2003/03/27 16:36:51  Dr.B
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
use ieee.std_logic_arith.all; 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity magnitude_gen is
  generic (
    size_in_g : integer := 16);
  port (
    --------------------------------------
    -- Signals
    --------------------------------------
    data_in_i : in  std_logic_vector(size_in_g -1 downto 0);
    data_in_q : in  std_logic_vector(size_in_g -1 downto 0);
    --
    mag_out  : out std_logic_vector(size_in_g -1 downto 0)
    
  );

end magnitude_gen;
