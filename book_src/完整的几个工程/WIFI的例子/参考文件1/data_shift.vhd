
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: data_shift.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Right shift input data of a number of bits
--               given in an input register (max 15).
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/phase_estimation/vhdl/rtl/data_shift.vhd,v  
--  Log: data_shift.vhd,v  
-- Revision 1.2  2002/05/02 07:40:43  Dr.A
-- Added work-around for Synopsys synthesis.
--
-- Revision 1.1  2002/03/28 12:42:05  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity data_shift is
  generic (
    dsize_g : integer := 30 -- Data size
  );
  port (
    shift_reg      : in  std_logic_vector(3 downto 0);
    data_in        : in  std_logic_vector(dsize_g-1 downto 0);
    --
    shifted_data   : out std_logic_vector(dsize_g+14 downto 0)
  );

end data_shift;
