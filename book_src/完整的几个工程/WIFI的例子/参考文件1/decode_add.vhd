
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: decode_add.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.7   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Decode on apb access to wild rf, info needed by the HiSS
-- States Machines (clk_switch_req)
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/decode_add.vhd,v  
--  Log: decode_add.vhd,v  
-- Revision 1.7  2005/01/06 14:47:11  sbizet
-- #BugId:577#
-- Removed bank register memorization
--
-- Revision 1.6  2004/10/25 14:25:11  sbizet
-- #BugId:782#
-- Increased counter size for wildref_clockreset 1.2 compliant with WILD EAGLE 1.2
--
-- Revision 1.5  2004/04/21 08:22:17  Dr.B
-- add a memorization of the bank register.
--
-- Revision 1.4  2003/11/26 13:58:15  Dr.B
-- decode_add is now running at 240 MHz.
--
-- Revision 1.3  2003/10/09 08:20:31  Dr.B
-- remove unused detection.
--
-- Revision 1.2  2003/09/25 12:18:48  Dr.B
-- remove cca detection.
--
-- Revision 1.1  2003/07/21 09:53:56  Dr.B
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
entity decode_add is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                   : in  std_logic; 
    reset_n               : in  std_logic;  
    --------------------------------------
    -- Signals
    --------------------------------------
    hiss_enable_n_i       : in  std_logic;  -- enable hiss block
    apb_access_i          : in  std_logic;  -- ask of apb access (wr or rd)
    wr_nrd_i              : in  std_logic;  -- wr_nrd = '1' => write access
    add_i                 : in  std_logic_vector( 5 downto 0);
    wrdata_i              : in  std_logic_vector(15 downto 0);
    clk_switched_i        : in  std_logic;  -- clk switched.
    
    clk_switch_req_tog_o  : out std_logic;  -- toggle:ask of clock switching (decoded from write_reg)
    clk_switch_req_o      : out std_logic;  -- ask of clock switching (decoded from write_reg)
    clk_div_o             : out std_logic_vector(2 downto 0);
    back_from_deep_sleep_o : out std_logic  -- pulse when back to deep sleep
    
  );

end decode_add;
