
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem
--    ,' GoodLuck ,'      RCSfile: cck_mod.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : CCK Modulation
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/cck_mod/vhdl/rtl/cck_mod.vhd,v  
--  Log: cck_mod.vhd,v  
-- Revision 1.4  2002/07/04 08:39:53  Dr.B
-- unused shift_count removed.
--
-- Revision 1.3  2002/04/30 11:54:32  Dr.B
-- phy_data_req ; switched signal - enable => activate.
--
-- Revision 1.2  2002/03/06 13:58:48  Dr.B
-- '_number' => 'number' signals
--
-- Revision 1.1  2002/02/06 14:32:21  Dr.B
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
entity cck_mod is
  port (
    -- clock and reset
    clk                : in  std_logic;                    
    resetn             : in  std_logic;                   
     
    -- inputs
    cck_mod_in         : in  std_logic_vector (7 downto 2);
    --                   input data
    cck_mod_activate     : in  std_logic;
    --                   enable cck_mod block
    first_data         : in  std_logic;
    --                   indicate that the first data is sent (even data)
    new_data           : in  std_logic;
    --                   a new data is available and valid 
    phi_map            : in  std_logic_vector (1 downto 0);
    --                   for phi1 calculated from mapping
    shift_pulse        : in  std_logic;
    --                   reduce shift ferquency.
    -- outputs
    phi_out            : out std_logic_vector (1 downto 0)
  );

end cck_mod;
