
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem
--    ,' GoodLuck ,'      RCSfile: serializer.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.8   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Wild Modem Serializer  1 byte => 2 bits serialized
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/serializer/vhdl/rtl/serializer.vhd,v  
--  Log: serializer.vhd,v  
-- Revision 1.8  2005/01/12 14:40:35  arisse
-- #BugId:596#
-- Txv_immstop was not into the sensitivity list of
-- seria_next_state_p process.
--
-- Revision 1.7  2004/12/20 16:13:07  arisse
-- #BugId:596#
-- Integrated txv_immstop for BT Co-existence.
-- Removed last version correction which was wrong.
--
-- Revision 1.6  2004/12/14 16:48:29  arisse
-- #BugId:908#
-- When seria_cur_state = shift_op we were waitting for
-- (trans_count = 000 and shift_per_count = 0000
-- and shift_pulse = 1) to considere seria_activate signal. This is corrected.
--
-- Revision 1.5  2002/04/30 12:17:05  Dr.B
-- enable => activate. phy_data_req/conf => (switched signals).
--
-- Revision 1.4  2002/03/06 13:57:43  Dr.B
-- add constants.
--
-- Revision 1.3  2002/02/26 15:50:30  Dr.B
-- psk_mod bug corrected.
--
-- Revision 1.2  2002/01/29 16:19:40  Dr.B
-- state_machines + signals for other blocks added.
--
-- Revision 1.1  2001/12/20 09:29:57  Dr.B
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


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity serializer is
  port (
    -- clock and reset
    clk             : in  std_logic;                    
    resetn          : in  std_logic;                   
     
    -- inputs
    seria_in       : in  std_logic_vector ( 7 downto 0);
    --               byte from the buffer 
    phy_data_req   : in  std_logic;
    --               the BuP send a Tx octet to the Modem (on switched signal)
    psk_mode       : in  std_logic;
    --               BPSK = 0 - QPSK = 1
    seria_activate : in  std_logic;
    --               activate the seria. when disabled the serializer finishes
    --               its last byte.
    shift_period   : in  std_logic_vector (3 downto 0);
    --               nb of (per-1) between 2 shifts(if clk=11MHz,1MHz is 10)
    shift_pulse    : in  std_logic;
    --               reduce shift ferquency.
    txv_prtype     : in  std_logic; 
    --               def the type of preamble (short or long)
    txv_immstop    : in std_logic;
    --               for BT co-existence, stop tx immediately if high.

    -- outputs
    seria_out      : out std_logic_vector (1 downto 0); 
    --               2-bits outputs 
    phy_data_conf  : out std_logic;
    --               The modem ind. that the Tx path has read the new octet.
    --               A new one should be presented as soon as possible.
    scramb_reg     : out std_logic;
    --               Indicate to the scrambler that it can register the
    --               last data. (pulse)
    shift_mapping  : out std_logic;
    --               ask of performing a new mapping op. (every dibits sent)
    map_first_val  : out std_logic;
    --               indicate the the mapping that the first data arrives.
    fol_bl_activate: out std_logic;
    --               manage the acti. of the following blocks to finish byte.
    cck_disact     : out std_logic
    --               keep high during bytes transfer.
    --               when high, the cck block does not see phy_data_req     
  
  );

end serializer;
