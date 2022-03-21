
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem
--    ,' GoodLuck ,'      RCSfile: modem802_11b_core.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.40   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Modem 802_11b core
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/modem802_11b/vhdl/rtl/modem802_11b_core.vhd,v  
--  Log: modem802_11b_core.vhd,v  
-- Revision 1.40  2005/10/07 12:47:18  arisse
-- #BugId:983#
-- Removed unused signals.
--
-- Revision 1.39  2005/09/20 09:52:47  arisse
-- #BugId:1385#
-- Added output gaindisb_out to connect register gaindisb to block of Gain_Compensation into Front-End.
--
-- Revision 1.38  2005/03/01 16:16:23  arisse
-- #BugId:983#
-- Added globals.
--
-- Revision 1.37  2005/02/11 14:51:39  arisse
-- #BugId:953#
-- Removed resynchronization of Rho (bus).
-- Added globals.
--
-- Revision 1.36  2005/02/02 14:40:16  arisse
-- #BugId:977#
-- Modified rx_gating signal to enable and cut the clock only when we need.
--
-- Revision 1.35  2005/01/26 10:49:33  arisse
-- #BugId:977#
-- Added one clock cycle more to rx_gating.
--
-- Revision 1.34  2005/01/24 15:34:00  arisse
-- #BugId:624,684,795#
-- Added interp_max_stage.
-- Added generic for front-end registers.
--
-- Revision 1.33  2005/01/11 10:15:57  arisse
-- #BugId:953#
-- Resynchronizations of signals.
--
-- Revision 1.32  2004/12/22 13:40:24  arisse
-- #BugId:854#
-- Added hard-coded registers rxlenchken and rxmaxlength.
--
-- Revision 1.31  2004/12/21 13:21:09  Dr.J
-- #BugId:606#
-- Use the modemb clock instead of the rx_pathb_gclk to clock the rx_cntl block and the cca_busy.
--
-- Revision 1.30  2004/12/20 16:24:17  arisse
-- #BugId:596#
-- Updated tx_path_core with txv_immstop for BT Co-existence.
--
-- Revision 1.29  2004/12/14 16:52:48  arisse
-- #BugId:596#
-- Added BT Co-existence feature.
--
-- Revision 1.28  2004/09/13 08:45:58  arisse
-- Added modemb_registers_if block and resynchronized rf_txonoff_conf and rf_rxonoff_conf.
--
-- Revision 1.27  2004/08/24 13:42:59  arisse
-- Added globals for testbench.
--
-- Revision 1.26  2004/04/27 09:17:45  arisse
-- Added 1 bit to applied_mu.
--
-- Revision 1.25  2004/03/11 11:08:39  arisse
-- Removed rx_path_b_gclk and tx_path_b_gclk from modem_diag1.
--
-- Revision 1.24  2004/02/10 14:38:19  Dr.C
-- Re-synchronized gating conditions and added clk input.
--
-- Revision 1.23  2003/12/12 08:50:06  Dr.C
-- Changed cca_busy to cca_busy_resync for gating condition.
--
-- Revision 1.22  2003/12/12 08:48:10  Dr.C
-- Updated gating condition with new AGC/CCA.
--
-- Revision 1.21  2003/12/03 09:38:10  arisse
-- Resynchronization of correl_rst_n, reg_cs, agcproc_end, ed_stat, cca_busy.
--
-- Revision 1.20  2003/12/02 09:31:32  arisse
-- Modified modemb_registers declaration :
-- txconst, rxc2disb, txc2disb, txenddel.
--
-- Revision 1.19  2003/12/01 11:00:51  arisse
-- Removed resynchronization of cca_busy.
--
-- Revision 1.18  2003/11/29 16:05:46  arisse
-- Removed resynchronization of ed_stat.
--
-- Revision 1.17  2003/11/28 17:26:03  arisse
-- Resynchronized Rho.
--
-- Revision 1.16  2003/11/28 17:13:42  arisse
-- Resynchronized ed_stat and cca_busy.
--
-- Revision 1.15  2003/11/13 08:10:11  Dr.C
-- Updated gating condition. Will be uncommented with next version of AGC/CCA.
--
-- Revision 1.14  2003/11/03 15:10:03  Dr.B
-- add txenddel.
--
-- Revision 1.13  2003/10/17 08:26:02  arisse
-- Changed order of signals in diag ports.
--
-- Revision 1.12  2003/10/16 14:22:40  arisse
-- Added diag ports.
--
-- Revision 1.11  2003/10/14 07:00:56  Dr.C
-- Changed gating condition.
--
-- Revision 1.10  2003/10/13 12:18:04  Dr.C
-- Changed tx_gating.
--
-- Revision 1.9  2003/10/13 08:39:01  Dr.C
-- Added gating conditions for Rx & Tx path.
--
-- Revision 1.8  2003/10/09 08:15:08  Dr.B
-- Added interfildisb and scaling ports.
--
-- Revision 1.7  2003/09/09 13:31:49  Dr.C
-- Removed links between equalizer and power_estim.
--
-- Revision 1.6  2003/07/29 06:32:17  Dr.F
-- added listen_start_o.
--
-- Revision 1.5  2003/07/28 07:16:13  Dr.B
-- remove clk.
--
-- Revision 1.4  2003/07/26 15:19:31  Dr.F
-- added clk port.
--
-- Revision 1.3  2003/07/25 17:22:43  Dr.B
-- new rx_path_core (rx_front_end blocks removed).
--
-- Revision 1.2  2003/07/18 09:03:46  Dr.B
-- fir_phi_out_tog + tx_activated changed.
--
-- Revision 1.1  2003/04/23 07:41:10  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--library modem802_11b_rtl;
library work;
--use modem802_11b_rtl.modem802_11b_pkg.all;
use work.modem802_11b_pkg.all;

--library modem_sm_b_rtl;
library work;

--library crc16_8_rtl;
library work;

--library tx_path_rtl;
library work;
--library rx_path_rtl;
library work;
--library rx_ctrl_rtl;
library work;

--library modemb_registers_rtl;
library work;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity modem802_11b_core is
  generic (
    radio_interface_g : integer := 3   -- 0 -> reserved
    );                                 -- 1 -> only Analog interface
                                       -- 2 -> only HISS interface
  port (                               -- 3 -> both interfaces (HISS and Analog)
   -- clocks and reset
   bus_clk             : in  std_logic; -- apb clock
   clk                 : in  std_logic; -- main clock (not gated)
   rx_path_b_gclk      : in  std_logic; -- gated clock for RX path
   tx_path_b_gclk      : in  std_logic; -- gated clock for TX path
   reset_n             : in  std_logic; -- global reset  
   --
   rx_gating           : out std_logic; -- Gating condition for Rx path
   tx_gating           : out std_logic; -- Gating condition for Tx path
  
   --------------------------------------------
   -- APB slave
   --------------------------------------------
   psel                : in  std_logic; -- Device select.
   penable             : in  std_logic; -- Defines the enable cycle.
   paddr               : in  std_logic_vector( 5 downto 0); -- Address.
   pwrite              : in  std_logic; -- Write signal.
   pwdata              : in  std_logic_vector(31 downto 0); -- Write data.
   --
   prdata              : out std_logic_vector(31 downto 0); -- Read data.
  
   --------------------------------------------
   -- Interface with Wild Bup
   --------------------------------------------
   -- inputs signals                                                           
   bup_txdata          : in  std_logic_vector(7 downto 0); -- data to send         
   phy_txstartend_req  : in  std_logic; -- request to start a packet transmission    
   phy_data_req        : in  std_logic; -- request to send a byte                  
   phy_ccarst_req      : in  std_logic; -- request to reset CCA state machine                 
   txv_length          : in  std_logic_vector(11 downto 0);  -- RX PSDU length     
   txv_service         : in  std_logic_vector(7 downto 0);  -- tx service field   
   txv_datarate        : in  std_logic_vector( 3 downto 0); -- PSDU transm. rate
   txpwr_level         : in  std_logic_vector( 2 downto 0); -- TX power level.
   txv_immstop         : in std_logic;  -- request from Bup to stop tx.
    
   -- outputs signals                                                          
   phy_txstartend_conf : out std_logic; -- transmission started, ready for data  
   phy_rxstartend_ind  : out std_logic; -- indication of RX packet                     
   phy_data_conf       : out std_logic; -- last byte was read, ready for new one 
   phy_data_ind        : out std_logic; -- received byte ready                  
   rxv_length          : out std_logic_vector(11 downto 0);  -- RX PSDU length  
   rxv_service         : out std_logic_vector(7 downto 0);  -- rx service field
   rxv_datarate        : out std_logic_vector( 3 downto 0); -- PSDU rec. rate
   rxe_errorstat       : out std_logic_vector(1 downto 0);-- packet recep. stat
   phy_cca_ind         : out std_logic; -- CCA status                           
   bup_rxdata          : out std_logic_vector(7 downto 0); -- data received      
   
   --------------------------------------------
   -- Radio controller interface
   --------------------------------------------
   rf_txonoff_conf     : in  std_logic;  -- Radio controller in TX mode conf
   rf_rxonoff_conf     : in  std_logic;  -- Radio controller in RX mode conf
   --
   rf_txonoff_req      : out std_logic;  -- Radio controller in TX mode req
   rf_rxonoff_req      : out std_logic;  -- Radio controller in RX mode req
   rf_dac_enable       : out std_logic;  -- DAC enable
   
   --------------------------------------------
   -- AGC
   --------------------------------------------
   agcproc_end         : in std_logic;
   cca_busy            : in std_logic;
   correl_rst_n        : in std_logic;
   agc_diag            : in std_logic_vector(15 downto 0);
   --
   psdu_duration       : out std_logic_vector(15 downto 0);
   correct_header      : out std_logic;
   plcp_state          : out std_logic;
   plcp_error          : out std_logic;
   listen_start_o      : out std_logic; -- high when start to listen
   -- registers
   interfildisb        : out std_logic;
   ccamode             : out std_logic_vector( 2 downto 0);
   --
   sfd_found           : out std_logic;
   symbol_sync2        : out std_logic;
   --------------------------------------------
   -- Data Inputs
   --------------------------------------------
   -- data from gain compensation (inside rx_b_frontend)
   rf_rxi              : in  std_logic_vector(7 downto 0);
   rf_rxq              : in  std_logic_vector(7 downto 0);
   
   --------------------------------------------
   -- Disable Tx & Rx filter
   --------------------------------------------
   fir_disb            : out std_logic;
   
   --------------------------------------------
   -- Tx FIR controls
   --------------------------------------------
   init_fir            : out std_logic;
   fir_activate        : out std_logic;
   fir_phi_out_tog_o   : out std_logic;
   fir_phi_out         : out std_logic_vector (1 downto 0);
   tx_const            : out std_logic_vector(7 downto 0);
   txc2disb            : out std_logic; -- Complement's 2 disable (from reg)
   
   --------------------------------------------
   -- Interface with RX Frontend
   --------------------------------------------
   -- Control from Registers
   rxc2disb            : out std_logic; -- Complement's 2 disable (from reg)
   interp_disb         : out std_logic; -- Interpolator disable
   clock_lock          : out std_logic;
   tlockdisb           : out std_logic;  -- use timing lock from service field.
   gain_enable         : out std_logic;  -- gain compensation control.
   tau_est             : out std_logic_vector(17 downto 0);
   enable_error        : out std_logic;
   interpmaxstage      : out std_logic_vector(5 downto 0);
   gaindisb_out        : out std_logic;  -- disable the gain compensation.
   --------------------------------------------
   -- Diagnostic port
   --------------------------------------------
   modem_diag          : out std_logic_vector(31 downto 0);
   modem_diag0         : out std_logic_vector(15 downto 0);
   modem_diag1         : out std_logic_vector(15 downto 0);
   modem_diag2         : out std_logic_vector(15 downto 0)    
  );

end modem802_11b_core;
