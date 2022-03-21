
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: rx_path_core.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.21   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Receive path for 802.11b modem core.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/rx_path/vhdl/rtl/rx_path_core.vhd,v  
--  Log: rx_path_core.vhd,v  
-- Revision 1.21  2005/10/07 08:04:38  arisse
-- #BugId:1404#
-- Replaced data_in_i by data_in_q in assignation of data_dc_q when dcoffdisb = '1'.
--
-- Revision 1.20  2005/01/24 13:55:38  arisse
-- #BugId:624#
-- Added status signals.
--
-- Revision 1.19  2004/08/24 13:42:27  arisse
-- Added globals for testbench.
--
-- Revision 1.18  2004/05/03 13:50:53  pbressy
-- modified list file to remove unused lib and files
--
-- Revision 1.17  2004/04/27 09:22:29  arisse
-- Added one bit to mu in input.
-- Mu_int is '0' & mu now.
--
-- Revision 1.16  2004/04/06 13:17:34  Dr.B
-- Changed the delay for remod_data_delay (from remod_data_dly6_v to
-- remod_data_dly5_v).
-- Removed the "+1" from mu_int generation.
--
-- Revision 1.15  2004/03/29 12:49:20  Dr.B
-- Removed previous modification.
--
-- Revision 1.14  2004/03/29 09:34:08  Dr.B
-- Added symbol_synchro_ff5 to delay data sampled by ffwd_filter in equalizer.
--
-- Revision 1.13  2004/03/24 18:18:34  arisse
-- Went back to version 1.11.
--
-- Revision 1.12  2004/03/24 17:33:55  arisse
-- Removed unused library.
--
-- Revision 1.11  2003/12/15 11:16:39  Dr.B
-- no condition on rx_enable_ff1.
--
-- Revision 1.10  2003/11/29 16:09:18  arisse
-- Resynchronized rx_enable.
--
-- Revision 1.9  2003/10/16 16:20:49  arisse
-- Changed diag_error_i/q to 8 bits instead of 9 bits.
--
-- Revision 1.8  2003/10/16 14:16:10  arisse
-- Added diag ports.
--
-- Revision 1.7  2003/09/23 09:08:54  Dr.B
-- remove delay on remod_data.
--
-- Revision 1.6  2003/09/18 08:41:17  Dr.A
-- Added barker_sync.
--
-- Revision 1.5  2003/09/09 13:10:13  Dr.C
-- Removed links between power_estim and equalizer.
--
-- Revision 1.4  2003/07/25 17:14:26  Dr.B
-- remove rx_b_front_end blocks.
--
-- Revision 1.3  2003/07/07 08:33:03  Dr.J
-- Updated with the new size of the cordic
--
-- Revision 1.2  2003/05/07 13:57:22  Dr.J
-- Added cordic enable
--
-- Revision 1.1  2003/04/23 07:26:53  Dr.C
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
use ieee.std_logic_arith.all; 

--library rx_path_rtl; 
library work;
--use rx_path_rtl.rx_path_pkg.ALL; 
use work.rx_path_pkg.ALL; 

--library rx11b_demod_rtl;
library work;
--library peak_detect_rtl;
library work;
--library decode_path_rtl;
library work;
--library symbol_sync_rtl;
library work;
--library barker_cor_rtl;
library work;
--library cordic_rtl;
library work;
--library equalizer_rtl;
library work;
--library iq_mismatch_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity rx_path_core is

  generic (
    -- number of bits for the complex data :
    data_length_g  : integer := 9;
    -- number of bits for the input angle z_in :
    angle_length_g : integer := 15
    );
  port (
    --------------------------------------------
    -- clocks and reset.
    --------------------------------------------
    reset_n                : in  std_logic;  -- Global reset.
    rx_path_b_gclk         : in  std_logic;  -- Gated Clock for RX Path (44 Mhz).

    --------------------------------------------
    -- Data In. (from gain compensation)
    --------------------------------------------
    data_in_i              : in  std_logic_vector(7 downto 0);
    data_in_q              : in  std_logic_vector(7 downto 0);

    --------------------------------------------
    -- Control for dc_offset compensation.
    --------------------------------------------
    dcoffdisb              : in  std_logic;  -- disable dc_offset compensation when high

    --------------------------------------------
    -- Control for IQ Mismatch Compensation
    --------------------------------------------
    iq_estimation_enable   : in  std_logic;  -- enable the I/Q estimation when high
    iq_compensation_enable : in  std_logic;  -- enable the I/Q compensation when high

    --------------------------------------------
    -- Control for equalization
    --------------------------------------------
    equ_activate           : in  std_logic;  -- enable the equalizer when high.
    equalizer_disb         : in  std_logic;  -- disable the equalizer filter when high.
    equalizer_init_n       : in  std_logic;  -- equalizer filter coeffs set to 0 when low.
    alpha_accu_disb        : in  std_logic;  -- stop coeff accu when high.
    beta_accu_disb         : in  std_logic;  -- stop dc accu when high.
    alpha                  : in  std_logic_vector(2 downto 0);  -- alpha parameter value.
    beta                   : in  std_logic_vector(2 downto 0);  -- beta parameter value.

    --------------------------------------------
    -- Control for DSSS / CCK demodulation
    --------------------------------------------
    interp_disb            : in  std_logic;  -- disable the interpolation when high
    rx_enable              : in  std_logic;  -- enable rx path when high 
    mod_type               : in  std_logic;  -- '0' for DSSS, '1' for CCK.
    enable_error           : in  std_logic;  -- Enable error calculation when high.
    precomp_enable         : in  std_logic;  -- Reload the omega accumulator.
    demod_rate             : in  std_logic;  -- '0' for BPSK, '1' for QPSK.
    cck_rate               : in  std_logic;  -- '0' for 5.5 Mhz, '1' for 11 Mhz.
    rho                    : in  std_logic_vector(1 downto 0);  -- rho parameter value
    mu                     : in  std_logic_vector(2 downto 0);  -- mu parameter value.
    --
    tau_est                : out std_logic_vector(17 downto 0);

    --------------------------------------------
    -- Control for Decode Path
    --------------------------------------------
    scrambling_disb        : in  std_logic;  -- scrambling disable (test mode) 
    decode_path_activate   : in  std_logic;  -- enable the differential decoder
    diff_decod_first_val   : in  std_logic;  -- initialize the diff_decoder block
    sfd_detect_enable      : in  std_logic;  -- enable the sfd detection 
    -- Number of errors allowed.
    sfderr                 : in  std_logic_vector (2 downto 0);
    -- Number of pramble bits used for Start Frame Delimiter search.
    sfdlen                 : in  std_logic_vector (2 downto 0);
    -- Receive mode        : 0=BPSK, 1=QPSK, 2=CCK5.5, 3=CCK11.
    rec_mode               : in  std_logic_vector (1 downto 0);

    --------------------------------------------
    -- Remodulation interface
    --------------------------------------------
    remod_data             : in  std_logic_vector(1 downto 0);  -- Data from the TX path
    --
    remod_enable           : out std_logic;  -- High when the remodulation is enabled
    remod_data_req         : out std_logic;  -- request to send a byte 
    remod_type             : out std_logic;  -- CCK : 0 ; PBCC : 1
    remod_bq               : out std_logic;  -- BPSK = 0 - QPSK = 1 
    demod_data             : out std_logic_vector(7 downto 0);  -- Data to the TX path

    --------------------------------------------
    -- AGC-CCA interface
    --------------------------------------------
    correl_rst_n           : in  std_logic;  -- reset the Barker correlator when low
    synchro_en             : in  std_logic;  -- enable the synchronisation when high 
    --
    symbol_synchro         : out std_logic;  -- pulse at the beginning of a symbol.

    --------------------------------------------
    -- Modem B state machines interface
    --------------------------------------------
    sfd_found              : out std_logic;  -- sfd found when high
    preamble_type          : out std_logic;  -- Type of preamble 
    phy_data_ind           : out std_logic;  -- pulse when an RX byte is available.
    data_to_bup            : out std_logic_vector(7 downto 0); -- RX data.
    --------------------------------------------
    -- Status registers.
    --------------------------------------------
    iq_gain_sat_stat       : out std_logic_vector(6 downto 0);
    dc_offset_i_stat       : out std_logic_vector(5 downto 0);
    dc_offset_q_stat       : out std_logic_vector(5 downto 0);
    coeff_sum_i_stat       : out std_logic_vector(7 downto 0);
    coeff_sum_q_stat       : out std_logic_vector(7 downto 0);
    freqoffestim_stat      : out std_logic_vector(7 downto 0);
    -------------------------------
    -- Diag ports
    -------------------------------
    diag_error_i     : out std_logic_vector(data_length_g-2 downto 0); 
    diag_error_q     : out std_logic_vector(data_length_g-2 downto 0)
    
    );

end rx_path_core;
