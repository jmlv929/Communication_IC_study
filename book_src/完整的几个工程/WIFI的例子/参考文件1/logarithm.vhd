
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild modem
--    ,' GoodLuck ,'      RCSfile: logarithm.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Compute logarithm
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/agc_cca/vhdl/rtl/logarithm.vhd,v  
--  Log: logarithm.vhd,v  
-- Revision 1.3  2003/01/09 15:31:10  Dr.C
-- Changed constants to registers
--
-- Revision 1.2  2002/11/07 16:24:35  Dr.C
-- Added accoup input
--
-- Revision 1.1  2002/10/25 17:02:39  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;



--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity logarithm is
  generic (
    p_size_g : integer := 4);           -- size of power estimation
  port (
    -----------------------
    -- clock and reset
    -----------------------
    clk     : in std_logic;             -- System clock
    reset_n : in std_logic;
    
    -----------------------
    -- Registers
    -----------------------
    accoup  : in  std_logic_vector(4 downto 0);
    kilp    : in  std_logic_vector(3 downto 0);
    
    -----------------------
    -- Control
    -----------------------
    lna         : in  std_logic_vector(7 downto 0);  -- LNA value
    pgc         : in  std_logic_vector(7 downto 0);  -- PGC value
    logstart    : in  std_logic;                     -- Triggers the logarithm
    power_estim : in  std_logic_vector(p_size_g-1 downto 0);
                                                     -- power estimation
    icinput     : out std_logic_vector(7 downto 0)
    );

end logarithm;
