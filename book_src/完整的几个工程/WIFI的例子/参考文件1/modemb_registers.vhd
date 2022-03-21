
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: modemb_registers.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.33   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Registers for the 802.11b Wild Modem.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/modemb_registers/vhdl/rtl/modemb_registers.vhd,v  
--  Log: modemb_registers.vhd,v  
-- Revision 1.33  2005/04/25 15:09:07  arisse
-- #BugId:1227#
-- Changed reset value of MAXSTAGE register.
--
-- Revision 1.32  2005/04/11 16:16:01  arisse
-- #BugId:983#
-- Changer version register.
--
-- Revision 1.31  2005/02/11 14:44:25  arisse
-- #BugId:795#
-- Changed use of generic.
--
-- Revision 1.30  2005/02/10 16:52:11  arisse
-- #BugId:953#
-- Remove resynchronization of status signal (this was not used and they are buses).
--
-- Revision 1.29  2005/02/10 08:43:07  arisse
-- #BugId:795#
-- Corrected test on value of radio_interface_g.
-- When radio_interface_g = 2, set intermediate signal to 0, otherwise the report detect a latch and remove it.
--
-- Revision 1.28  2005/01/24 14:06:16  arisse
-- #BugId:624,684,795#
-- - Added status registers.
-- - Cleaned registers
-- - Added Interp_max_stage register.
-- - Added generic for front-end registers.
--
-- Revision 1.27  2004/08/26 16:00:48  arisse
-- Changed version register.
--
-- Revision 1.26  2004/05/07 16:26:17  Dr.A
-- prdata mux controlled by psel (and not penable)
--
-- Revision 1.25  2004/04/26 08:55:29  arisse
-- Added flip-flop on prdata bus.
--
-- Revision 1.24  2003/12/02 18:55:03  arisse
-- Resynchronized reg_sq, reg_ed, reg_cs, reg_rssi.
--
-- Revision 1.23  2003/12/02 09:26:56  arisse
-- Updated registers according to spec modemb 1.02 :
-- - Modified reset values,
-- - Changed c2disb in rxc2disb,
-- - Added txc2disb, txconst, txenddel.
--
-- Revision 1.22  2003/11/04 09:41:04  Dr.C
-- Updated c2disb to 1 by default.
--
-- Revision 1.21  2003/10/09 08:23:24  Dr.B
-- Updated MDMBCNTL(11) register, updated port with new output reg_int.
--
-- Revision 1.20  2003/02/13 07:45:45  Dr.C
-- Added adcpdmod
--
-- Revision 1.19  2003/01/20 11:21:09  Dr.C
-- Added disable bit for AGC.
--
-- Revision 1.18  2003/01/10 18:27:45  Dr.A
-- Updated build (26).
--
-- Revision 1.17  2003/01/09 15:27:20  Dr.A
-- Updated to spec 17.
--
-- Revision 1.16  2002/11/28 10:21:21  Dr.A
-- Updated to Modemb v0.17.
--
-- Revision 1.15  2002/11/08 10:18:35  Dr.A
-- Reset rssi and accoup registers.
--
-- Revision 1.14  2002/11/05 10:06:24  Dr.A
-- Updated to spec 0.15.
--
-- Revision 1.13  2002/10/10 15:27:45  Dr.A
-- Added interpdisb.
--
-- Revision 1.12  2002/10/04 16:23:59  Dr.A
-- Added  registers for Modem v0.15.
--
-- Revision 1.11  2002/09/20 15:10:38  Dr.F
-- added the version register.
--
-- Revision 1.10  2002/09/12 14:23:14  Dr.F
-- added reg_compdisb bit.
--
-- Revision 1.9  2002/09/09 14:26:22  Dr.A
-- Updated CCA registers.
--
-- Revision 1.8  2002/07/31 07:00:59  Dr.A
-- Added eq_disb bit.
-- Changed signal quality registers size.
--
-- Revision 1.7  2002/07/12 12:30:26  Dr.A
-- Updated to spec 0.13
--
-- Revision 1.6  2002/06/07 13:24:29  Dr.A
-- Reset PRMINIT register.
--
-- Revision 1.5  2002/06/03 16:18:35  Dr.A
-- Changed paddr size.
-- Updated MDMbCNTL register.
-- Added MDMbPRECOMP, MDMbCCA and MDMbEQTIME registers.
--
-- Revision 1.4  2002/05/07 16:15:36  Dr.A
-- Added sqthres register.
--
-- Revision 1.3  2002/04/23 16:26:03  Dr.A
-- Removed tea0 and tpa0 registers.
-- Completed prdata sensitivity list.
--
-- Revision 1.2  2002/03/22 17:47:33  Dr.A
-- Added registers.
--
-- Revision 1.1  2002/02/06 10:29:51  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library modemb_registers_rtl; 
library work;
--use modemb_registers_rtl.modemb_registers_pkg.all;
use work.modemb_registers_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity modemb_registers is
  generic (
    radio_interface_g : integer := 2   -- 0 -> reserved
    );                                 -- 1 -> only Analog interface
                                       -- 2 -> only HISS interface
  port (                               -- 3 -> both interfaces (HISS and Analog)
    --------------------------------------------
    -- clock and reset
    --------------------------------------------
    reset_n         : in  std_logic; -- Reset.
    pclk            : in  std_logic; -- APB clock.

    --------------------------------------------
    -- APB slave
    --------------------------------------------
    psel            : in  std_logic; -- Device select.
    penable         : in  std_logic; -- Defines the enable cycle.
    paddr           : in  std_logic_vector( 5 downto 0); -- Address.
    pwrite          : in  std_logic; -- Write signal.
    pwdata          : in  std_logic_vector(31 downto 0); -- Write data.
    --
    prdata          : out std_logic_vector(31 downto 0); -- Read data.
  
    --------------------------------------------
    -- Modem Registers Inputs
    --------------------------------------------

    -- MDMbSTAT0 register. 
    reg_eqsumq : in std_logic_vector(7 downto 0);
    reg_eqsumi : in std_logic_vector(7 downto 0);  
    reg_dcoffsetq : in std_logic_vector(5 downto 0);
    reg_dcoffseti : in std_logic_vector(5 downto 0);

    -- MDMbSTAT1 register.
    reg_iqgainestim : in std_logic_vector(6 downto 0);
    reg_freqoffestim : in std_logic_vector(7 downto 0);
    
    --------------------------------------------
    -- Modem Registers Outputs
    --------------------------------------------
    -- MDMbCNTL register.
    reg_tlockdisb        : out std_logic; -- '0': use timing lock from service field.
    reg_rxc2disb         : out std_logic; -- '1' to disable 2 complement.
    reg_interpdisb       : out std_logic; -- '0' to enable interpolator.
    reg_iqmmdisb         : out std_logic; -- '0' to enable I/Q mismatch compensation.
    reg_gaindisb         : out std_logic; -- '0' to enable the gain compensation.
    reg_precompdisb      : out std_logic; -- '0' to enable timing offset compensation
    reg_dcoffdisb        : out std_logic; -- '0' to enable the DC offset compensation
    reg_compdisb         : out std_logic; -- '0' to enable the compensation.
    reg_eqdisb           : out std_logic; -- '0' to enable the Equalizer.
    reg_firdisb          : out std_logic; -- '0' to enable the FIR.
    reg_spreaddisb       : out std_logic; -- '0' to enable spreading.                        
    reg_scrambdisb       : out std_logic; -- '0' to enable scrambling.
    reg_sfderr           : out std_logic_vector( 2 downto 0); -- Error number for SFD
    reg_interfildisb     : out std_logic; -- '1' to bypass rx_11b_interf_filter 
    reg_txc2disb         : out std_logic; -- '1' to disable 2 complement.   
    -- Number of preamble bits to be considered in short SFD comparison.
    reg_sfdlen      : out std_logic_vector( 2 downto 0);
    reg_prepre      : out std_logic_vector( 5 downto 0); -- pre-preamble count.
    
    -- MDMbPRMINIT register.
    -- Values for phase correction parameters.
    reg_rho         : out std_logic_vector( 1 downto 0);
    reg_mu          : out std_logic_vector( 1 downto 0);
    -- Values for phase feedforward equalizer parameters.
    reg_beta        : out std_logic_vector( 1 downto 0);
    reg_alpha       : out std_logic_vector( 1 downto 0);

    -- MDMbTALPHA register.
    -- TALPHA time interval value for equalizer alpha parameter.
    reg_talpha3     : out std_logic_vector( 3 downto 0);
    reg_talpha2     : out std_logic_vector( 3 downto 0);
    reg_talpha1     : out std_logic_vector( 3 downto 0);
    reg_talpha0     : out std_logic_vector( 3 downto 0);
    
    -- MDMbTBETA register.
    -- TBETA time interval value for equalizer beta parameter.
    reg_tbeta3      : out std_logic_vector( 3 downto 0);
    reg_tbeta2      : out std_logic_vector( 3 downto 0);
    reg_tbeta1      : out std_logic_vector( 3 downto 0);
    reg_tbeta0      : out std_logic_vector( 3 downto 0);
    
    -- MDMbTMU register.
    -- TMU time interval value for phase correction and offset comp. mu param
    reg_tmu3        : out std_logic_vector( 3 downto 0);
    reg_tmu2        : out std_logic_vector( 3 downto 0);
    reg_tmu1        : out std_logic_vector( 3 downto 0);
    reg_tmu0        : out std_logic_vector( 3 downto 0);

    -- MDMbCNTL1 register.
    reg_rxlenchken  : out std_logic;
    reg_rxmaxlength : out std_logic_vector(11 downto 0);
    
    -- MDMbRFCNTL register.
    -- AC coupling gain compensation.
    -- Value to be sent to the I data before the Tx packets for
    -- auto-calibration of the transmit path.
    reg_txconst     : out std_logic_vector(7 downto 0);
    -- Delay of the Tx front-end inside the WILD RF, in number of 44 MHz cycles.
    reg_txenddel    : out std_logic_vector(7 downto 0);

    -- MDMbCCA register.
    reg_ccamode     : out std_logic_vector( 2 downto 0); -- CCA mode select.

    -- MDMbEQCNTL register.
    -- Delay to stop the equalizer adaptation after the last param update, in 탎
    reg_eqhold      : out std_logic_vector(11 downto 0);
    -- Delay to start the compensation after the start of the estimation, in 탎.
    reg_comptime    : out std_logic_vector( 4 downto 0);
    -- Delay to start the estimation after the enabling of the equalizer, in 탎.
    reg_esttime     : out std_logic_vector( 4 downto 0);
    -- Delay to switch on the equalizer after the fine gain setting, in 탎.
    reg_eqtime      : out std_logic_vector( 3 downto 0);

    -- MDMbCNTL2 register
    reg_maxstage    : out std_logic_vector(5 downto 0);
    reg_precomp     : out std_logic_vector( 5 downto 0); -- in us.
    reg_synctime    : out std_logic_vector( 5 downto 0);
    reg_looptime    : out std_logic_vector( 3 downto 0)
  );

end modemb_registers;
