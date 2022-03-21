
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: arctan_lut.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Look-up table for arctan(2^-i) values.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/cordic_vect/vhdl/rtl/arctan_lut.vhd,v  
--  Log: arctan_lut.vhd,v  
-- Revision 1.2  2003/04/03 13:43:22  Dr.B
-- add scaling_g generic + arctan table for scaling.
--
-- Revision 1.1  2002/03/28 12:41:49  Dr.A
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
entity arctan_lut is
  generic (
    dsize_g       : integer := 32;                    -- max value = 32.
    scaling_g     : integer := 0   -- 1:Use all the amplitude (pi/2 = 2^errosize_g=~ 01111....) 
  );                               -- (-pi/2 = -2^errosize_g= 100000....) 
  port (
    index   : in  std_logic_vector(4 downto 0); -- i value.
    arctan  : out std_logic_vector(dsize_g-1 downto 0)
  );
 

end arctan_lut;
