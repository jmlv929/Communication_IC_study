
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Stream_Processing
--    ,' GoodLuck ,'      RCSfile: key_mixing_sm.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : State machine for the TKIP key mixing block.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/tkip_key_mixing/vhdl/rtl/key_mixing_sm.vhd,v  
--  Log: key_mixing_sm.vhd,v  
-- Revision 1.2  2003/08/28 14:34:55  Dr.A
-- Added register for key_mix_done.
--
-- Revision 1.1  2003/07/16 13:24:38  Dr.A
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
entity key_mixing_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n        : in  std_logic;
    clk            : in  std_logic;

    --------------------------------------
    -- Controls
    --------------------------------------
    key1_key2n     : in  std_logic; -- High during phase 1, low during phase 2.
    start_keymix   : in  std_logic; -- Pulse to start the key mixing phase.
    --
    keymix1_done   : out std_logic; -- High when key mixing phase 1 is done.
    keymix2_done   : out std_logic; -- High when key mixing phase 2 is done.
    loop_cnt       : out std_logic_vector(2 downto 0); -- Loop counter.
    state_cnt      : out std_logic_vector(2 downto 0); -- State counter for P1.
    in_even_state  : out std_logic; -- Indicates the FSM is in even state.

    --------------------------------------
    -- S-Box interface
    --------------------------------------
    sbox_addr1     : in  std_logic_vector(15 downto 0); -- Sbox address for P1.
    sbox_addr2     : in  std_logic_vector(15 downto 0); -- Sbox address for P2.
    --
    sbox_data      : out std_logic_vector(15 downto 0);

    --------------------------------------
    -- Data
    --------------------------------------
    address2       : in  std_logic_vector(47 downto 0); -- A2 MAC header field.
    tsc            : in  std_logic_vector(47 downto 0); -- Sequence counter.
    -- Values to update internal registers.
    next_keymix1_reg_w  : in std_logic_vector(15 downto 0); -- from P1.
    next_keymix2_reg_w  : in std_logic_vector(15 downto 0); -- from P2.
    -- Registers out.
    keymix_reg_w5  : out std_logic_vector(15 downto 0);
    keymix_reg_w4  : out std_logic_vector(15 downto 0);
    keymix_reg_w3  : out std_logic_vector(15 downto 0);
    keymix_reg_w2  : out std_logic_vector(15 downto 0);
    keymix_reg_w1  : out std_logic_vector(15 downto 0);
    keymix_reg_w0  : out std_logic_vector(15 downto 0)
  );

end key_mixing_sm;
