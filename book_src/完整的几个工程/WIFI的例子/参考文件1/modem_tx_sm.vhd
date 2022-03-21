
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: modem_tx_sm.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.19   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Modem 802.11b transmission state machine.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/modem_sm_b/vhdl/rtl/modem_tx_sm.vhd,v  
--  Log: modem_tx_sm.vhd,v  
-- Revision 1.19  2005/02/02 14:51:45  arisse
-- #BugId:983#
-- Removed txv_datarate_resync and txv_length_resync because they are busses.
--
-- Revision 1.18  2004/12/23 14:29:21  arisse
-- #BugId:596#
-- Teated txv_immstop in idle_state after setting other data. Revision 1.17 has a wrong log file.
--
-- Revision 1.17  2004/12/23 08:44:30  arisse
-- #BugId:854#
-- Added check on 13th MSB of the length to verify that it's not bigger than 4095.
--
-- Revision 1.16  2004/12/14 16:50:42  arisse
-- #BugId:596#
-- Added BT co-existence feature.
--
-- Revision 1.15  2003/11/18 17:57:02  Dr.F
-- resynchronized txv_datarate and txv_length due to timing problems.
--
-- Revision 1.14  2003/09/01 15:05:42  Dr.F
-- debugged falling edge of txonoff_req.
--
-- Revision 1.13  2003/01/30 08:33:22  Dr.F
-- debugged activate_seria : it was not activated when reg_prepre=0.
--
-- Revision 1.12  2003/01/28 17:34:30  Dr.F
-- activate_seria set at end of prepre state.
--
-- Revision 1.11  2002/12/13 18:18:33  Dr.F
-- reset state machines when phy_txstartend_req = 0.
--
-- Revision 1.10  2002/11/07 16:23:51  Dr.F
-- added rf control ports.
--
-- Revision 1.9  2002/11/05 10:06:11  Dr.F
-- removed txv_modulation.
--
-- Revision 1.8  2002/10/21 13:57:03  Dr.F
-- added reg_prepre and txv_service.
--
-- Revision 1.7  2002/07/11 13:18:35  Dr.F
-- debugged plcp_data at start of preamble.
--
-- Revision 1.6  2002/06/14 16:37:15  Dr.F
-- reduced txv_length size.
--
-- Revision 1.5  2002/04/30 12:25:37  Dr.B
-- phy_data_req/conf are switched signals.
--
-- Revision 1.4  2002/02/28 15:48:38  omilou
-- added statement in others case to avoid latch at synthesis
--
-- Revision 1.3  2002/02/26 12:11:34  omilou
-- psk_mode and speed are set one cycle later.
-- cahnged the length calculation, using a division by 11
--
-- Revision 1.2  2002/01/29 16:07:22  omilou
-- adapted to spec 0.06
--
-- Revision 1.1  2002/01/17 10:16:27  omilou
-- Initial revision
--
--
--
--
--------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 


entity modem_tx_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn             : in  std_logic; -- AHB reset line.
    hclk                : in  std_logic; -- AHB clock line.
    --------------------------------------
    -- TX path block
    -------------------------------------- 
    seria_data_conf     : in  std_logic; -- Serializer is ready for new data
    tx_activated        : in  std_logic; -- the tx_path is transmitting when high
    -- 
    scr_data_in         : out std_logic_vector(7 downto 0); -- data sent to scrambler
    sm_data_req         : out std_logic; -- State machines data request
    psk_mode            : out std_logic; -- 0 = BPSK; 1 = QPSK
    activate_seria      : out std_logic; -- activate Serializer
    shift_period        : out std_logic_vector(3 downto 0); -- Serializer speed
    activate_cck        : out std_logic; -- activate CCK modulator
    cck_speed           : out std_logic; -- CCK speed (0 = 5.5 Mbit/s; 1 = 11 Mbit/s)
    preamble_type       : out std_logic; -- preamble type (0 = short; 1 = long)
    --------------------------------------------
    -- Registers
    --------------------------------------------
    reg_prepre          : in  std_logic_vector(5 downto 0); -- pre-preamble count.

    --------------------------------------
    -- CRC
    -------------------------------------- 
    crc_data_1st        : in  std_logic_vector(7 downto 0); -- CRC data
    crc_data_2nd        : in  std_logic_vector(7 downto 0); -- CRC data
    --
    crc_init            : out std_logic; -- init CRC computation
    crc_data_valid      : out std_logic; -- compute CRC on packet header
    data_to_crc         : out std_logic_vector(7 downto 0); -- byte data to CRC
    --------------------------------------------
    -- Radio controller interface
    --------------------------------------------
    rf_txonoff_req      : out std_logic;  -- tx on off request
    rf_txonoff_conf     : in  std_logic;  -- tx on off confirmation
    rf_rxonoff_req      : out std_logic;  -- rx on off request
    rf_rxonoff_conf     : in  std_logic;  -- rx on off confirmation
    --------------------------------------
    -- BuP
    -------------------------------------- 
    phy_txstartend_req  : in  std_logic; -- request to start a packet transmission
                                         -- or request for end of transmission
    txv_service         : in  std_logic_vector(7 downto 0); -- service field
    phy_data_req        : in  std_logic; -- request from BuP to send a byte
    txv_datarate        : in  std_logic_vector( 3 downto 0); -- PSDU transmission rate
    txv_length          : in  std_logic_vector(11 downto 0); -- packet length in bytes
    bup_txdata          : in  std_logic_vector( 7 downto 0); -- data from BuP
    txv_immstop         : in std_logic;  -- request from Bup to stop tx.
    --
    phy_txstartend_conf : out std_logic -- transmission started, ready for data
                                        -- or transmission ended
    );
end modem_tx_sm;
