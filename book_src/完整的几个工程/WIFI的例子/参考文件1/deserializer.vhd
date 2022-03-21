
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: deserializer.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Deserializer Block . deserialize data from diff_decoder
--               and cck_demod acccording to the mode (DSSS 1/2 Mbs - 
--               CCK 5.5/11 Mbs) and send the phy_data_ind to the Bup.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/deserializer/vhdl/rtl/deserializer.vhd,v  
--  Log: deserializer.vhd,v  
-- Revision 1.2  2002/09/17 07:15:34  Dr.B
-- in 11 Mb/s, rec_mode checked directely.
--
-- Revision 1.1  2002/07/03 08:49:45  Dr.B
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
entity deserializer is
  port (
    -- clock and reset
    clk             : in  std_logic;                   
    reset_n         : in  std_logic;                  
     
    -- inputs
    d_from_diff_dec : in std_logic_vector (1 downto 0); 
    --               2-bits input from differential decoder (PSK)
    d_from_cck_dem  : in std_logic_vector (5 downto 0); 
    --               6-bits input from cck_demod (CCK)
    rec_mode        : in  std_logic_vector (1 downto 0);
    --               reception mode : BPSK QPSK CCK5.5 or CCK11
    symbol_sync     : in  std_logic;
    --               new chip available


    packet_sync    : in  std_logic;
    --               resynchronize (start a new byte)
    deseria_activate : in  std_logic;
    --               activate the deserializer. Beware to disable the deseria.
    --               when no transfer is performed to not get any 
    --               phy_data_ind pulse. 
    
    -- outputs
    deseria_out   : out std_logic_vector (7 downto 0);
    --              byte for the Bup
    byte_sync     : out std_logic;
    --              synchronisation for the descrambler (1 per bef phy_data_ind)
    --              as there should be glitches on transition of trans_count
    --              byte_sync must be used only to generate clocked signals !
    phy_data_ind  : out std_logic
    --              The modem indicates that a new byte is received.
  );

end deserializer;
