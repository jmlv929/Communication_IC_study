
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: kalman_lut.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Look up table for coefficient
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/residual_dc_offset/vhdl/rtl/kalman_lut.vhd,v  
--  Log: kalman_lut.vhd,v  
-- Revision 1.2  2005/01/26 09:23:05  Dr.C
-- #BugId:986#
-- Updated Kalman filter coeff and resynchronized m_i and m_q for synthesis.
--
-- Revision 1.1  2005/01/19 17:08:25  Dr.C
-- #BugId:737#
-- First revision.
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity kalman_lut is
  port (
    k_index : in std_logic_vector(5 downto 0);
    k_o  : out std_logic_vector(9 downto 0);
    km_o : out std_logic_vector(9 downto 0)
    );

end kalman_lut;
