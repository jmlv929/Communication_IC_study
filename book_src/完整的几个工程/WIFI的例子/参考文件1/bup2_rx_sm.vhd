
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILDBuP2
--    ,' GoodLuck ,'      RCSfile: bup2_rx_sm.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.28  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : RX BuP2 state machine.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_sm/vhdl/rtl/bup2_rx_sm.vhd,v  
--  Log: bup2_rx_sm.vhd,v  
-- Revision 1.28  2005/04/19 07:45:00  Dr.A
-- #BugId:906#
-- Corrected buffer full detection when only 8 bytes left in buffer.
--
-- Revision 1.27  2005/03/29 14:06:30  Dr.A
-- #BugId:1162#
-- Control structure not written after FCS error
--
-- Revision 1.26  2005/02/18 16:12:18  Dr.A
-- #BugId:1064#
-- FCS error flag not set after A1 match abort
--
-- Revision 1.25  2005/02/11 13:55:14  Dr.A
-- #BugId:906#
-- access_cnt size reduced
--
-- Revision 1.24  2005/02/10 12:58:35  Dr.A
-- #BugId:906,974#
-- reset_bufempty removed (now coming from memory sequencer) (974)
-- Debugged last wrote access in case of buffer full (906)
--
-- Revision 1.23  2005/01/21 15:41:08  Dr.A
-- #BugId:974#
-- Bufempty flag reset on first memory write access.
--
-- Revision 1.22  2005/01/13 14:02:20  Dr.A
-- #BugId:903,956#
-- New diag ports (903)
-- Rewrote RX state machine for fake bytes and control structure memory accesses. 'rx' signal to the memory sequencer now comes from the RX state machine (956)
--
-- Revision 1.21  2004/12/23 10:19:26  Dr.A
-- #BugId:835#
-- rxrssi bit8 stuck to 1 in control structure
--
-- Revision 1.20  2004/12/22 17:09:12  Dr.A
-- #BugId:906#
-- Removed ring buffer mechanism and added new checks for end of buffer.
--
-- Revision 1.19  2004/12/17 12:54:46  Dr.A
-- #BugId:606#
-- RX end interrupt must be sent to the timers after end of Abort (CCA back to idle)
--
-- Revision 1.18  2004/12/10 10:36:32  Dr.A
-- #BugId:606#
-- Added RX abort after address 1 mismatch
--
-- Revision 1.17  2004/12/06 09:12:35  Dr.A
-- #BugId:836#
-- Address1 field now checked as soon as received, using mask from register.
--
-- Revision 1.16  2004/11/09 14:12:45  Dr.A
-- #BugId:835#
-- New ports for new fields in RX and TX control structures.
--
-- Revision 1.15  2004/04/14 16:10:19  Dr.A
-- Removed unused signal last_word_size.
-- Sampled rxe_errorstat in rx_errstat register at phy_rxstartend_ind falling edge, and reset rx_errstat at the beginning of a new reception.
-- Cleaned state machines (no more test on rxe_errorstat not registered).
--
-- Revision 1.14  2004/02/26 18:14:59  Dr.F
-- added reset of the write_data_sm.
--
-- Revision 1.13  2004/02/20 10:45:36  Dr.F
-- wait until phy_rxstartend_ind = 0 when there is a buffer collision.
--
-- Revision 1.12  2004/02/10 18:30:48  Dr.F
-- removed testmode.
--
-- Revision 1.11  2004/02/06 14:46:04  Dr.F
-- removed testdata_rec.
--
-- Revision 1.10  2004/01/29 17:54:06  Dr.F
-- fixed problem when there is a modem error.
--
-- Revision 1.9  2004/01/26 08:49:01  Dr.F
-- added ready_load.
--
-- Revision 1.8  2004/01/13 17:06:20  Dr.F
-- fixed rx_acc_type for the last RX control structure write access.
--
-- Revision 1.7  2004/01/06 10:50:35  Dr.F
-- changed condition to go in check_rx_state from idle_state.
--
-- Revision 1.6  2003/12/17 19:22:58  Dr.F
-- Fixed the fake bytes write.
--
-- Revision 1.5  2003/12/16 16:30:39  Dr.F
-- fixed end of rx.
--
-- Revision 1.4  2003/12/09 15:55:36  Dr.F
-- fixed load_ptr.
--
-- Revision 1.3  2003/11/25 08:47:35  Dr.F
-- access types in rx ctrl struct are now woed instead of half word.
--
-- Revision 1.2  2003/11/25 07:51:03  Dr.F
-- implemented modification for 2.0 revision.
--
-- Revision 1.1  2003/11/19 16:26:20  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Taken from revision 1.25 of bup_rx_sm.
--
-- Revision 1.25  2003/11/18 18:03:20  Dr.F
-- resynchronized phy_data_ind due to timing problems.
--
-- Revision 1.24  2003/11/14 10:02:14  Dr.F
-- fixed sensitivity list.
--
-- Revision 1.23  2003/11/13 18:33:00  Dr.F
-- added rx_packet_type for SIFS selection.
--------------------------------------------------------------------------------


library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;

--library bup2_sm_rtl;
library work;
--use bup2_sm_rtl.bup2_sm_pkg.all;      
use work.bup2_sm_pkg.all;      

--------------------------------------------
-- Entity
--------------------------------------------
entity bup2_rx_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn          : in  std_logic; -- AHB reset line.
    hclk             : in  std_logic; -- AHB clock line.
    --------------------------------------
    -- BuP Registers
    -------------------------------------- 
    buprxptr         : in  std_logic_vector(31 downto 0); -- rx buffer ptr
    buprxoff         : in  std_logic_vector(15 downto 0); -- start address of
                                                           -- next packet
    buprxsize        : in  std_logic_vector(15 downto 0); -- size of ring buf
    buprxunload      : in  std_logic_vector(15 downto 0); -- rx unload ptr

    reg_frmcntl      : out std_logic_vector(15 downto 0); -- Frame Control
    reg_durid        : out std_logic_vector(15 downto 0); -- Duration / Id
    reg_bupaddr1     : in  std_logic_vector(47 downto 0); -- Address1 field
    reg_addr1mskh    : in  std_logic_vector( 3 downto 0); -- Mask Address1(43:40)
    reg_addr1mskl    : in  std_logic_vector( 3 downto 0); -- Mask Address1(27:24)
    reg_enrxabort    : in  std_logic; -- Enable abort of RX packets
    -- Number of bytes to save after an RX abort.
    reg_rxabtcnt     : in  std_logic_vector( 5 downto 0);
    reg_rxlen        : out std_logic_vector(11 downto 0); -- rxlen
    reg_rxserv       : out std_logic_vector(15 downto 0); -- rxservice
    reg_rxrate       : out std_logic_vector( 3 downto 0); -- rxrate
    reg_rxrssi       : out std_logic_vector( 6 downto 0); -- rssi
    reg_rxccaaddinfo : out std_logic_vector( 7 downto 0); -- CCA additional information
    reg_rxant        : out std_logic; -- Antenna used for reception.
    reg_a1match      : out std_logic; -- high when received addr1 matches
 
    --------------------------------------
    -- Modem test mode
    -------------------------------------- 
    fcsdisb            : in  std_logic; -- disable FCS computation
    --------------------------------------
    -- Memory Sequencer
    -------------------------------------- 
    mem_seq_rx_mode    : out std_logic; -- Indicates a reception
    mem_seq_ind        : out std_logic; -- Indicates that new byte is ready
    data_to_mem_seq    : out std_logic_vector(7 downto 0); -- byte data 
                                                           --to Mem Seq
    last_word          : out std_logic; -- next bytes are part of last word
    mem_seq_rxptr      : out std_logic_vector(31 downto 0);-- rxptr for mem_seq
    load_rxptr         : out std_logic; -- pulse for mem seq to load rxptr
    ready_load         : in  std_logic;        -- ready 4 new load_ptr
    -- access type for endianness converter.
    rx_acc_type        : out std_logic_vector(1 downto 0); 
    --------------------------------------
    -- FCS generator
    -------------------------------------- 
    fcs_data_1st       : in  std_logic_vector(7 downto 0); -- First FCS data
    fcs_data_2nd       : in  std_logic_vector(7 downto 0); -- Second FCS data
    fcs_data_3rd       : in  std_logic_vector(7 downto 0); -- Third FCS data
    fcs_data_4th       : in  std_logic_vector(7 downto 0); -- Fourth FCS data
    --
    fcs_init           : out std_logic; -- init FCS computation
    fcs_data_valid     : out std_logic; -- compute FCS on mem seq data
    --------------------------------------
    -- Modem
    -------------------------------------- 
    phy_data_ind       : in  std_logic; -- received byte ready
    phy_rxstartend_ind : in  std_logic; -- end of received packet
    rxv_length         : in  std_logic_vector(11 downto 0);-- RX PSDU length
    bup_rxdata         : in  std_logic_vector( 7 downto 0);-- data from Modem
    rxe_errorstat      : in  std_logic_vector( 1 downto 0);-- packet reception 
                                                           -- status
    rxv_datarate       : in  std_logic_vector( 3 downto 0);-- RX PSDU rate
    rxv_service        : in  std_logic_vector(15 downto 0);-- RX SERVICE field
                                                           -- (802.11a only)
    -- RX SERVICE field available on rising edge
    rxv_service_ind    : in  std_logic;
    rxv_rssi           : in  std_logic_vector( 6 downto 0);-- preamble RSSI 
                                                           -- (802.11a only)
    rxv_ccaaddinfo     : in  std_logic_vector( 7 downto 0);
    rxv_rxant          : in  std_logic; -- Antenna used during reception.
    --------------------------------------
    -- BuP general state machine
    -------------------------------------- 
    rx_mode            : in  std_logic; -- Bup in reception mode
    --
    rx_end             : out std_logic; -- end of received packet
    rx_fullbuf         : out std_logic; -- rx buffer full detected when high
    bufempty           : in  std_logic; -- 1 when RX buffer emptied.
    rx_errstat         : out std_logic_vector(1 downto 0); -- error from modem
    rxend_stat         : out std_logic_vector(1 downto 0); -- RX status
    rx_fcs_err         : out std_logic; -- end of packet and FCS error detected
    rx_err             : out std_logic; -- unexpected end of packet 
    rx_packet_type     : out std_logic; -- 0 : modem b packet; 1 modem a packet
    -- diag
    rx_sm_diag         : out std_logic_vector(7 downto 0)
  );
end bup2_rx_sm;
