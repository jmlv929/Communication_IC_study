
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: init_sync.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.15  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Init Sync Top Level Block - Include Preprocessing
-- and Postprocessing
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/init_sync/vhdl/rtl/init_sync.vhd,v  
--  Log: init_sync.vhd,v  
-- Revision 1.15  2004/12/20 08:57:10  Dr.C
-- #BugId:810#
-- Added ybnb port.
--
-- Revision 1.14  2004/12/14 17:18:55  Dr.C
-- #BugId:810#
-- Updated postprocessing port map.
--
-- Revision 1.13  2004/04/07 12:47:58  Dr.B
-- Changed generics type from boolean to integer.
--
-- Revision 1.12  2004/03/10 16:54:42  Dr.B
-- Updated GENERIC PORT of preprocessing:
--  - removed use_full_preprocessing_g.
--  - replaced by use_3correlators_g & use_autocorrelators_g..
--
-- Revision 1.11  2004/02/20 17:43:17  Dr.B
-- Updated preprocessing GENEIRC PORT with use_full_preprocessing_g.
--
-- Revision 1.10  2003/11/18 13:23:49  Dr.B
-- Updated port on carrier_detect: detthr_reg_i is 6 bits (was 4), new INPUT cs_accu_en.
--
-- Revision 1.9  2003/11/06 16:30:53  Dr.B
-- Updated ports on preprocessing and data_size_g (now 14) on carrier_detect.
--
-- Revision 1.8  2003/11/03 08:33:56  Dr.B
-- Added OUTPUT fast_99carrier_s_o to carrier_detect.vhd, used in 11g AGC procedure.
--
-- Revision 1.7  2003/10/15 09:51:46  Dr.C
-- Added yb_o.
--
-- Revision 1.6  2003/08/01 15:06:18  Dr.B
-- comments added.
--
-- Revision 1.5  2003/07/29 09:38:35  Dr.C
-- Added cp2_detected output
--
-- Revision 1.4  2003/06/25 17:14:18  Dr.B
-- new links between pre and post processing.
-- ..
--
-- Revision 1.3  2003/04/04 16:29:53  Dr.B
-- shift_param_gen added.
--
-- Revision 1.2  2003/03/31 08:36:20  Dr.B
-- read_enable = '1' removed.
--
-- Revision 1.1  2003/03/27 17:06:11  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--library preprocessing_rtl;
library work;
 
--library postprocessing_rtl;
library work;

--library init_sync_rtl;
library work;
--use init_sync_rtl.init_sync_pkg.all;
use work.init_sync_pkg.all;
--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity init_sync is
  generic (
    size_n_g        : integer := 11;
    size_rem_corr_g : integer := 4);  -- nb of bits removed for correlation calc
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                 : in  std_logic;
    reset_n             : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    sync_res_n          : in  std_logic;
    -- interface with dezfilter
    i_i                 : in  std_logic_vector (10 downto 0);
    q_i                 : in  std_logic_vector (10 downto 0);
    data_valid_i        : in  std_logic;
    autocorr_enable_i   : in  std_logic;  -- from AGC, enable autocorr calc when high
    -- Calculation parameters
    -- timing acquisition correction threshold parameters
    autothr0_i          : in  std_logic_vector (5 downto 0);
    autothr1_i          : in  std_logic_vector (5 downto 0);
    -- Treshold Accumulation for carrier sense  Register
    detthr_reg_i        : in  std_logic_vector (3 downto 0);
    -- interface with Mem (write port Read port + control)
    mem_o               : out std_logic_vector (2*(size_n_g-size_rem_corr_g+5-2)-1 downto 0);
    mem1_i              : in  std_logic_vector (2*(size_n_g-size_rem_corr_g+5-2)-1 downto 0);
    wr_ptr_o            : out std_logic_vector(6 downto 0);
    rd_ptr1_o           : out std_logic_vector(6 downto 0);
    write_enable_o      : out std_logic;
    read_enable_o       : out std_logic;
    -- coarse frequency correction increment
    cf_inc_o            : out std_logic_vector (23 downto 0);
    cf_inc_data_valid_o : out std_logic;
    -- Preamble Detected
    preamb_detect_o     : out std_logic; -- pulse
    cp2_detected_o      : out std_logic; -- remains high until next init
    -- Shift Paramater (for ffe scaling)
    shift_param_o       : out std_logic_vector(2 downto 0);
    -- Carrier Sense Detection
    fast_carrier_s_o    : out std_logic;
    carrier_s_o         : out std_logic;
    -- Internal signal for debug from postprocessing
    yb_o                : out std_logic_vector(3 downto 0);
    ybnb_o              : out std_logic_vector(6 downto 0)
    );

end init_sync;
