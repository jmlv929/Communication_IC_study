
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: ofdm_preamble_detector.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : OFDM Preamble Presence Detector
--               This block increments a counter when a .11a short training 
--               symbols is detected without a subsequent valid Signal field.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/ofdm_preamble_detector/vhdl/rtl/ofdm_preamble_detector.vhd,v  
--  Log: ofdm_preamble_detector.vhd,v  
-- Revision 1.1  2005/01/12 16:21:11  Dr.J
-- #BugId:727#
-- initial release
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_unsigned.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity ofdm_preamble_detector is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n      : in  std_logic;
    clk          : in  std_logic;
    --------------------------------------
    -- Controls
    --------------------------------------
    reg_rstoecnt   : in  std_logic;
    a_b_mode       : in  std_logic;
    cp2_detected   : in  std_logic;
    rxe_errorstat  : in  std_logic_vector(1 downto 0);
    phy_cca_ind    : in  std_logic;
    ofdmcoex       : out std_logic_vector(7 downto 0)
  );

end ofdm_preamble_detector;
