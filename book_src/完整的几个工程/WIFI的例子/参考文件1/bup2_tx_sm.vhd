
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILDBuP2
--    ,' GoodLuck ,'      RCSfile: bup2_tx_sm.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.17  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Transmission BuP2 state machine.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_sm/vhdl/rtl/bup2_tx_sm.vhd,v  
--  Log: bup2_tx_sm.vhd,v  
-- Revision 1.17  2005/03/17 16:34:11  Dr.A
-- #BugId:1087#
-- Rewrote control structure read state because it was not working with the bus granted to the BuP by default.
--
-- Revision 1.16  2005/03/16 14:54:00  Dr.A
-- #BugId:1087#
-- Added state to change PSDUs
--
-- Revision 1.15  2005/03/01 10:04:48  Dr.A
-- #BugId:1087#
-- New state machine for memory sequencer control.
--
-- Revision 1.14  2005/01/21 15:42:06  Dr.A
-- #BugId:822,978#
-- TX immediate stop debug. Added output to timers.
--
-- Revision 1.13  2005/01/10 12:50:44  Dr.A
-- #BugId:912#
-- Removed enable_bup
--
-- Revision 1.12  2004/12/20 13:02:24  Dr.A
-- #BugId:822#
-- Connected txend status line
--
-- Revision 1.11  2004/12/10 10:35:25  Dr.A
-- #BugId:702#
-- Read ack time-out fields from TX control structure
--
-- Revision 1.10  2004/12/02 10:28:48  Dr.A
-- #BugId:822#
-- Added tx abort controlled by tx immediate stop register
--
-- Revision 1.9  2004/11/09 14:12:51  Dr.A
-- #BugId:835#
-- New ports for new fields in RX and TX control structures.
--
-- Revision 1.8  2004/04/14 08:29:03  Dr.A
-- Syntax error corrected.
--
-- Revision 1.7  2004/04/09 12:11:06  Dr.A
-- Removed redundant signal byte_tx_done, use phy_data_conf_pulse instead.
--
-- Revision 1.6  2004/02/10 18:32:08  Dr.F
-- begugged when FCS is disabled.
--
-- Revision 1.5  2004/01/13 17:05:43  Dr.F
-- fixed acc_type for control structure access.
--
-- Revision 1.4  2003/12/17 13:19:06  Dr.F
-- fixed guard_time_expired flag.
--
-- Revision 1.3  2003/12/09 15:56:40  Dr.F
-- resynchronized some signals due to timing problems.
--
-- Revision 1.2  2003/11/25 07:51:30  Dr.F
-- implemented modification according to 2.0 revision.
--
-- Revision 1.1  2003/11/19 16:26:24  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Taken from revision 1.24 of bup_tx_sm.
--
-- Revision 1.24  2003/11/18 18:04:06  Dr.F
-- delayed txrate_read_done due to timing problems.
--
-- Revision 1.23  2003/11/15 14:37:19  Dr.F
-- txpwr_level size changed.
--
-- Revision 1.22  2003/11/13 18:35:05  Dr.F
-- added tx_packet_type for SIFS selection.
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
entity bup2_tx_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn             : in  std_logic; -- AHB reset line.
    hclk                : in  std_logic; -- AHB clock line.
    --------------------------------------
    -- BuP Registers
    -------------------------------------- 
    tximmstop           : in  std_logic; -- Stop TX when high.
    enable_1mhz         : in  std_logic; -- Enable at 1 MHz.
    buptxptr            : in  std_logic_vector(31 downto 0); -- tx buffer ptr
    iacptr              : in  std_logic_vector(31 downto 0); -- IAC ctrl struct ptr

    txend_stat          : out std_logic_vector(1 downto 0); -- TX status.
    -- queue that generated the it :
    --          1000 : IAC
    --          1001 : Beacon
    --   0000 - 0111 : ACP[0-7]
    queue_it_num        : in  std_logic_vector(3 downto 0);
    sampled_queue_it_num: out std_logic_vector(3 downto 0);

    --------------------------------------
    -- Modem test mode
    -------------------------------------- 
    testenable          : in  std_logic; -- enable BuP test mode
    bup_testmode        : in  std_logic_vector(1 downto 0); -- selects the type of test
    datatype            : in  std_logic_vector(1 downto 0); -- selects the data pattern
    fcsdisb             : in  std_logic; -- disable FCS computation
    testdata            : in  std_logic_vector(31 downto 0); -- data test pattern
    --------------------------------------
    -- Memory Sequencer
    -------------------------------------- 
    mem_seq_ready       : in  std_logic; -- memory sequencer is ready (data valid)
    mem_seq_data        : in  std_logic_vector(7 downto 0); -- mem seq data
    --
    mem_seq_req         : out std_logic; -- request to mem seq for new byte
    mem_seq_txptr       : out std_logic_vector(31 downto 0);-- txptr for mem_seq
    last_word           : out std_logic; -- last word to be read when high
    load_txptr          : out std_logic; -- pulse for mem seq to load txptr
    -- access type for endianness converter.
    tx_acc_type         : out std_logic_vector(1 downto 0); 
    --------------------------------------
    -- FCS generator
    -------------------------------------- 
    fcs_data_1st        : in  std_logic_vector(7 downto 0); -- First FCS data
    fcs_data_2nd        : in  std_logic_vector(7 downto 0); -- Second FCS data
    fcs_data_3rd        : in  std_logic_vector(7 downto 0); -- Third FCS data
    fcs_data_4th        : in  std_logic_vector(7 downto 0); -- Fourth FCS data
    --
    fcs_init            : out std_logic; -- init FCS computation
    fcs_data_valid      : out std_logic; -- compute FCS on mem seq data
    --------------------------------------
    -- Modem
    -------------------------------------- 
    phy_data_conf       : in  std_logic; -- last byte was read, ready for new one
    phy_txstartend_conf : in  std_logic; -- transmission started, ready for data
                                         -- or transmission ended
    --
    phy_data_req        : out std_logic; -- request to send a byte
    phy_txstartend_req  : out std_logic; -- request to start a packet transmission
                                         -- or request for end of transmission
    bup_txdata          : out std_logic_vector( 7 downto 0);-- data to Modem
    txv_datarate        : out std_logic_vector( 3 downto 0);-- TX PSDU rate
    txv_length          : out std_logic_vector(11 downto 0);-- TX packet size
    txpwr_level         : out std_logic_vector( 3 downto 0);-- TX power level
    txv_service         : out std_logic_vector(15 downto 0);-- value of TX SERVICE
                                                            -- field (802.11a only)
    -- Additional transmission control
    txv_txaddcntl       : out std_logic_vector( 1 downto 0);
    -- Index into the PABIAS table to select the PA bias programming
    txv_paindex         : out std_logic_vector( 4 downto 0);
    txv_txant           : out std_logic; -- Antenna to be used for transmission
    tximmstop_sm        : out std_logic; -- Immediate stop from the state machines
    ackto               : out std_logic_vector(8 downto 0); -- Time-out for ACK transmission
    ackto_en            : out std_logic; -- Enable ACK time-out generation
    --------------------------------------
    -- BuP general state machine
    -------------------------------------- 
    tx_mode             : in  std_logic; -- Bup in transmit mode
    --
    tx_start_it         : out std_logic; -- start of transmit packet
    tx_end_it           : out std_logic; -- end of transmit packet
    tx_packet_type      : out std_logic; -- 0 : modem b packet; 1 modem a packet
    --------------------------------------------
    -- Diag
    --------------------------------------------
    tx_sm_diag          : out std_logic_vector(2 downto 0);
    tx_read_sm_diag     : out std_logic_vector(1 downto 0)
    
  );
end bup2_tx_sm;
