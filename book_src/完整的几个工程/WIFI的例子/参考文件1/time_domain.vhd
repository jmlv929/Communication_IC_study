
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: time_domain.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.18  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Time Domain Top : Instantiation of the subblocks
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/time_domain/vhdl/rtl/time_domain.vhd,v  
--  Log: time_domain.vhd,v  
-- Revision 1.18  2005/02/23 17:18:49  Dr.C
-- #BugId:810#
-- Removed carrier_s from diag port.
--
-- Revision 1.17  2004/12/20 09:06:49  Dr.C
-- #BugId:810#
-- Updated instance port map.
--
-- Revision 1.16  2004/12/14 17:44:07  Dr.C
-- #BugId:810#
-- Updated debug port.
--
-- Revision 1.15  2003/10/16 13:36:49  Dr.C
-- Updated diag port order.
--
-- Revision 1.14  2003/10/16 13:33:54  Dr.C
-- Changed diag.
--
-- Revision 1.13  2003/10/15 16:11:30  Dr.C
-- Added diag port.
--
-- Revision 1.12  2003/07/29 10:27:25  Dr.C
-- Added cp2_detected output.
--
-- Revision 1.11  2003/07/22 15:42:24  Dr.C
-- Removed 60Mhz clock port.
--
-- Revision 1.10  2003/06/30 12:02:02  Dr.B
-- remove unused detthr_reg signal.
--
-- Revision 1.9  2003/06/30 09:45:35  arisse
-- Added input register : detect_thr_carrier.
--
-- Revision 1.8  2003/06/27 16:09:56  Dr.B
-- temporary detthr_reg set to 0.
--
-- Revision 1.7  2003/06/27 09:10:51  Dr.C
-- Removed target_supplier generic on shared_fifo_mem
--
-- Revision 1.6  2003/06/25 17:17:09  Dr.B
-- change init_sync port map.
--
-- Revision 1.5  2003/04/30 09:13:29  Dr.A
-- IQ compensation and RX filter interface moved to top of Modem.
--
-- Revision 1.4  2003/04/11 09:09:45  Dr.B
-- fifo_mem rd_ptr 1 -> 2.
--
-- Revision 1.3  2003/04/04 16:39:25  Dr.B
-- shift_param added + freq_corr_data_ready removed.
--
-- Revision 1.2  2003/04/01 11:52:02  Dr.B
-- unused signals removed.
--
-- Revision 1.1  2003/03/27 18:28:07  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

 
--library fine_freq_estim_rtl;
library work;
--library init_sync_rtl;
library work;
--library sample_fifo_rtl;
library work;
--library t1t2_demux_rtl;
library work;
--library t1t2_preamble_mux_rtl;
library work;
--library tcombine_preamble_mux_rtl;
library work;
--library freq_corr_rtl;
library work;
--library shared_fifo_mem_rtl;
library work;

--library time_domain_rtl;
library work;
--use time_domain_rtl.time_domain_pkg.all;
use work.time_domain_pkg.all;
--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity time_domain is
  port (
    ---------------------------------------
    -- Clocks & Reset
    ---------------------------------------
    clk                         : in  std_logic; -- 80 MHz clk
    reset_n                     : in  std_logic;
    -- Enable and synchronous reset
    sync_reset_n                : in  std_logic;  -- Init 

    ---------------------------------------
    -- Parameters from registers
    ---------------------------------------
    -- InitSync Registers
    detect_thr_carrier_i        : in  std_logic_vector(3 downto 0);
    initsync_autothr0_i         : in  std_logic_vector (5 downto 0);
    initsync_autothr1_i         : in  std_logic_vector (5 downto 0);
    -- Samplefifo Registers
    sampfifo_timoffst_i         : in  std_logic_vector (2 downto 0);

    ---------------------------------------
    -- Parameters to registers
    ---------------------------------------
    -- Frequency correction
    freq_off_est_o              : out std_logic_vector(19 downto 0);
    -- Preprocessing sample number before sync
    ybnb_o                      : out std_logic_vector(6 downto 0);

    ---------------------------------------
    -- Controls
    ---------------------------------------
    -- To FFT
    data_ready_i                : in  std_logic;
    start_of_symbol_o           : out std_logic;
    data_valid_o                : out std_logic;
    start_of_burst_o            : out std_logic;
    -- to global state machine
    preamb_detect_o             : out std_logic;
    -- to DC offset
    cp2_detected_o              : out std_logic;   

    ---------------------------------------
    -- I&Q Data
    ---------------------------------------
    -- Input data after IQ compensation.
    iqcomp_data_valid_i         : in  std_logic; -- High when data is valid.
    i_iqcomp_i                  : in  std_logic_vector(10 downto 0);
    q_iqcomp_i                  : in  std_logic_vector(10 downto 0);
    --
    i_o                         : out std_logic_vector(10 downto 0);
    q_o                         : out std_logic_vector(10 downto 0);
    
    ---------------------------------------
    -- Diag. port
    ---------------------------------------
    time_domain_diag0           : out std_logic_vector(15 downto 0);
    time_domain_diag1           : out std_logic_vector(11 downto 0);
    time_domain_diag2           : out std_logic_vector(5 downto 0)
    );

end time_domain;
