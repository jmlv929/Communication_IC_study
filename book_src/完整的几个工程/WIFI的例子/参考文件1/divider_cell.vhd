
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Euclidean Divider
--    ,' GoodLuck ,'      RCSfile: divider_cell.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Basic cell for a divider : substraction and output mux.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/eucl_divider/vhdl/rtl/divider_cell.vhd,v  
--  Log: divider_cell.vhd,v  
-- Revision 1.1  2003/04/24 07:33:19  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity divider_cell is
  generic (
    dsize_g  : integer := 7
    );
  port (
    d_in  : in  std_logic_vector(dsize_g-1 downto 0); -- Divisor.
    z_in  : in  std_logic_vector(dsize_g downto 0);   -- Dividend.
    --
    q_out : out std_logic;                            -- Quotient.
    s_out : out std_logic_vector(dsize_g downto 0)    -- Remainder.
    );

end divider_cell;
