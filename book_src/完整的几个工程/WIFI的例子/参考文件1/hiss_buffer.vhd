
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem B.
--    ,' GoodLuck ,'      RCSfile: hiss_buffer.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.7   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Resynchronization buffer for data comming from Hiss controller.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/hiss_buffer/vhdl/rtl/hiss_buffer.vhd,v  
--  Log: hiss_buffer.vhd,v  
-- Revision 1.7  2005/03/11 08:56:03  arisse
-- #BugId:1129#
-- Reset output data between when hiss_buf_init = '1'.
--
-- Revision 1.6  2005/01/18 14:25:21  arisse
-- #BugId:814#
-- Back to version 1.2. The resynchronization is not possible
-- because we miss some samples and we repeat others.
--
-- Revision 1.5  2005/01/06 14:28:51  arisse
-- #BugId:944#
-- Resynchronized clk_2skip signal comming from radio controller.
--
-- Revision 1.4  2004/12/17 10:19:04  arisse
-- #BugId:911#
-- Modified toggle_i with toggle_ff2_resync when detecting a change in the input toggle.
--
-- Revision 1.3  2004/12/06 17:09:57  arisse
-- #BugId:814#
-- Added resynchronization of toggle input signal.
--
-- Revision 1.2  2003/12/09 11:03:40  Dr.B
-- add reset val of clk2skip_ff0.
--
-- Revision 1.1  2003/10/27 16:16:13  arisse
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
use ieee.std_logic_textio.all;
use ieee.STD_LOGIC_ARITH.all;
use std.textio.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity hiss_buffer is
  generic (
    buf_size_g  : integer := 4;
    rx_length_g : integer := 8);
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n       : in  std_logic;
    clk_44        : in  std_logic;      -- rx chain clock.
    clk_44g       : in  std_logic;      -- gated clock.
    --------------------------------------
    -- Controls
    --------------------------------------
    hiss_buf_init : in  std_logic;      -- init when pulse
    toggle_i      : in  std_logic;      -- toggle when new data.
    -- Input data.
    rx_i_i        : in  std_logic_vector(rx_length_g-1 downto 0);
    rx_q_i        : in  std_logic_vector(rx_length_g-1 downto 0);
    clk_2skip_i   : in  std_logic;      -- Toggle for clock skip : 2 periods.
    rx_i_o        : out std_logic_vector(rx_length_g-1 downto 0);
    rx_q_o        : out std_logic_vector(rx_length_g-1 downto 0);
    clkskip_o     : out std_logic
    );

end hiss_buffer;
