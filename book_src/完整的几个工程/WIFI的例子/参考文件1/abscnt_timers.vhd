
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_MII
--    ,' GoodLuck ,'      RCSfile: abscnt_timers.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Set of absolute count timers generating an interrupt when they
--               reach the BuP timer value.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_timers/vhdl/rtl/abscnt_timers.vhd,v  
--  Log: abscnt_timers.vhd,v  
-- Revision 1.1  2005/10/21 13:26:32  Dr.A
-- #BugId:1246#
-- Added absolute count timers
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
entity abscnt_timers is
  generic (
    num_abstimer_g : integer := 16
  );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n               : in std_logic;
    clk                   : in std_logic;

    --------------------------------------
    -- Controls
    --------------------------------------
    mode32k               : in std_logic;
    bup_timer             : in  std_logic_vector(25 downto 0);

    --------------------------------------
    -- Timers time tags
    --------------------------------------
    abstime0              : in  std_logic_vector(25 downto 0);
    abstime1              : in  std_logic_vector(25 downto 0);
    abstime2              : in  std_logic_vector(25 downto 0);
    abstime3              : in  std_logic_vector(25 downto 0);
    abstime4              : in  std_logic_vector(25 downto 0);
    abstime5              : in  std_logic_vector(25 downto 0);
    abstime6              : in  std_logic_vector(25 downto 0);
    abstime7              : in  std_logic_vector(25 downto 0);
    abstime8              : in  std_logic_vector(25 downto 0);
    abstime9              : in  std_logic_vector(25 downto 0);
    abstime10             : in  std_logic_vector(25 downto 0);
    abstime11             : in  std_logic_vector(25 downto 0);
    abstime12             : in  std_logic_vector(25 downto 0);
    abstime13             : in  std_logic_vector(25 downto 0);
    abstime14             : in  std_logic_vector(25 downto 0);
    abstime15             : in  std_logic_vector(25 downto 0);
    --------------------------------------
    -- Timers interrupts
    --------------------------------------
    abscount_it           : out std_logic_vector(num_abstimer_g-1 downto 0)    
  );

end abscnt_timers;
