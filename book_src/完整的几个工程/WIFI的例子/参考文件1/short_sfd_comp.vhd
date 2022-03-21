
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: short_sfd_comp.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Short SFD COMPARATOR.
-- It signals the start of PLCP Header by setting short_packet_sync high when it
-- has detect the short SFD. The comparison is performed with the theorical
-- values of 7 last preamble bits + the short SFD after PSK demapping and before
-- differential decoder. "sfderr" errors are allowed in comparison.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/sfd_comp/vhdl/rtl/short_sfd_comp.vhd,v  
--  Log: short_sfd_comp.vhd,v  
-- Revision 1.3  2002/07/31 07:45:41  Dr.B
-- added sfdlen.
--
-- Revision 1.2  2002/07/09 15:50:46  Dr.B
-- added condition of block activated on output.
--
-- Revision 1.1  2002/07/03 11:48:23  Dr.B
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
entity short_sfd_comp is
  port (
    -- clock and reset
    clk                  : in std_logic;
    reset_n              : in std_logic;

    -- inputs
    sh_sfd_comp_activate : in std_logic;  -- activate the block   
    demap_data0          : in std_logic;  -- bit 0 of PSK_demapping output data
    symbol_sync          : in std_logic;  -- chip synchronization
    sfderr               : in std_logic_vector (2 downto 0); -- allowed errs nb
    sfdlen               : in std_logic_vector (2 downto 0);

    -- output
    short_packet_sync    : out std_logic  -- indicate when detect of short SFD
    );

end short_sfd_comp;
