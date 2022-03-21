
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: modema2_registers.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.35   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Registers of the WiLD Modem A2.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/modema2_registers/vhdl/rtl/modema2_registers.vhd,v  
--  Log: modema2_registers.vhd,v  
-- Revision 1.35  2005/03/30 14:26:31  Dr.C
-- #BugId:1171#
-- Force UPG to 3 according to the FS.
--
-- Revision 1.34  2005/02/23 16:20:48  Dr.C
-- #BugId:794#
-- Removed part of init_sync_cntl register in case of Analog mode only.
--
-- Revision 1.33  2005/01/19 16:45:43  Dr.C
-- #BugId:737#
-- Added res_dco_disb_o to disable residual_dc_offset. Changed gen_frontend_reg_g to radio_interface_g to be complain with .11g top block.
--
-- Revision 1.32  2004/12/22 16:41:39  Dr.C
-- #BugId:794#
-- Removed some registers in case of Analog mode only according to spec 1.02.
--
-- Revision 1.31  2004/12/21 14:12:11  Dr.C
-- #BugId:772#
-- Changed rx_length_limit init value.
--
-- Revision 1.30  2004/12/20 09:01:48  Dr.C
-- #BugId:810,910#
-- Added ybnb and reduce length of frq offset estimation.
--
-- Revision 1.29  2004/12/14 17:39:26  Dr.C
-- #BugId:794,810#
-- Added debug port and gen_frontend_reg generic.
--
-- Revision 1.28  2004/05/24 17:13:45  Dr.C
-- Updated version register.
--
-- Revision 1.27  2004/04/26 08:11:30  Dr.C
-- Added register on rdata busses.
--
-- Revision 1.26  2004/04/02 14:38:16  Dr.C
-- Updated default value for wfwin.
--
-- Revision 1.25  2004/03/25 17:19:09  Dr.C
-- Changed tx_enddel default value.
--
-- Revision 1.24  2003/12/03 14:38:31  Dr.C
-- Added dc_off_disb.
--
-- Revision 1.23  2003/11/25 18:19:47  Dr.C
-- Added iq_mm_estrst_done_i.
--
-- Revision 1.22  2003/11/14 15:43:58  Dr.C
-- Added tx_const_o and changed dac_on2off in tx_enddel.
--
-- Revision 1.21  2003/11/07 09:49:50  Dr.C
-- Debugged sentivity list.
--
-- Revision 1.20  2003/11/03 08:56:38  Dr.C
-- Added c2disb_rx and c2disb_tx.
--
-- Revision 1.19  2003/10/23 16:28:37  Dr.C
-- Updated block according to spec 0.16.
--
-- Revision 1.18  2003/09/22 09:53:50  Dr.C
-- Removed calvalid_i.
--
-- Revision 1.17  2003/09/18 12:55:29  Dr.C
-- Updated equalyzer default value.
--
-- Revision 1.16  2003/08/29 16:34:36  Dr.B
-- change iq_comp ampl default values.
--
-- Revision 1.15  2003/06/30 08:30:53  arisse
-- Updated block according to spec 0.15.
--
-- Revision 1.14  2003/06/04 14:33:04  rrich
-- Fixed iq_mm_estrst - this bit always read as '0'
--
-- Revision 1.13  2003/05/15 07:48:13  arisse
-- Changed a comment.
--
-- Revision 1.12  2003/05/13 07:48:27  arisse
-- Added version register.
--
-- Revision 1.11  2003/04/29 15:17:13  Dr.A
-- rx_iq_g_preset reset to 1.
--
-- Revision 1.10  2003/04/28 10:12:59  arisse
-- Changed file according to modema2 spec rev 0.13.
--
-- Revision 1.9  2003/04/07 13:36:24  Dr.A
-- Removed calgener, changed freq0 size in CALIBCNTL1.
--
-- Revision 1.8  2003/04/04 12:35:33  arisse
-- Updated sensitivity lists.
--
-- Revision 1.7  2003/04/04 10:04:36  arisse
-- Removed all the intermediate 32-bit registers.
-- Changed name from int_filter_sign_q_swap_o to tx_iq_swap,
-- from int_filter_bypass_o to tx_filter_bypass,
-- from iq_swap_o to rx_iq_swap_o,
-- from bypass_o to rx_filter_bypass_o.
-- Modified register MdmaPRBSCNTL as a writable register.
--
-- Revision 1.6  2003/04/03 10:01:19  Dr.A
-- Added calib_test.
--
-- Revision 1.5  2003/03/28 16:30:26  arisse
-- Removed apb_rdata_ext_i.
--
-- Revision 1.4  2003/03/28 15:19:59  arisse
-- Removed outputs : agc_uadc_i, agc_urssi_i, a
-- agc_ant_power_in_i.
-- Removed signals : agc_calib1 and agc_calib2.
--
-- Revision 1.3  2003/03/27 10:07:37  arisse
-- Removed calmav_re_o, calmav_im_o, calpow_re_i and calpow_im_o.
--
-- Revision 1.2  2003/03/27 09:23:28  arisse
-- Removed registers initsync_ctrl1_init, initsync_ctrl2,
-- initsync_ctrl3_init, initsync_ctrl4_init.
-- Replaced by one register initsync_ctrl_init at address 34'h.
-- Compliant with spec 0.10.
--
-- Revision 1.1  2003/03/19 10:32:18  arisse
-- Initial revision
--
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

--library modema2_registers_rtl;
library work;
--use modema2_registers_rtl.modema2_registers_pkg.all;
use work.modema2_registers_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity modema2_registers is
  generic (
    -- Use of Front-end register : 1 or 3 for use, 2 for don't use
    -- If the HiSS interface is used, the front-end is a part of the radio and
    -- so during the synthesis these registers could be removed.
    radio_interface_g   : integer := 2 -- 0 -> reserved
    );                                 -- 1 -> only Analog interface
                                       -- 2 -> only HISS interface
  port (                               -- 3 -> both interfaces (HISS and Analog)
    reset_n             : in  std_logic;  -- asynchronous negative reset
    -- APB interface
    apb_clk             : in  std_logic;  -- APB clock (sync with clk in)
    apb_sel_i           : in  std_logic;  -- APB select
    apb_enable_i        : in  std_logic;  -- APB enable
    apb_write_i         : in  std_logic;  -- APB write
    apb_addr_i          : in  std_logic_vector(5 downto 0);   -- APB address
    apb_wdata_i         : in  std_logic_vector(31 downto 0);  -- APB write data
    apb_rdata_o         : out std_logic_vector(31 downto 0);  -- APB read data
    -- Clock controls
    calib_test_o        : out std_logic;  -- Do not gate clocks when high
    -- MDMaTXCNTL
    add_short_pre_o     : out std_logic_vector(1 downto 0);
    scrmode_o           : out std_logic;  -- '1' to tx scrambler.
    tx_filter_bypass_o  : out std_logic;  -- to tx_rx_filter
    dac_powerdown_dyn_o : out std_logic;
    tx_enddel_o         : out std_logic_vector(7 downto 0);  -- to Tx mux
    scrinitval_o        : out std_logic_vector(6 downto 0);  -- Seed init value
    tx_scrambler_i      : in  std_logic_vector(6 downto 0);  -- from scrambler
    c2disb_tx_o         : out std_logic;
    tx_norm_factor_o    : out std_logic_vector(7 downto 0);  -- to tx_rx_filter
    -- MDMaTXIQCOMP
    tx_iq_phase_o       : out std_logic_vector(5 downto 0);  -- to tx iq_comp
    tx_iq_ampl_o        : out std_logic_vector(8 downto 0);  -- to tx iq_comp
    -- MDMaTXCONST
    tx_const_o          : out std_logic_vector(7 downto 0);  -- to DAC (I only)
    -- MDMaRXCNTL0
    rx_iq_step_ph_o     : out std_logic_vector(7 downto 0);
    rx_iq_step_g_o      : out std_logic_vector(7 downto 0);
    adc_powerdown_dyn_o : out std_logic;
    c2disb_rx_o         : out std_logic;
    wf_window_o         : out std_logic_vector(1 downto 0);  -- to wiener
    reduceerasures_o    : out std_logic_vector(1 downto 0);  -- to rx_equ
    res_dco_disb_o      : out std_logic;                     -- to residual_dc_offset
    iq_mm_estrst_o      : out std_logic;                     -- to iq_estimation
    iq_mm_estrst_done_i : in  std_logic;
    iq_mm_est_o         : out std_logic;                     -- to iq_estimation
    dc_off_disb_o       : out std_logic;                     -- to dc_offset
    -- MDMaRXCNTL1
    rx_del_dc_cor_o     : out std_logic_vector(7 downto 0);  -- to dc_offset
    rx_length_limit_o   : out std_logic_vector(11 downto 0); -- to rx_sm
    rx_length_chk_en_o  : out std_logic;
    -- MDMaRXIQPRESET
    rx_iq_ph_preset_o   : out std_logic_vector(15 downto 0);
    rx_iq_g_preset_o    : out std_logic_vector(15 downto 0);
    -- MDMaRXIQEST
    rx_iq_ph_est_i      : in  std_logic_vector(15 downto 0);
    rx_iq_g_est_i       : in  std_logic_vector(15 downto 0);
    -- MDMaTIMEDOMSTAT
    rx_ybnb_i           : in  std_logic_vector(6 downto 0);
    rx_freq_off_est_i   : in  std_logic_vector(19 downto 0);
    -- MDMaEQCNTL1
    histoffset18_o      : out std_logic_vector(1 downto 0);
    histoffset12_o      : out std_logic_vector(1 downto 0);
    histoffset9_o       : out std_logic_vector(1 downto 0);
    histoffset6_o       : out std_logic_vector(1 downto 0);
    satmaxncar18_o      : out std_logic_vector(5 downto 0);  -- to rx_equ
    satmaxncar12_o      : out std_logic_vector(5 downto 0);  -- to rx_equ
    satmaxncar9_o       : out std_logic_vector(5 downto 0);  -- to rx_equ
    satmaxncar6_o       : out std_logic_vector(5 downto 0);  -- to rx_equ
    -- MDMaEQCNTL2
    histoffset54_o      : out std_logic_vector(1 downto 0);
    histoffset48_o      : out std_logic_vector(1 downto 0);
    histoffset36_o      : out std_logic_vector(1 downto 0);
    histoffset24_o      : out std_logic_vector(1 downto 0);
    satmaxncar54_o      : out std_logic_vector(5 downto 0);  -- to rx_equ
    satmaxncar48_o      : out std_logic_vector(5 downto 0);  -- to rx_equ
    satmaxncar36_o      : out std_logic_vector(5 downto 0);  -- to rx_equ
    satmaxncar24_o      : out std_logic_vector(5 downto 0);  -- to rx_equ
    -- MDMaINITSYNCCNTL
    detect_thr_carrier_o : out std_logic_vector(3 downto 0);
    initsync_timoffst_o : out std_logic_vector(2 downto 0);
    -- Combiner accumulator for slow preamble detection
    initsync_autothr1_o : out std_logic_vector(5 downto 0);
    -- Combiner accumulator for fast preamble detection
    initsync_autothr0_o : out std_logic_vector(5 downto 0);
    -- MDMaPRBSCNTL
    prbs_inv_o          : out std_logic;
    prbs_sel_o          : out std_logic_vector(1 downto 0);
    prbs_init_o         : out std_logic_vector(22 downto 0);
    -- MDMaIQCALIBCNTL
    calmode_o           : out std_logic;
    calgain_o           : out std_logic_vector(2 downto 0);
    calfrq0_o           : out std_logic_vector(22 downto 0)
    );

end modema2_registers;
