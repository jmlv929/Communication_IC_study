
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: reqdata_handler.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.40   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Request and data handler:
--               * Manage access priority to the radio interface controller
--               * Process data sent or received
--               * Controls RF switches and enable
-- 
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/radioctrl/vhdl/rtl/reqdata_handler.vhd,v  
--  Log: reqdata_handler.vhd,v  
-- Revision 1.40  2005/10/04 12:27:18  Dr.A
-- #BugId:1398#
-- Completed sensitivity list in registers and reqdata_handler.
-- Removed unused signals and rf_goto_sleep port
--
-- Revision 1.39  2005/03/10 08:47:03  sbizet
-- #BugId:907,948,946#
-- new diag ports
--
-- Revision 1.38  2005/03/02 12:59:33  sbizet
-- #BugId:907#
-- Signal wait_end_tx not generated in Tx
--
-- Revision 1.37  2005/02/11 14:47:56  sbizet
-- #BugId:953#
-- Renamed resync FF
--
-- Revision 1.36  2005/01/21 08:31:36  sbizet
-- #BugId:953,713,948,907#
-- o Added wait end of Rx software rf off
-- o Write access possible in Rx
-- o AGC RF reseted when a Rx is stopped to
-- insure several Rx can be performed
-- o b_txbbonoff_req resynchronized -> 0.18 um issue
--
-- Revision 1.35  2005/01/06 17:19:04  sbizet
-- #BugId:907,948,946,947#
-- Added:
-- o software radio off request
-- o Tx immediate stop
-- o radio off when MACADDR does not match
-- o Avoid generating read time out when maxresp =0
--
-- Revision 1.34  2004/12/15 14:53:33  sbizet
-- #BugId:907#
-- Added txv_txant port
--
-- Revision 1.33  2004/10/29 15:54:09  sbizet
-- #BugId:804#
-- Resynchronized b_txdatavalid on bus_gclk
--
-- Revision 1.32  2004/10/25 13:39:55  sbizet
-- #BugId:801#
-- Analog TX IQ swap stuff put in the same generate as
-- RX IQ swap stuff
--
-- Revision 1.31  2004/07/16 07:42:11  Dr.B
-- add pabias info feature
--
-- Revision 1.30  2004/06/04 13:51:50  Dr.C
-- Changed to only one port for Tx/Rx data.
--
-- Revision 1.29  2004/02/19 17:29:54  Dr.B
-- add b_antsel.
--
-- Revision 1.28  2004/01/12 13:46:13  Dr.B
-- retried_parity_err is a pulse.
--
-- Revision 1.27  2004/01/07 13:16:01  Dr.B
-- remove ab_mode condition.
--
-- Revision 1.26  2004/01/07 09:22:18  Dr.B
-- delay rxon_req by masking it when txon_req_ff1 = 1 (instead of txon_req).
--
-- Revision 1.25  2004/01/06 18:07:34  Dr.B
-- mask rxon_req when txon_req.
--
-- Revision 1.24  2003/12/23 16:49:08  Dr.B
-- in hiss mode, startacc is 2 periods.
--
-- Revision 1.23  2003/12/17 15:22:21  Dr.B
-- remove rf_rx when hiss only,
--
-- Revision 1.22  2003/12/08 08:47:43  Dr.B
-- change rxon_reg_req conditions for compensating control signals of modem A.
--
-- Revision 1.21  2003/12/04 10:54:19  Dr.B
-- agc_rxonoff_conf goes to low only when agc has been reset.
--
-- Revision 1.20  2003/12/04 08:30:36  Dr.B
-- add condition on txpwr_req.
--
-- Revision 1.19  2003/12/03 17:33:19  Dr.B
-- add diagport.
--
-- Revision 1.18  2003/12/03 08:17:02  Dr.B
-- reset read time out counter when parity err.
--
-- Revision 1.17  2003/12/01 13:24:33  Dr.B
-- debug txonoff_conf when txstartdel = 0
--
-- Revision 1.16  2003/12/01 10:02:49  Dr.B
-- delay txonoff_req for timings matters.
--
-- Revision 1.15  2003/11/27 10:26:11  Dr.B
-- memo of data when idle.
--
-- Revision 1.14  2003/11/26 16:09:58  Dr.B
-- soft_req delayed.
--
-- Revision 1.13  2003/11/21 17:58:47  Dr.B
-- debug conflict accesses + increase clk switch time out.
--
-- Revision 1.12  2003/11/20 11:29:20  Dr.B
-- conflict access included.
--
-- Revision 1.11  2003/11/17 14:52:36  Dr.B
-- add modem request.
--
-- Revision 1.10  2003/11/05 08:32:36  Dr.B
-- add a_txbbronoff_req.
--
-- Revision 1.9  2003/11/03 16:01:18  Dr.B
-- output pa_on.
--
-- Revision 1.8  2003/10/31 08:38:23  Dr.B
-- change enable of the adc order.
--
-- Revision 1.7  2003/10/31 08:11:31  Dr.B
-- no enable of the ADC in hiss mode.
--
-- Revision 1.6  2003/10/30 16:37:27  Dr.B
-- change txpwr size.
--
-- Revision 1.5  2003/10/30 14:42:51  Dr.B
-- update to spec 0.06.
--
-- Revision 1.4  2003/10/24 09:10:46  Dr.C
-- Debugged txonoffconf
--
-- Revision 1.3  2003/10/09 08:30:50  Dr.C
-- Removed glitch found
--
-- Revision 1.2  2003/09/25 12:36:56  Dr.C
-- Added glitch found processing
--
-- Revision 1.1  2003/09/23 13:10:30  Dr.C
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
use IEEE.STD_LOGIC_ARITH.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity reqdata_handler is
  generic (
    ana_digital_g : integer := 3);  -- Selects between analog and HISS interface
                                    -- 0: reserved
                                    -- 1: analog interface
                                    -- 2: digital interface
                                    -- 3: both
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk          : in std_logic;        -- APB clock
    sampling_clk : in std_logic;        -- Sampling clock
    reset_n      : in std_logic;

    --------------------------------------
    -- Tx data
    --------------------------------------
    hiss_rxi_i         : in  std_logic_vector(10 downto 0);
    hiss_rxq_i         : in  std_logic_vector(10 downto 0);
    hiss_rxdatavalid_i : in  std_logic;  -- Toggles when new data is valid
    ana_rxi_i          : in  std_logic_vector(7 downto 0);
    ana_rxq_i          : in  std_logic_vector(7 downto 0);
    --
    hiss_txi_o         : out std_logic_vector(9 downto 0);
    hiss_txq_o         : out std_logic_vector(9 downto 0);
    hiss_txdatavalid_o : out std_logic;  -- Toggles when new data is valid
    ana_txi_o          : out std_logic_vector(7 downto 0);
    ana_txq_o          : out std_logic_vector(7 downto 0);
    
    --------------------------------------
    -- AGCs data
    --------------------------------------
    agc_busy_i             : in std_logic;  -- Indicates RF access restricted to AGC
    agc_bb_switch_ant_tog  : in std_logic;  -- toggle when switch antenna request
    agc_rf_switch_ant_tog  : in std_logic;  -- toggle when switch antenna request
    agc_rxonoff_req_i      : in std_logic;  -- Request to conf. Rx mode
    agc_stream_enable_i    : in std_logic;  -- Enable hiss 'pipe' on reception
    agc_rfoff              : in std_logic;  -- Request from the AGC to stop the
                                            -- radio(MACADDR does not match)
    --
    agc_rxonoff_conf_o     : out  std_logic;   -- Ack to conf. Rx mode
    --------------------------------------
    -- Bup data
    --------------------------------------
    -- modem
    txv_immstop      : in std_logic; -- Bup Tx immediate stop
    txpwr_req_i      : in std_logic; -- Power level programming req.
                                     --(actually connected to phy_txstartend_req
                                     -- to know when BuP requests for Tx)
    txpwr_i          : in std_logic_vector(3 downto 0);  -- Power level
    paindex_i        : in std_logic_vector(4 downto 0); -- index in the PA bias table -
                                                        -- valid with txpwr_req (paindex(0) = PAINDEXL)
    txv_txant_i      : in std_logic;       -- Tx antenna used
    --
    txpwr_conf_o     : out std_logic;   -- Power level programming conf.

    --------------------------------------
    -- Modem data
    --------------------------------------
    a_txdatavalid_i   : in  std_logic;
    b_txdatavalid_i   : in  std_logic;
    a_txonoff_req_i   : in  std_logic;  -- Request to conf. Tx mode
    a_txbbonoff_req_i : in  std_logic;  -- Same as previous but stop when no data in bb
    b_txonoff_req_i   : in  std_logic;  -- Request to conf. Tx mode
    b_txbbonoff_req_i : in  std_logic;  -- Same as previous but stop when no data in bb
    --
    a_rxdatavalid_o   : out std_logic;
    b_rxdatavalid_o   : out std_logic;
    a_txonoff_conf_o  : out std_logic;  -- Conf. Tx mode
    b_txonoff_conf_o  : out std_logic;  -- Conf. Tx mode   
    --
    txi_i             : in  std_logic_vector(9 downto 0);
    txq_i             : in  std_logic_vector(9 downto 0);
    --
    rxi_o             : out std_logic_vector(10 downto 0);
    rxq_o             : out std_logic_vector(10 downto 0);
    
    --------------------------------------
    -- Bup & AGC
    --------------------------------------
    agc_req_i     : in std_logic;       -- AGC requests RF access
    agc_addr_i    : in std_logic_vector(2 downto 0);  -- RF reg. address
    agc_wrdata_i  : in std_logic_vector(7 downto 0);  -- RF reg write data
    agc_wr_i      : in std_logic;       -- RF reg access type
    agc_adcen_i   : in std_logic;       -- Request AGC switch on
    agc_ab_mode_i : in std_logic;       -- Mode of received packet
    tx_ab_mode_i  : in std_logic;       -- Indicates type of packet transmitted
    --
    agc_conf_o    : out std_logic;       -- Conf. to AGC request
    agc_rddata_o  : out std_logic_vector(7 downto 0);   -- RF reg. read data
    
    --------------------------------------
    -- HISS interface
    --------------------------------------
    parityerr_tog_i   : in std_logic;     -- Parity error during access
    agcerr_tog_i      : in std_logic;     -- AGC error parity toggle
    cs_error_i        : in std_logic;     -- CS error when high (pulse whem high)
    protocol_err_i    : in std_logic;     -- Protocol error during access
    clockswitch_req_i : in std_logic;     -- Clock switch has been requested
    clock_switched_i  : in std_logic;     -- Clock has been switched

    --------------------------------------
    -- RF control
    --------------------------------------
    ana_rxen_o           : out std_logic;  -- Enable Rx path
    ana_txen_o           : out std_logic;  -- Enable Tx path
    rf_sw_o              : out std_logic_vector(3 downto 0);  -- RF switches
    pa_on_o              : out std_logic; -- high when PA is on
    ana_adc_en_o         : out std_logic_vector(1 downto 0);  -- ADC enable
    ana_dac_en_o         : out std_logic;  -- DAC enable
    hiss_rxen_o          : out std_logic;  -- Enable reception in Hiss mode
    hiss_txen_o          : out std_logic;  -- Enable transmission in Hiss mode
    txon_req_o           : out std_logic;  -- txon_req
    rf_off_reg_req_o     : out std_logic;  -- additional access to switch off radio
    txv_immstop_masked_o : out std_logic;

    --------------------------------------
    -- Radio interface controller
    --------------------------------------
    ana_accend_i      : in std_logic;   -- Analog int. access finished
    hiss_accend_i     : in std_logic;   -- HISS int. access finished
    ana_rddata_i      : in std_logic_vector(15 downto 0);  -- Analog IF read data
    hiss_rddata_i     : in std_logic_vector(15 downto 0);  -- HISS IF read data
    --
    startacc_o  : out std_logic;        -- Triggers RF controller
    writeacc_o  : out std_logic;        -- RF access type
    rf_addr_o   : out std_logic_vector(5 downto 0);  -- Radio register address
    rf_wrdata_o : out std_logic_vector(15 downto 0);  -- Radio register address
    
    
    --------------------------------------
    -- Register
    --------------------------------------
    soft_req_i     : in  std_logic;  -- Software requests access to RF
    soft_addr_i    : in  std_logic_vector(5 downto 0);  -- RF register address
    soft_wrdata_i  : in  std_logic_vector(15 downto 0);  -- Write data
    soft_acctype_i : in  std_logic;  -- Write data
    rfmode_i       : in  std_logic;  -- Selects HISS/Analog interface
    txiqswap_i     : in  std_logic;  -- Swap Tx I&Q
    rxiqswap_i     : in  std_logic;  -- Swap Rx I&Q
    maxresp_i      : in  std_logic_vector(5 downto 0);  -- Max. response time for
                                                        -- a read access
    maxparerr_i    : in  std_logic_vector(2 downto 0);  -- Max parity errors accepted
    paondel_i      : in  std_logic_vector(7 downto 0);  -- Delay to switch PA on
    forcedacon_i   : in  std_logic; -- when high, always enable dac
    forceadcon_i   : in  std_logic; -- when high, always enable adc
    txstartdel_i   : in  std_logic_vector(7 downto 0);  -- Delay to wait bef send tx_onoff_conf
    band_i         : in  std_logic;     -- Select between 2.4/5 GHz
--    useant_i       : in  std_logic;     -- Indicates which antenna to use
    useant_i       : in  std_logic;     -- Indicates which antenna to use
    antforce_i     : in  std_logic;     -- Forces antenna switch
    swcase_i       : in  std_logic_vector(1 downto 0);  -- Antenna configuration
    sw_rfoff_req_i : in  std_logic;     -- Request to switch off the RF
    --
    rf_off_done_o         : out std_logic;  -- RF has been switched off(Pulse Interrupt)
    b_antsel_o            : out std_logic;  -- give info on the antenna selection for B
    soft_accend_o         : out std_logic;  -- Indicates end of software request
    soft_rddata_o         : out std_logic_vector(15 downto 0);  -- Software read data
    clockswitch_timeout_o : out std_logic;  -- Clock switch time out
    retried_parityerr_o   : out std_logic;  -- Max parity error number reached
    parityerr_o           : out std_logic;  -- a parity error happens
    agcerr_o              : out std_logic;  -- AGC error parity
    conflict_o            : out std_logic;  -- Conflict : RD / RX
    readacc_timeout_o     : out std_logic   -- Read access time out
    
  );

end reqdata_handler;
