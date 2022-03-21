
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem
--    ,' GoodLuck ,'      RCSfile: spreading.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Direct Sequence Spread Spectrum Modulation
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/spreading/vhdl/rtl/spreading.vhd,v  
--  Log: spreading.vhd,v  
-- Revision 1.2  2002/04/30 12:23:14  Dr.B
-- enable => activate.
--
-- Revision 1.1  2002/02/06 14:30:08  Dr.B
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

--library mapping_rtl;
library work;
--use mapping_rtl.functions_pkg.all;
use work.functions_pkg.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity spreading is
  port (
    -- clock and reset
    clk             : in  std_logic;                    
    resetn          : in  std_logic;    
    
    -- inputs
    spread_activate : in  std_logic;  
    --                activate the spreading block.
    spread_init     : in  std_logic;  
    --                initialize the spreading block
    --                the first value is sent. spread_activate should be high
    phi_map         : in  std_logic_vector (1 downto 0); 
    --                spreading input
    spread_disb     : in std_logic;
    --                disable the scrambler when high (for modem tests) 
    shift_pulse     : in  std_logic;
    --                reduce shift ferquency.

    
    -- outputs
    phi_out      : out std_logic_vector (1 downto 0) 
    --             spreading output   
  );

end spreading;
