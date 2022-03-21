
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: keymix_phase1.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Phase 1 of the TKIP key mixing function.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/tkip_key_mixing/vhdl/rtl/keymix_phase1.vhd,v  
--  Log: keymix_phase1.vhd,v  
-- Revision 1.3  2003/09/01 13:09:41  Dr.A
-- Cleaned code.
--
-- Revision 1.2  2003/08/13 16:23:13  Dr.A
-- Removed unused ports.
--
-- Revision 1.1  2003/07/16 13:23:22  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
 
--library tkip_key_mixing_rtl;
library work;
--use tkip_key_mixing_rtl.tkip_key_mixing_pkg.all;
use work.tkip_key_mixing_pkg.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity keymix_phase1 is
  port (
    --------------------------------------
    -- Controls
    --------------------------------------
    loop_cnt      : in  std_logic_vector(2 downto 0); -- Loop counter.
    state_cnt     : in  std_logic_vector(2 downto 0); -- State counter.
    in_even_state : in  std_logic; -- High when the FSM is in even state.

    --------------------------------------
    -- S-Box interface
    --------------------------------------
    sbox_addr     : out std_logic_vector(15 downto 0); -- Address.
    --
    sbox_data     : in  std_logic_vector(15 downto 0); -- Data.

    --------------------------------------
    -- Data
    --------------------------------------
    -- Temporal key (128 bits)
    temp_key_w3   : in  std_logic_vector(31 downto 0);
    temp_key_w2   : in  std_logic_vector(31 downto 0);
    temp_key_w1   : in  std_logic_vector(31 downto 0);
    temp_key_w0   : in  std_logic_vector(31 downto 0);
    -- Internal registers, storing the TTAK during phase 1
    keymix_reg_w4 : in std_logic_vector(15 downto 0);
    keymix_reg_w3 : in std_logic_vector(15 downto 0);
    keymix_reg_w2 : in std_logic_vector(15 downto 0);
    keymix_reg_w1 : in std_logic_vector(15 downto 0);
    keymix_reg_w0 : in std_logic_vector(15 downto 0);
    -- Value to update the registers.
    next_keymix_reg_w  : out std_logic_vector(15 downto 0)
  );

end keymix_phase1;
