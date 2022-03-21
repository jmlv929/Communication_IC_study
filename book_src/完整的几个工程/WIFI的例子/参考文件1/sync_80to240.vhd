
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: sync_80to240.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.11   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Synchronization from 80 to 240 MHz
-- of control signals and data signals. 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/sync_80to240.vhd,v  
--  Log: sync_80to240.vhd,v  
-- Revision 1.11  2005/01/06 15:12:02  sbizet
-- #BugId:713#
-- txv_immstop signal resynchronization for master_hiss_sm
--
-- Revision 1.10  2004/03/04 13:17:07  Dr.B
-- save one period on buf_i sampling.
--
-- Revision 1.9  2003/12/01 09:59:06  Dr.B
-- change stop condition on read access.
--
-- Revision 1.8  2003/11/27 10:22:39  Dr.B
-- debug add / wrdata resync.
--
-- Revision 1.7  2003/11/26 14:00:56  Dr.B
-- clk_switch_req is removed.
--
-- Revision 1.6  2003/11/20 11:19:45  Dr.B
-- perform a real asynchronous resync.
--
-- Revision 1.5  2003/10/30 14:39:37  Dr.B
-- add buffer info.
--
-- Revision 1.4  2003/10/09 08:26:39  Dr.B
-- apb_access is memorized.
--
-- Revision 1.3  2003/09/25 12:31:44  Dr.B
-- rx_abmode, ant_selection ... added.
--
-- Revision 1.2  2003/09/22 09:35:04  Dr.B
-- rf_fast_clk -> hiss_clk.
--
-- Revision 1.1  2003/07/21 09:57:02  Dr.B
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
entity sync_80to240 is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    hiss_clk              : in  std_logic; -- 240 MHz clock
    reset_n               : in  std_logic; 
    --------------------------------------
    --  ***  Signals ****
    --------------------------------------
    -- Control Signals (240 MHz)
    rd_reg_pulse_on240_i        : in  std_logic;  -- used to reset apb_access_on240_o
    wr_reg_pulse_on240_i        : in  std_logic;  -- used to reset apb_access_on240_o
    -- 80 MHz signals Inputs (from Radio Controller)
    txv_immstop_i               : in  std_logic;  -- BuP asks for transmission immediate stop
    hiss_enable_n_on80_i        : in  std_logic;  -- enable block 
    force_hiss_pad_on80_i       : in  std_logic;  -- when high the receivers/drivers are always activated
    tx_abmode_on80_i            : in  std_logic;  --  tx mode A=0 - B=1
    rx_abmode_on80_i            : in  std_logic;  --  rx mode A=0 - B=1
    rd_time_out_on80_i          : in  std_logic;  -- time out : no reg val from RF
    clkswitch_time_out_on80_i   : in  std_logic;  -- time out : no clkswitch happens
    apb_access_on80_i           : in  std_logic;  -- ask of apb access (wr or rd)
    wr_nrd_on80_i               : in  std_logic;  -- wr_nrd = '1' => write access
    wrdata_on80_i               : in  std_logic_vector(15 downto 0);
    add_on80_i                  : in  std_logic_vector( 5 downto 0);
    preamble_detect_req_on80_i  : in  std_logic; 
    recep_enable_on80_i         : in  std_logic;  -- high = BB accepts incoming data (after CCA detect)
    trans_enable_on80_i         : in  std_logic;  -- high = there are data to transmit
    start_seria_on80_i          : in  std_logic;  -- high when trans is ready
    sync_found_on80_i           : in  std_logic;  -- sync A is found
    buf_tog_on80_i              : in  std_logic;
    bufi_on80_i                 : in  std_logic_vector(11 downto 0);
    bufq_on80_i                 : in  std_logic_vector(11 downto 0);
    -- 240 MHz Synchronized Outputs (to HiSS interface)
    txv_immstop_on240_o         : out std_logic;  -- BuP asks for transmission immediate stop
    hiss_enable_n_on240_o       : out std_logic;  -- enable block 
    force_hiss_pad_on240_o      : out std_logic;  -- when high the receivers/drivers are always activated
    tx_abmode_on240_o           : out std_logic;  -- tx mode A=0 - B=1
    rx_abmode_on240_o           : out std_logic;  -- rx mode A=0 - B=1
    rd_time_out_on240_o         : out std_logic;  -- timer out pulse
    clkswitch_time_out_on240_o  : out  std_logic;  -- time out : no clkswitch happens
    apb_access_on240_o          : out std_logic;  -- ask of apb access (wr or rd)
    wr_nrd_on240_o              : out std_logic;  -- wr_nrd = '1' => write access
    wrdata_on240_o              : out std_logic_vector(15 downto 0);
    add_on240_o                 : out std_logic_vector( 5 downto 0);
    preamble_detect_req_on240_o : out std_logic;  -- (from decode_add)
    recep_enable_on240_o        : out std_logic;  -- high = BB accepts incoming data (after CCA detect)
    trans_enable_on240_o        : out std_logic;  -- high = there are data to transmit
    start_seria_on240_o         : out std_logic;  -- serialization can start
    sync_found_on240_o          : out  std_logic;  -- sync A is found
    bufi_on240_o                : out std_logic_vector(11 downto 0);
    bufq_on240_o                : out std_logic_vector(11 downto 0)
    
  );

end sync_80to240;
