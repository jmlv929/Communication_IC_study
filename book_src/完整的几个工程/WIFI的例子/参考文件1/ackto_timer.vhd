
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: ackto_timer.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This timer issues a time-out signal if a packet is not received
--               within a certain time (in us) after a transmission end.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_timers/vhdl/rtl/ackto_timer.vhd,v  
--  Log: ackto_timer.vhd,v  
-- Revision 1.3  2005/04/19 07:25:08  Dr.A
-- #BugId:1181#
-- Ackto counter reset when ackto interrupt disabled.
--
-- Revision 1.2  2005/02/09 17:51:33  Dr.A
-- #BugId:1019#
-- Enable gate interrupt generation when ackto = 0.
--
-- Revision 1.1  2004/12/20 12:43:08  Dr.A
-- #BugId:702#
-- ACK time-out timer initial release.
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
entity ackto_timer is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n             : in  std_logic; -- Reset.
    clk                 : in  std_logic; -- Clock.
    enable_1mhz         : in  std_logic; -- Enable at 1 MHz.
    mode32k             : in  std_logic; -- High in low-power mode.

    --------------------------------------
    -- Controls
    --------------------------------------
    txstart_it          : in  std_logic; -- Start of transmission pulse
    txend_it            : in  std_logic; -- End of transmission pulse
    rxstart_it          : in  std_logic; -- Start of reception pulse
    -- Control fields from tx packet control structure:
    ackto_count         : in  std_logic_vector(8 downto 0); -- Time-out value
    -- Enable ACK time-out generation
    ackto_en            : in  std_logic; -- From TX control struture
    reg_ackto_en        : in  std_logic; -- From registers
    --
    ackto_it            : out std_logic; -- Time-out pulse
    ackto_timer_on      : out std_logic  -- High while timer is running.
    
  );

end ackto_timer;
