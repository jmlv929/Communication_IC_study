
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem
--    ,' GoodLuck ,'      RCSfile: crc16_8.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description :  Parallel (8 input bits) Cyclic Redundancy Check 16
--                with the polynomial: G(x) = X^16 + X^12 + X^5 + 1
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/crc16_8/vhdl/rtl/crc16_8.vhd,v  
--  Log: crc16_8.vhd,v  
-- Revision 1.2  2002/01/29 16:05:04  Dr.B
-- bit reversal added.
--
-- Revision 1.1  2001/12/11 15:35:42  Dr.B
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
entity crc16_8 is
  port (
    -- clock and reset
    clk       : in  std_logic;                    
    resetn    : in  std_logic;                   
     
    -- inputs
    data_in   : in  std_logic_vector ( 7 downto 0);
    --          8-bits inputs for parallel computing. 
    ld_init   : in  std_logic;
    --          initialize the CRC
    calc      : in  std_logic;
    --          ask of calculation of the available data.
 
    -- outputs
    crc_out_1st  : out std_logic_vector (7 downto 0); 
    crc_out_2nd  : out std_logic_vector (7 downto 0) 
    --          CRC result
   );

end crc16_8;
