
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: long_sfd_comp.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Long SFD COMPARATOR
-- It signals the start of PLCP Header by setting long_packet_sync high when it
-- has detect the long SFD. The comparison is performed with the theorical
-- values of the long SFD after differential decoder.
-- no error is allowed in comparison.
-- It also search short sfd. This research is performed after descrambling (as
-- short_sfd_comp performs it before descrambling).
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/sfd_comp/vhdl/rtl/long_sfd_comp.vhd,v  
--  Log: long_sfd_comp.vhd,v  
-- Revision 1.5  2005/01/26 10:47:08  arisse
-- #BugId:983#
-- Removed 3rd state of state machine.
-- Removed state machine.
--
-- Revision 1.4  2004/12/06 08:56:57  arisse
-- #BugId:841#
-- Modified generation of outputs.
--
-- Revision 1.3  2002/09/17 07:18:25  Dr.B
-- descrambled short sfd detection added.
--
-- Revision 1.2  2002/07/08 13:02:58  Dr.B
-- added condition block_activated on output.
--
-- Revision 1.1  2002/07/03 11:48:16  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity long_sfd_comp is
  port (
     -- clock and reset
    clk                  : in std_logic;
    reset_n              : in std_logic;

    -- inputs
    lg_sfd_comp_activate : in std_logic;  -- activate the block   
    delta_phi0           : in std_logic;  -- bit 0 of PSK_demapping output data
    symbol_sync          : in std_logic;  -- chip synchronization

    -- output
    long_packet_sync     : out std_logic; -- indicate when detect of long SFD
    short_packet_sync    : out std_logic  -- indicate when detect of short SFD
 );

end long_sfd_comp;
