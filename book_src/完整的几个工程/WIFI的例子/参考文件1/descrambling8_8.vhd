
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: descrambling8_8.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description :Descrambler 8 bits - parallel (8 bits) and serial 
--              Descrambler Polynomial: G(z) = Z^(-7) + Z^(-4) + 1
--                         
--          dscr_in(t) ---(+)-->[dscr_in(t-4)]----[dscr_in(t-7)] 
--                        |          |             |
--                        |          \/            |
--                        ----------(+)<-----------
--                        | 
--                        --> dscr_out(t)
--
--  dscr_out(t) = dscr_in(t) xor dscr_in(t-4) xor dscr_in(t-7)
-- 
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/scrambling/vhdl/rtl/descrambling8_8.vhd,v  
--  Log: descrambling8_8.vhd,v  
-- Revision 1.5  2002/09/26 13:08:34  Dr.B
-- reinit regs before each new decode action.
--
-- Revision 1.4  2002/07/03 11:36:11  Dr.B
-- fit with decode path - serial mode added.
--
-- Revision 1.3  2002/01/29 15:58:46  Dr.B
-- registers updated with phy_data_ind.
--
-- Revision 1.2  2001/12/12 14:35:45  Dr.B
-- update control signals.
--
-- Revision 1.1  2001/12/11 15:29:20  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity descrambling8_8 is
  port (
    -- clock and reset
    clk     : in std_logic;
    reset_n : in std_logic;

    dscr_activate   : in std_logic;     -- activate the block
    scrambling_disb : in std_logic;     -- disable the descr.when high 
    dscr_mode       : in std_logic;     -- 0 : serial - 1 : parallel

    -- Signals for serial descrambling
    bit_fr_diff_dec : in  std_logic;    -- bit from differential decoder
    symbol_sync     : in  std_logic;    -- chip synchronisation
    --
    dscr_bit_out    : out std_logic;

    -- Signals for parallel descrambling   
    byte_fr_des : in  std_logic_vector (7 downto 0);  -- byte from deseria.
    byte_sync   : in  std_logic;                      --  sync from deseria
    --
    data_to_bup : out std_logic_vector (7 downto 0)

    );

end descrambling8_8;
