
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: rx_ctrl.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.19   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : RX path control. This block controls some parts of
--        the rx_path by enabling the different sub-blocks at suitable
--        times.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/rx_ctrl/vhdl/rtl/rx_ctrl.vhd,v  
--  Log: rx_ctrl.vhd,v  
-- Revision 1.19  2004/08/06 12:11:25  arisse
-- Between two packets, reset iqmm_cnt_enable, alpha_param_cnt_enable, alpha_param_cnt, beta_param_cnt, beta_param_cnt_enable, mu_param_cnt_enable, mu_param_cnt signals.
--
-- Revision 1.18  2004/05/17 12:48:56  arisse
-- In processes max_alpha/beta/mu_param_cnt_p : added assignement to next_max_beta/mu_param_cnt when in the case 'when others'.
--
-- Revision 1.17  2004/04/27 09:36:11  arisse
-- Cerrection of array shape mismatch.
--
-- Revision 1.16  2004/04/27 09:19:20  arisse
-- Added one bit to applied_mu (last version is wrong).
--
-- Revision 1.15  2004/04/27 09:15:07  arisse
-- Added 2 bits to applied_mu.
--
-- Revision 1.14  2004/04/16 15:21:58  arisse
-- - Added 1 us between iq_estimation_enable_int=1 and iq_estimation_enable=1.
-- - Creation of signal equalizer_init_n_ff_o which initializates the equalizer
-- one clock cycle after the way it was before.
-- This is done in order to set alpha and this initilization at the same time.
-- - When Talphan, Tbetan or Tmun are set to 0 the equalizer stops switching.
--
-- Revision 1.13  2002/12/03 13:22:59  Dr.F
-- added sfd_detect_enable.
--
-- Revision 1.12  2002/11/28 10:19:49  Dr.A
-- Updatedto Modem v0.17 registers.
--
-- Revision 1.11  2002/11/20 13:22:00  Dr.F
-- delayed gain
-- -enable.
--
-- Revision 1.10  2002/11/06 17:38:36  Dr.F
-- added gain_disb and gain_enable.
--
-- Revision 1.9  2002/11/05 10:03:14  Dr.F
-- trigger counters on agcproc_end.
--
-- Revision 1.8  2002/10/25 16:58:26  Dr.F
-- launch alpha and beta parameters after equalizer init.
--
-- Revision 1.7  2002/10/21 13:59:02  Dr.F
-- added control signals for iq mismatch block.
--
-- Revision 1.6  2002/09/20 15:12:45  Dr.F
-- added comp_disb port.
--
-- Revision 1.5  2002/09/16 16:42:01  Dr.F
-- debugged alpha, neta and mu parameters update.
--
-- Revision 1.4  2002/09/09 14:20:43  Dr.F
-- added 1us counter.
--
-- Revision 1.3  2002/08/08 16:58:45  Dr.F
-- changed condition to disable the phase estimation, the precompensation and the synchronization.
--
-- Revision 1.2  2002/07/31 15:58:20  Dr.F
-- changed reset of equalizer.
--
-- Revision 1.1  2002/07/31 08:11:02  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all; 

--library rx_ctrl_rtl;
library work;
--use rx_ctrl_rtl.rx_ctrl_pkg.all;      
use work.rx_ctrl_pkg.all;      

entity rx_ctrl is
  port (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn             : in  std_logic; -- AHB reset line.
    hclk                : in  std_logic; -- AHB clock line.

    --------------------------------------------
    -- Registers interface
    --------------------------------------------
    eq_disb             : in std_logic; --equalizer disable
    -- delay before enabling the precompensation :
    precomp             : in  std_logic_vector(5 downto 0); 
    -- delay before enabling the equalizer after energy detect
    eqtime              : in  std_logic_vector(3 downto 0); 
    -- delay before disabling the equalizer after last parameter update
    eqhold              : in  std_logic_vector(11 downto 0); 
    -- delay before enabling the phase correction after energy detect
    looptime            : in  std_logic_vector(3 downto 0); 
    -- delay before switching off the timing synchro after energy detect
    synctime            : in  std_logic_vector(5 downto 0); 
    -- initial value of equalizer parameters
    alpha               : in  std_logic_vector(1 downto 0); 
    beta                : in  std_logic_vector(1 downto 0); 
    -- initial value of phase estimation parameters
    mu                  : in  std_logic_vector(1 downto 0); 
    -- Talpha time intervals values for alpha equalizer parameter.
    talpha3             : in  std_logic_vector( 3 downto 0);
    talpha2             : in  std_logic_vector( 3 downto 0);
    talpha1             : in  std_logic_vector( 3 downto 0);
    talpha0             : in  std_logic_vector( 3 downto 0);
    -- Tbeta time intervals values for beta equalizer parameter.
    tbeta3              : in  std_logic_vector( 3 downto 0);
    tbeta2              : in  std_logic_vector( 3 downto 0);
    tbeta1              : in  std_logic_vector( 3 downto 0);
    tbeta0              : in  std_logic_vector( 3 downto 0);
    -- Tmu time interval value for phase correction mu parameter.
    tmu3                : in  std_logic_vector( 3 downto 0);
    tmu2                : in  std_logic_vector( 3 downto 0);
    tmu1                : in  std_logic_vector( 3 downto 0);
    tmu0                : in  std_logic_vector( 3 downto 0);

    --------------------------------------------
    -- Input control
    --------------------------------------------
    energy_detect       : in  std_logic;
    agcproc_end         : in  std_logic; -- pulse on AGC procedure end
    rx_psk_mode         : in  std_logic; -- 0 = BPSK; 1 = QPSK
    rx_idle_state       : in  std_logic;
    precomp_disb        : in  std_logic; -- disable the precompensation 
    comp_disb           : in  std_logic; -- disable the compensation 
                                         -- (error calculation)
    iqmm_disb           : in  std_logic; -- disable iq mismatch
    gain_disb           : in  std_logic; -- disable gain

    --------------------------------------------
    -- RX path control signals
    --------------------------------------------
    equalizer_activate  : out std_logic; -- equalizer enable
    equalizer_init_n    : out std_logic; -- equalizer initialization
    equalizer_disb      : out std_logic; -- equalizer disable
    precomp_enable      : out std_logic; -- frequency precompensation enable
    synctime_enable     : out std_logic; -- timing synchronization enable
    phase_estim_enable  : out std_logic; -- phase estimation enable
    iq_comp_enable      : out std_logic; -- iq mismatch compensation enable
    iq_estim_enable     : out std_logic; -- iq mismatch estimation enable
    gain_enable         : out std_logic; -- gain enable
    sfd_detect_enable   : out std_logic; -- enable SFD detection when high
    -- parameters value sent to the equalizer
    applied_alpha       : out std_logic_vector(2 downto 0);
    applied_beta        : out std_logic_vector(2 downto 0);
    alpha_accu_disb     : out std_logic;
    beta_accu_disb      : out std_logic;
    -- parameters value sent to the phase estimation
    applied_mu          : out std_logic_vector(2 downto 0)
    );

end rx_ctrl;
