
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: radioctrl.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.29   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Radio controller
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/radioctrl/vhdl/rtl/radioctrl.vhd,v  
--  Log: radioctrl.vhd,v  
-- Revision 1.29  2006/02/27 15:08:10  Dr.J
-- #BugId:1509#
-- Removed the ECO for TSC and changed the agc_cca_hissbb in order to remove the bug 1509
--
-- Revision 1.28  2006/02/27 15:05:08  Dr.J
-- #BugId:1509#
-- ECO for TSC
--
-- Revision 1.27  2005/10/04 12:27:05  Dr.A
-- #BugId:1398#
-- Completed sensitivity list in registers and reqdata_handler.
-- Removed unused signals and rf_goto_sleep port
--
-- Revision 1.26  2005/03/10 08:45:59  sbizet
-- #BugId:907,948,946#
-- new diag ports
--
-- Revision 1.25  2005/01/06 17:07:08  sbizet
-- #BugId:907,948,946,643#
-- Added:
-- o software radio off request(sw_rfoff_req)
-- o Tx immediate stop feature(txv_immstop_i)
-- o radio off when MACADDR does not match(agc_rfoff)
-- o radar detection interrupt handling(rfint)
--
-- Revision 1.24  2004/12/14 16:31:15  sbizet
-- #BugId:713#
-- Updated port map for 1.2 functions
--
-- Revision 1.23  2004/11/03 10:00:08  sbizet
-- #BugId:804#
-- b_tx_data_val_tog resynchronized on bus_gclk
--
-- Revision 1.22  2004/07/16 07:41:43  Dr.B
-- add pabias info feature.
--
-- Revision 1.21  2004/06/04 13:51:37  Dr.C
-- Changed to only one port for Tx/Rx data.
--
-- Revision 1.20  2004/03/29 13:04:45  Dr.B
-- add clk44_possible_g generic.
--
-- Revision 1.19  2004/02/19 17:28:20  Dr.B
-- add hiss_reset_n + b_antsel.
--
-- Revision 1.18  2003/12/17 15:21:04  Dr.B
-- remove rf_rx when hiss only.
--
-- Revision 1.17  2003/12/03 17:32:58  Dr.B 
-- add diagport.
--
-- Revision 1.16  2003/11/27 12:20:21  Dr.B
-- add default value of rf_switch_ant when no hiss.
--
-- Revision 1.15  2003/11/20 16:26:41  Dr.B
-- add hiss_clk_n and rf_goto_sleep.
--
-- Revision 1.14  2003/11/20 13:06:29  Dr.B
-- remove rf_gotosleep port.
--
-- Revision 1.13  2003/11/20 11:35:15  Dr.B
-- readd hiss_clk_n temporarly for compatibilty with wildcore portmap.
--
-- Revision 1.12  2003/11/20 11:28:20  Dr.B
-- remove hiss_clk_n
--
-- Revision 1.11  2003/11/17 14:54:21  Dr.B
-- acc clk_switch_tog.
--
-- Revision 1.10  2003/11/05 09:19:42  Dr.B
-- add a_txbbonoff_req an agc_stream_enable.
--
-- Revision 1.9  2003/11/03 16:01:49  Dr.B
-- output pa_on.
--
-- Revision 1.8  2003/10/30 16:37:58  Dr.B
-- change txpwr size.
--
-- Revision 1.7  2003/10/30 14:42:02  Dr.B
-- update to spec 0.06.
--
-- Revision 1.6  2003/10/09 08:29:59  Dr.C
-- Updated hiss master port map
--
-- Revision 1.5  2003/09/25 12:46:26  Dr.C
-- Updated Hiss interface
--
-- Revision 1.4  2003/09/23 13:08:47  Dr.C
-- Updated to spec 0.05
--
-- Revision 1.3  2003/07/15 08:40:17  Dr.C
-- Updated to spec 0.04
--
-- Revision 1.2  2002/06/25 12:48:51  Dr.C
-- Modified rf_clk and data generation
--
-- Revision 1.1  2002/04/26 12:18:15  Dr.C
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

--library radioctrl_rtl;
library work;
--use radioctrl_rtl.radioctrl_pkg.all;
use work.radioctrl_pkg.all;

--library master_hiss_rtl;
library work;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity radioctrl is
  generic (
    ana_digital_g : integer := 2;  -- Selects between analog and HISS interface
                                    -- 0: reserved
                                    -- 1: analog interface
                                    -- 2: digital interface
                                    -- 3: both
    clk44_possible_g : integer := 0);  -- when 1 - the radioctrl can work with a
  -- 44 MHz clock instead of the normal 80 MHz.
    port (
    -------------------------------------------
    -- Clocks and reset                         
    -------------------------------------------
    reset_n      : in  std_logic;  -- general reset
    hiss_reset_n : in  std_logic;  -- reset for 240 MHz flip-flops
    sampling_clk : in  std_logic;
    hiss_clk     : in  std_logic; -- 240 MHz clock with mini clocktree
    rfh_fastclk  : in  std_logic; -- 240 MHz clock without clktree (directly from pad) 
    clk          : in  std_logic;       -- bus_clk
    clk_n        : in  std_logic;       -- bus_clk_n
   
    -------------------------------------------
    -- APB interface                           
    -------------------------------------------
    psel         : in  std_logic;
    penable      : in  std_logic;
    paddr        : in  std_logic_vector(5 downto 0);
    pwrite       : in  std_logic;
    pclk         : in  std_logic;
    pwdata       : in  std_logic_vector(31 downto 0);
    prdata       : out std_logic_vector(31 downto 0);

    -------------------------------------------
    -- AGC                       
    -------------------------------------------
    agc_ant_switch_tog : in  std_logic;  -- Ask of antenna switch when toggle
    agc_req            : in  std_logic;  -- Triggers an access to RF reg.
    agc_addr           : in  std_logic_vector(2 downto 0);  -- Register address
    agc_wrdata         : in  std_logic_vector(7 downto 0);  -- Write data for reg
    agc_wr             : in  std_logic;  -- Access type requested write = '1'
    agc_adc_enable     : in  std_logic;  -- Request ADC switch on
    agc_ab_mode        : in  std_logic;  -- Mode of received packet
    agc_busy           : in  std_logic;  -- Prevents software to access to RF
    agc_rxonoff_req    : in  std_logic;  -- Request switch to Rx mode
    agc_stream_enable  : in  std_logic;  -- Enable hiss 'pipe' on reception
    agc_rfint          : in  std_logic;  -- Interrupt from AGC RF decoded by AGC BB
    agc_rfoff          : in  std_logic;  -- AGC Request to stop the RF
    sw_rfoff_req       : out std_logic;  -- Pulse to request RF stop by software
    --
    agc_cs             : out std_logic_vector(1 downto 0);-- CS info for AGC/CCA
    agc_cs_valid       : out std_logic;  -- high when the CS is valid
    agc_conf           : out std_logic;  -- Acknowledge AGC access
    agc_rddata         : out std_logic_vector(7 downto 0);  -- AGC read data
    agc_ccamarker      : out std_logic; -- pulse when valid
    agc_ccaflags       : out std_logic_vector(5 downto 0);  -- CCA information   
    agc_cca_add_flags  : out std_logic_vector(15 downto 0);  -- CCA additional information   
    agc_rxonoff_conf   : out  std_logic;  -- Acknowledge switch to Rx mode
    
    -------------------------------------------
    -- Modem 802.11a                         
    -------------------------------------------
    a_txonoff_req   : in  std_logic;    -- Request switch to Tx mode
    a_txbbonoff_req : in  std_logic;  -- Same as previous but stop when no data in bb
    a_txdatavalid   : in  std_logic;
    --
    a_rxdatavalid   : out std_logic;
    a_txonoff_conf  : out std_logic;    -- Confirm switch to Tx mode
    
    -------------------------------------------
    -- Modem 802.11b                         
    -------------------------------------------
    b_txonoff_req   : in  std_logic;    -- Request switch to Tx mode
    b_txbbonoff_req : in  std_logic;    -- Same as previous but stop when no data in bb
    b_txdatavalid   : in  std_logic;    -- Indicates tx valid data
    --
    b_rxdatavalid   : out std_logic;    -- Indicates rx valid data
    b_txonoff_conf  : out std_logic;    -- Confirm switch to Tx mode

    -------------------------------------------
    -- Modem signals
    -------------------------------------------
    txi             : in  std_logic_vector(9 downto 0);   -- TX data
    txq             : in  std_logic_vector(9 downto 0);
    --
    rxi             : out std_logic_vector(10 downto 0);  -- RX data
    rxq             : out std_logic_vector(10 downto 0);

    -------------------------------------------
    -- BuP                 
    -------------------------------------------
    txv_immstop     : in  std_logic;                     -- Tx Immediate stop from BuP register
    txpwr_req       : in  std_logic;                     -- Request to program power level
    txpwr           : in  std_logic_vector(3 downto 0);  -- Tx power level
    txv_paindex     : in  std_logic_vector(4 downto 0);  -- index in the PA bias table -
                                                         -- valid with txpwr_req (paindex(0) = PAINDEXL)
    txv_txant       : in  std_logic;                     -- Antenna selected for transmission
    txv_txaddcntl   : in  std_logic_vector(1 downto 0);  -- Additionnal transmission control
    --
    txpwr_conf      : out std_logic;                     -- Confirm tx power level prog.
    -------------------------------------------
    -- Analog radio interface                        
    -------------------------------------------
    ana_rxi         : in  std_logic_vector(7 downto 0);  -- Rx data
    ana_rxq         : in  std_logic_vector(7 downto 0);
    ana_3wdatain    : in  std_logic;                     -- 3 wire data
    ana_3wenablein  : in  std_logic;                     -- 3 wire enable
    --
    ana_txi         : out std_logic_vector(7 downto 0);  -- Tx data
    ana_txq         : out std_logic_vector(7 downto 0);
    ana_3wclk       : out std_logic;    -- 3 wire interface clock
    ana_3wdataout   : out std_logic;    -- 3 wire data to write
    ana_3wdataen    : out std_logic;    -- Data enable
    ana_3wenableout : out std_logic;    -- 3 wire enable
    ana_3wenableen  : out std_logic;    -- enable enable signal
    ana_xoen        : out std_logic;    -- Enable crystal oscillator
    ana_rxen        : out std_logic;    -- Enable rx path
    ana_txen        : out std_logic;    -- Enable tx path
    ana_dacen       : out std_logic;    -- DAC enable
    ana_adcen       : out std_logic_vector(1 downto 0);
                                        -- ADC enable (1) paonbias (0) sleep

    -------------------------------------------
    -- Hiss radio interface                        
    -------------------------------------------
    rf_en_force  : in  std_logic;       -- Forces rf_en to '1'
    hiss_rxi     : in  std_logic;       -- Rx data
    hiss_rxq     : in  std_logic;
    --
    hiss_txi     : out std_logic;       -- Tx data
    hiss_txq     : out std_logic;
    hiss_txen    : out std_logic;       -- Enable Tx data outputs
    hiss_rxen    : out std_logic;       -- Enable Rx data inputs
    rf_en        : out std_logic;       -- Tx data
    hiss_biasen  : out std_logic;       -- enable HiSS drivers and receivers
    hiss_replien : out std_logic;       -- enable HiSS drivers and receivers
    hiss_clken   : out std_logic;       -- Enable HiSS clock receivers
    hiss_curr    : out std_logic;  -- Select high/low-current mode for HiSS drivers

    -------------------------------------------
    -- Radio control                       
    -------------------------------------------
    rf_sw         : out std_logic_vector(3 downto 0);  -- Radio switch
    pa_on         : out std_logic; -- high when PA is on

    -------------------------------------------
    -- Clock controller           
    -------------------------------------------
    clkdiv             : out std_logic_vector(2 downto 0);  -- Fast clock freq.
    clock_switched_tog : out std_logic;       -- Clock freq. switched
    
    -------------------------------------------
    -- Misc           
    -------------------------------------------
    rfmode         : in  std_logic;     -- 0 when hiss in enabled / 1 when ana
    sync_found     : in  std_logic;     -- Synchronization found active high
    tx_ab_mode     : in  std_logic;     -- TX a/b mode
    clk_2skip_tog  : out std_logic;     -- Clock skip of 2 per when toggle
    interrupt      : out std_logic;     -- Radio controller interrupt
    diag_port0     : out std_logic_vector(15 downto 0);  -- Diagnostic port 0
    diag_port1     : out std_logic_vector(15 downto 0)   -- Diagnostic port HiSS
    
    
  );

end radioctrl;
