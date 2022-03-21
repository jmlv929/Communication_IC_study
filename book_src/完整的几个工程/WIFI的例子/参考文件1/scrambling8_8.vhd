
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem
--    ,' GoodLuck ,'      RCSfile: scrambling8_8.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Scrambler 8 bits - parallel (8 bits) 
--               Scrambler Polynomial: G(z) = Z^(-7) + Z^(-4) + 1
--    
--                          --> scr_out(t)
--                         |
--          scr_in(t) ---(+)-->[scr_out(t-4)]---[scr_out(t-7)] 
--                       /\          |             |
--                       |          \/            |
--                       ----------(+)<-----------
--
--  S(t) = scr_in(t) xor scr_out(t-4) xor scr_out(t-7)
-- 
--            
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/scrambling/vhdl/rtl/scrambling8_8.vhd,v  
--  Log: scrambling8_8.vhd,v  
-- Revision 1.5  2004/12/20 16:16:08  arisse
-- #BugId:596#
-- Added txv_immstop for BT Co-existence.
--
-- Revision 1.4  2002/04/30 11:57:08  Dr.B
-- phy_data_conf => scramb_reg as phy_data_conf is now a switch signal.
--
-- Revision 1.3  2002/01/29 15:57:59  Dr.B
-- fit with the other blocks.
--
-- Revision 1.2  2001/12/12 14:36:09  Dr.B
-- update control signals.
--
-- Revision 1.1  2001/12/11 15:29:16  Dr.B
-- Initial revision
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
entity scrambling8_8 is
  port (
    -- clock and reset
    clk       : in  std_logic;                    
    resetn    : in  std_logic;                   
     
    -- inputs
    scr_in          : in  std_logic_vector (7 downto 0);
    --                8-bits input
    scr_activate    : in  std_logic;
    --                start and scramble
    scramb_reg      : in std_logic;
    --                confirmation from modem of a new byte tranfer.
    txv_prtype      : in std_logic; 
    --                0 for short sync packets / 1 for long sync packets.
    scrambling_disb : in std_logic;
    --                disable the scrambler when high (for modem tests)
    txv_immstop     : in std_logic;
    --                immediate stop from Bup.
    
    -- outputs
    scr_out         : out std_logic_vector (7 downto 0) 
    --                scrambled data
    );
end scrambling8_8;
