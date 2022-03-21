
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 
--    ,' GoodLuck ,'      RCSfile: cck_form.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.7   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : CCK byte formation
--
-- In 5.5Mbit/s the raw data stream is split in 2 4-bit words completed by 
-- dummy bits.
-- In 11 Mbit/s the raw data stream is 8 bits.                  
--                  
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/cck_mod/vhdl/rtl/cck_form.vhd,v  
--  Log: cck_form.vhd,v  
-- Revision 1.7  2005/01/12 14:38:35  arisse
-- #BugId:596#
-- Txv_immstop was not included into the sensitivity list of cck_next_state_p process.
--
-- Revision 1.6  2004/12/20 16:20:38  arisse
-- #BugId:596#
-- Added txv_immstop for BT Co-existence.
--
-- Revision 1.5  2002/09/02 14:24:54  Dr.B
-- wait_pulse state added.
--
-- Revision 1.4  2002/06/19 09:54:13  Dr.B
-- sensitivity list updated.
--
-- Revision 1.3  2002/04/30 11:55:05  Dr.B
-- enable => activate.
--
-- Revision 1.2  2002/02/26 15:49:16  Dr.B
-- sensitivity list added.
--
-- Revision 1.1  2002/02/06 14:32:11  Dr.B
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
entity cck_form is
  port (
    -- clock and reset
    clk             : in  std_logic;                    
    resetn          : in  std_logic;                   
     
    -- inputs
    cck_form_in    : in  std_logic_vector ( 7 downto 0);
    --               byte from the buffer 
    phy_data_req   : in  std_logic; 
    --               BuP send a Tx octet to the Modem
    cck_speed      : in  std_logic; 
    --               5.5 Mbits/s = 0 - 11 Mbits/s = 1 
    cck_form_activate: in  std_logic; 
    --               activate the cck_form block.
    shift_pulse    : in  std_logic;
    --               reduce shift frequency.
    txv_immstop    : in std_logic;
    --               immediate stop from Bup for BT Co-existence.
    
    -- outputs
    cck_form_out   : out std_logic_vector (7 downto 0);
    --               byte output   
    phy_data_conf  : out std_logic;
    --               The modem indicates that the Tx path has read the new octet
    --               A new one should be presented as soon as possible.
    scramb_reg     : out std_logic;
    --               Indicate to the scrambler that it can register the
    --               last data. (pulse)
    shift_mapping  : out std_logic;
    --               shift mapping (save last_phi)
    first_data     : out std_logic;
    --               indicate that the first data is sent (even data)
    new_data       : out std_logic;
    --               indicate to cck_mod that a new data is valid.
    fol_bl_activate  : out std_logic
    --               manage the enable of the following blocks to finish byte.
  
  );

end cck_form;
