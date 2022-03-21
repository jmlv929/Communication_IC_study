
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : CRC
--    ,' GoodLuck ,'      RCSfile: crc32_8.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description :  Parallel (8 input bits) Cyclic Redundancy Check 32
--                with the polynomial: 
--                G(x) = X^32 + X^26 + X^23 + X^22 + X^16 + X^12 + X^11 + X^10
--                     + X^8  + X^7  + X^5  + X^4  + X^2  + X    + 1
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/crc32/vhdl/rtl/crc32_8.vhd,v  
--  Log: crc32_8.vhd,v  
-- Revision 1.2  2002/02/05 15:46:53  Dr.B
-- 4 outputs.
--
-- Revision 1.1  2001/12/13 13:12:19  Dr.B
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
entity crc32_8 is
  port (
    -- clock and reset
    clk          : in  std_logic;                    
    resetn       : in  std_logic;                   
     
    -- inputs
    data_in      : in  std_logic_vector ( 7 downto 0);
    --             8-bits inputs for parallel computing. 
    ld_init      : in  std_logic;
    --             initialize the CRC
    calc         : in  std_logic;
    --             ask of calculation of the available data.
 
    -- outputs
    crc_out_1st  : out std_logic_vector (7 downto 0); 
    crc_out_2nd  : out std_logic_vector (7 downto 0); 
    crc_out_3rd  : out std_logic_vector (7 downto 0); 
    crc_out_4th  : out std_logic_vector (7 downto 0) 
    --          CRC result
   );

end crc32_8;
