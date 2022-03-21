
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: encoder.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block encodes the OFDM symbols SIGNAL and DATA fields
--               with a convolutional encoder of coding rate 1/2. Higher rates
--               for the DATA field (2/3 or 3/4) will be derived from it later
--               using puncturing.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/encoder/vhdl/rtl/encoder.vhd,v  
--  Log: encoder.vhd,v  
-- Revision 1.2  2004/12/14 10:42:30  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.1  2003/03/13 14:37:59  Dr.A
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
 
--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity encoder is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i     : in  std_logic;
    data_valid_i : in  std_logic;
    data_ready_i : in  std_logic;
    marker_i     : in  std_logic;
    --
    data_valid_o : out std_logic;
    data_ready_o : out std_logic;
    marker_o     : out std_logic;
    --------------------------------------
    -- Data
    --------------------------------------
    data_i       : in  std_logic; -- Data to encode.
    --
    x_o          : out std_logic; -- x encoded data at coding rate 1/2.
    y_o          : out std_logic  -- y encoded data at coding rate 1/2.
    
  );

end encoder;
