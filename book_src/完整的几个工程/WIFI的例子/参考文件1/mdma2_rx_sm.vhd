
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: mdma2_rx_sm.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.22   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : State machine of the rx path.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/mdma2_rx_sm/vhdl/rtl/mdma2_rx_sm.vhd,v  
--  Log: mdma2_rx_sm.vhd,v  
-- Revision 1.22  2005/03/09 14:07:25  Dr.C
-- #BugId:1125#
-- Added WAIT_CCA_LOW state which wait rssi_abovethr_i to low before return to idle.
--
-- Revision 1.21  2005/03/09 12:08:56  Dr.C
-- #BugId:1123#
-- Added channel_decoder_end_i input used to reset rx_path after the end of the channel decoder.
--
-- Revision 1.20  2005/02/07 10:17:46  Dr.C
-- #BugId:1024#
-- Added synchronous reset (from AGC) of iq_estimation control.
--
-- Revision 1.19  2004/12/14 17:22:34  Dr.C
-- #BugId:855#
-- Added unsupported length parameter.
--
-- Revision 1.18  2004/06/18 09:39:15  Dr.C
-- Added disable_output_iq_estim_o.
--
-- Revision 1.17  2004/05/06 13:16:34  Dr.C
-- From RX_IDLE, go directly to WAIT_PREAMB with WILD radio. Added comments and cleaned.
--
-- Revision 1.16  2004/03/24 09:13:09  Dr.C
-- Updated for IAC transmission.
--
-- Revision 1.15  2004/03/13 15:41:51  Dr.F
-- reset state machine when tx enable even in ADC_PU or WAIT_PREAMBLE states.
--
-- Revision 1.14  2003/12/18 17:00:17  Dr.C
-- Changed rx_start_end_ind_o generation during SIG_ERROR state for WILDRF radio.
--
-- Revision 1.13  2003/12/16 16:01:11  Dr.C
-- Changed cca_flag activation.
--
-- Revision 1.12  2003/12/12 09:59:25  Dr.C
-- Added mdma_sm_reset_n.
--
-- Revision 1.11  2003/11/25 17:50:08  Dr.C
-- Updated TIME_BEFORE_IQ_ESTIM_ENABLE_CT because the iq_compensation is now before the iq_estimation. We have added the delay of the iq_estimation.
--
-- Revision 1.10  2003/09/17 06:51:07  Dr.F
-- added enable_iq_estim.
-- Reduced the worst case wait state duration.
-- Debugged ADC sleep.
--
-- Revision 1.9  2003/09/10 07:21:03  Dr.F
-- removed modem_enable port.
--
-- Revision 1.8  2003/09/04 06:38:56  Dr.F
-- replaced the use of modem_enable by rx_ccarst_req_i.
--
-- Revision 1.7  2003/08/08 10:02:50  Dr.F
-- initialize listen_start at 1 on reset.
--
-- Revision 1.6  2003/08/01 16:04:17  Dr.F
-- modified rxactive_req depending on radio type./
--
-- Revision 1.5  2003/07/29 15:22:14  Dr.F
-- changed listen_start generation.
--
-- Revision 1.4  2003/07/24 06:59:58  Dr.F
-- added listen_start_o.
--
-- Revision 1.3  2003/07/17 13:58:05  Dr.C
-- Updated rx_error value.
--
-- Revision 1.2  2003/05/26 09:24:59  Dr.F
-- added rx_packet_end_o.
--
-- Revision 1.1  2003/03/25 18:05:05  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity mdma2_rx_sm is
  generic (
    -- time needed for the channel decoder to decode the 
    -- signal field from his input
    delay_chdec_sig_g   : integer := 102; 
    -- delay from CCA_flag_i(carry_lost) to intput of channel decoder 
    delay_datapath_g    : integer := 413; 
    -- worse case dalay for the channel decoder
    worst_case_chdec_g  : integer := 150;
    -- radio type : 1 for WILDRF, 0 for IFX
    radio_type_g        : integer := 1   
    );
  port (
    clk                       : in  std_logic;  -- Module clock
    reset_n                   : in  std_logic;  -- asynchronous reset
    mdma_sm_rst_n             : in  std_logic;  -- synchronous reset
    reset_dp_modules_n_o      : out std_logic;  -- `0': Reset data path modules.
    --
    calmode_i                 : in  std_logic;  -- IQ calibration mode.
    rx_start_end_ind_o        : out std_logic;  -- rising edge: PHY_RXSTART.ind
                                             -- falling edge: PHY_RXEND.ind
    tx_dac_on_i               : in  std_logic;  -- From TX
    rxactive_req_o            : out std_logic;  -- To RF Control
    rxactive_conf_i           : in  std_logic;  -- From RF Control
    rx_packet_end_o           : out std_logic;  -- pulse on end of RX packet
    enable_iq_estim_o         : out std_logic;  -- `1': enable iq estimation block.
    disable_output_iq_estim_o : out std_logic;  -- `1': disable iq estimation outputs.

    --------------------------------------------
    -- I/F to MAC
    --------------------------------------------
    rx_error_o             : out std_logic_vector(1 downto 0);  --RXERROR 
                                   -- vector is valid at     
                                   -- the falling edge of rx_start_end_ind_o.
                                   -- The coding is as follows:
                                   -- 0b00: No Error
                                   -- 0b01: Format Violation
                                   -- 0b10: Carrier lost
                                   -- 0b11: Unsupported rate
    rxv_length_o           : out std_logic_vector(11 downto 0);  -- RXVECTOR 
                                   -- length parameter is valid when
                                   -- rx_start_end_ind_o goes from 0 to 1.
    -- RXVECTOR rate parameter       
    rxv_rate_o             : out std_logic_vector(3 downto 0);
    rx_cca_ind_o           : out std_logic;  -- 0: IDLE 
                                             -- 1: BUSY 
    --
    rx_ccareset_req_i      : in  std_logic; -- CCA Reset
    rx_ccareset_confirm_o  : out std_logic;
    --------------------------------------------
    -- SIGNAL Field from channel decoder
    --------------------------------------------
    signal_field_unsup_rate_i   : in  std_logic;  -- 1: The rate computed in
                                        -- the signal field is not valid
    signal_field_unsup_length_i : in  std_logic;  -- 1: The length computed in
                                        -- the signal field is not valid
    -- This contains the RATE, LENGTH the reserved bit and the parity bit
    signal_field_i              : in  std_logic_vector(17 downto 0);
    signal_field_parity_error_i : in  std_logic;
    signal_field_valid_i        : in  std_logic;  -- 1: The signal field has 
                                        -- been decoded and the data is
                                        -- available. This signal is active
                                        -- for one cycle.
    --------------------------------------------
    -- End of channel decoder
    --------------------------------------------
    channel_decoder_end_i        : in std_logic;
    --------------------------------------------
    -- AGC/Power estimation blocks
    --------------------------------------------
    listen_start_o              : out std_logic;  -- high when start to listen
    rssi_abovethr_i             : in  std_logic;  -- RSSI above threshold
    rssi_enable_o               : out std_logic;  -- RSSI ADC Enable
    --------------------------------------------
    -- Preamble detection from Init sync
    --------------------------------------------
    -- Confirm preamble detection
    tdone_i                     : in std_logic;  
    --------------------------------------------
    -- I and Q ADCs control
    --------------------------------------------
    adc_powerdown_dyn_i         : in  std_logic;  -- From control regs
    adc_powctrl_o               : out std_logic_vector(1 downto 0);
    --------------------------------------------
    -- Internal state for debug
    --------------------------------------------
    rx_gsm_state_o              : out std_logic_vector(3 downto 0)
    
  );

end mdma2_rx_sm;
