
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: modem_rx_sm.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.33   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Modem 802.11b state machines for reception.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/modem_sm_b/vhdl/rtl/modem_rx_sm.vhd,v  
--  Log: modem_rx_sm.vhd,v  
-- Revision 1.33  2005/03/29 09:37:17  arisse
-- #BugId:983#
-- Removed carrier lost information : not used at all.
--
-- Revision 1.32  2005/03/22 14:05:20  arisse
-- #BugId:854#
-- Check of length only if we had not rate error before.
--
-- Revision 1.31  2005/03/09 16:59:59  arisse
-- #BugId:854#
-- Checked rate error only if there is no CRC error.
--
-- Revision 1.30  2005/03/01 16:10:07  arisse
-- #BugId:854#
-- Changed rate error generation (bit 3 of service field and ERP-DSSS-OFDM packet).
--
-- Revision 1.29  2005/02/16 09:25:00  arisse
-- #BugId:1057#
-- Looked at rising edge of byte_ind because otherwise, high during two clock cycles if in the same time of a clock skip.
--
-- Revision 1.28  2005/02/02 14:49:40  arisse
-- #BugId:955#
-- Added phy_txstartend_req input in case of a IAC.
--
-- Revision 1.27  2005/01/11 10:20:42  arisse
-- #BugId:854#
-- Romved possiblity of error_rate, added format_error for wrong length (too small or too big).
--
-- Revision 1.26  2004/12/23 14:30:40  arisse
-- #BugId:854#
-- Added check on 13th MSB of the rxv_length to verify that it's not bigger than 4095.
--
-- Revision 1.25  2004/12/22 14:30:10  arisse
-- #BugId:854#
-- Added rxlenchken and rxmaxlength.
-- Modified delay on rx_psk_mode with a counter instead of registers.
--
-- Revision 1.24  2004/08/06 12:12:56  arisse
-- Reset rx_psk_mode_o_ff0...39 to 0 between two packets.
--
-- Revision 1.23  2004/06/28 08:38:43  sbizet
-- Added cca_busy=0 condition in psdu_state to end reception
--
-- Revision 1.22  2004/06/14 14:02:01  arisse
-- Added delay on rx_psk_mode.
--
-- Revision 1.21  2003/11/03 16:03:13  arisse
-- Modified diag ports.
--
-- Revision 1.20  2003/10/16 14:13:37  arisse
-- Added diag ports.
--
-- Revision 1.19  2003/09/22 16:13:25  arisse
-- Removed rx_psk_mode2 signal wich was not used any more.
--
-- Revision 1.18  2003/08/06 13:38:08  Dr.C
-- debugged falling edge detection of tx_activated.
--
-- Revision 1.17  2003/07/29 15:20:14  Dr.F
-- debugged listen_start generation.
--
-- Revision 1.16  2003/07/29 07:47:37  Dr.F
-- debugged listen_start_o.
--
-- Revision 1.15  2003/07/29 07:38:50  Dr.F
-- wait for cca_busy to be 0 at end of rx.
--
-- Revision 1.14  2003/07/25 05:40:28  Dr.F
-- added listen_start_o.
--
-- Revision 1.13  2003/06/27 15:44:45  Dr.F
-- phy_data_ind is now created as a transitional signal instead of a pulse.
--
-- Revision 1.12  2002/12/03 13:24:24  Dr.F
-- increased psdu_duration size.
--
-- Revision 1.11  2002/11/26 08:13:31  Dr.F
-- added plcp_error.
-- generate a pulse on phy_rxstartend_ind on rate and format error.
--
-- Revision 1.10  2002/11/05 10:05:32  Dr.F
-- removed rxv_modulation and cck_enable.
--
-- Revision 1.9  2002/10/21 13:56:42  Dr.F
-- added rxv_service.
--
-- Revision 1.8  2002/09/12 14:21:54  Dr.F
-- removed test on cca_busy when in psdu state.
--
-- Revision 1.7  2002/09/09 14:22:14  Dr.F
-- removed one_us_it and added rx_plcp_state.
--
-- Revision 1.6  2002/08/08 16:52:07  Dr.F
-- removed agc_setting_end.
--
-- Revision 1.5  2002/07/31 08:24:09  Dr.F
-- rx_path interface changed.
-- removed rx_ctrl instanciation because now it is an external sub-block.
--
-- Revision 1.4  2002/07/11 13:15:09  Dr.F
-- added rx_patrh control signals.
--
-- Revision 1.3  2002/07/03 16:21:48  Dr.F
-- added some ports to control rx_path.
--
-- Revision 1.2  2002/06/19 10:10:11  Dr.A
-- Added parenthesis on rx_length_times11 computation.
--
-- Revision 1.1  2002/06/14 16:37:44  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use IEEE.STD_LOGIC_arith.ALL; 

--library modem_sm_b_rtl;
library work;
--use modem_sm_b_rtl.modem_sm_b_pkg.all;      
use work.modem_sm_b_pkg.all;      

entity modem_rx_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn             : in  std_logic; -- AHB reset line.
    hclk                : in  std_logic; -- AHB clock line.
    --------------------------------------
    -- RX path block
    -------------------------------------- 
    cca_busy            : in  std_logic; -- CCA busy
    preamble_type       : in  std_logic; -- 1: long preamble ; 0: short preamble
    sfd_found           : in  std_logic; -- pulse when SFD is detected
    byte_ind            : in  std_logic; -- byte indication  
    tx_activated        : in  std_logic; -- the tx_path is transmitting    
    rx_data             : in  std_logic_vector(7 downto 0); -- received descrambled data
    --
    decode_path_activate: out std_logic; -- decode path activate
    diff_decod_first_val: out std_logic; -- pulse on first byte to decode
    rec_mode            : out std_logic_vector(1 downto 0); -- BPSK, QPSK, CCK5.5, CCK 11
    mod_type            : out std_logic; -- 0 : DSSS ; 1 : CCK
    rx_psk_mode         : out std_logic; -- 0 = BPSK; 1 = QPSK
    cck_rate            : out std_logic; -- CCK rate (0 = 5.5 Mb/s; 1 = 11 Mb/s)
    rx_idle_state       : out std_logic; -- high when sm is idle
    rx_plcp_state       : out std_logic; -- high when sm is in plcp state
    --------------------------------------------
    -- CCA
    --------------------------------------------
    psdu_duration       : out std_logic_vector(15 downto 0); --length in us
    correct_header      : out std_logic; -- high when header is correct.
    plcp_error          : out std_logic; -- high when plcp error occures
    listen_start_o      : out std_logic; -- high when start to listen
    --------------------------------------
    -- CRC
    -------------------------------------- 
    crc_data_1st        : in  std_logic_vector(7 downto 0); -- CRC data
    crc_data_2nd        : in  std_logic_vector(7 downto 0); -- CRC data
    --
    crc_init            : out std_logic; -- init CRC computation
    crc_data_valid      : out std_logic; -- compute CRC on packet header
    data_to_crc         : out std_logic_vector(7 downto 0); -- byte data to CRC
    --------------------------------------
    -- BuP
    -------------------------------------- 
    phy_txstartend_req  : in  std_logic; -- request to start a packet transmission
                                         -- or request for end of transmission
    phy_cca_ind         : out  std_logic; -- indication of a carrier
    phy_rxstartend_ind  : out  std_logic; -- indication of a recieved PSDU
    rxv_service         : out  std_logic_vector(7 downto 0); -- service field
    phy_data_ind        : out  std_logic; -- indication of a recieved byte
    rxv_datarate        : out  std_logic_vector( 3 downto 0); -- PSDU RX rate
    rxv_length          : out  std_logic_vector(11 downto 0); -- packet length in bytes
    rxe_errorstat       : out  std_logic_vector(1 downto 0); -- error
    bup_rxdata          : out  std_logic_vector( 7 downto 0);  -- data to BuP
    --------------------------------------
    -- Registers
    --------------------------------------
    rxlenchken          : in  std_logic; -- select ckeck on rx data lenght.
    rxmaxlength         : in  std_logic_vector(11 downto 0); -- Max accepted received length.
    --------------------------------------
    -- Diag
    --------------------------------------
    rx_state_diag       : out std_logic_vector(2 downto 0)  -- Diag port
    );
end modem_rx_sm;
