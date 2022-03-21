
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : ModemA 2
--    ,' GoodLuck ,'      RCSfile: preprocessing.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.19   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
---------------------------------------------------------------------------------
-- Description : Preprocessing during preamble section
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/preprocessing/vhdl/rtl/preprocessing.vhd,v  
--  Log: preprocessing.vhd,v  
-- Revision 1.19  2004/12/20 09:02:58  Dr.C
-- #BugId:810#
-- Added ybnb port.
--
-- Revision 1.18  2004/04/08 13:38:39  Dr.B
-- Debug OUTPUT generic linking for autocorrelator.
--
-- Revision 1.17  2004/04/07 12:41:33  Dr.B
-- Changed type of generics from boolean to integer for synopsys.
--
-- Revision 1.16  2004/03/10 16:37:50  Dr.B
-- Removed use_full_preprocessing_g generic.
-- Replaced by: use_3correlators_g & use_autocorrelators_g for
-- conditional generation of these 2 sub-parts.
--
-- Revision 1.15  2004/02/20 17:15:50  Dr.B
-- Added GENERATE statements to provide conditional compilation.
-- Since some parts are not used in MODEM G AGC, they are not generated.
-- Added use_full_preprocessing_g on GENERIC PORT for this purpose.
--
-- Revision 1.14  2004/01/14 17:42:35  Dr.C
-- Debugged saturation on a16m and changed code to make the block hold at0 and at1 if disabled
--
-- Revision 1.13  2003/12/20 09:06:04  Dr.B
-- init accu when autocorrelator disb.
--
-- Revision 1.12  2003/11/21 16:34:36  Dr.B
-- Auto-correlation (a_data_valid) begins with th 17th sample (was 16).
--
-- Revision 1.11  2003/11/21 13:22:51  Dr.B
-- Changed value for samples clocked by mag_reg: 16 (was 17) and 32 (was 33).
--
-- Revision 1.10  2003/11/19 15:11:04  Dr.B
-- Add () for synthesis.
--
-- Revision 1.9  2003/11/07 11:31:53  Dr.B
-- Debug sub_offset fct.
--
-- Revision 1.8  2003/11/07 10:24:34  Dr.B
-- Debug sub_offset.
--
-- Revision 1.7  2003/11/07 10:04:50  Dr.B
-- Debug...
--
-- Revision 1.6  2003/11/07 09:58:12  Dr.B
-- Debug sub_offset fct.
--
-- Revision 1.5  2003/11/07 09:36:25  Dr.B
-- Debug sum_a16_i & q.
--
-- Revision 1.4  2003/11/06 16:34:26  Dr.B
-- Added dc_offset_4_corr port and prcessing, resized/redesigned some datapath structure.
--
-- Revision 1.3  2003/06/25 17:04:47  Dr.B
-- update the autocorrelation chain.
--
-- Revision 1.2  2003/03/31 11:49:51  Dr.B
-- yr_reg remove on seq process.
--
-- Revision 1.1  2003/03/27 16:34:53  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;

--library preprocessing_rtl;
library work;
--use preprocessing_rtl.preprocessing_pkg.all;
use work.preprocessing_pkg.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity preprocessing is
  generic (
    size_n_g                  : integer := 11;
    size_rem_corr_g           : integer := 4;    -- nb of bits removed for correlation calc
--    use_3correlators_g        : integer range 0 to 1:= 1; -- When 1 the "3" correlators are generated.
    use_3correlators_g        : integer range 0 to 1:= 1; -- When 1 the "3" correlators are generated.
--    use_autocorrelators_g     : integer range 0 to 1:= 1  -- When 1 the auto-correlators are generated.
    use_autocorrelators_g     : integer range 0 to 1:= 1  -- When 1 the auto-correlators are generated.
    );                                          
    
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                    : in std_logic;
    reset_n                : in std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i                 : in std_logic;
    -- Data Input
    i_i                    : in std_logic_vector (10 downto 0);
    q_i                    : in std_logic_vector (10 downto 0);
    data_valid_i           : in std_logic;
    dc_offset_4_corr_i_i   : in std_logic_vector (11 downto 0);-- NEW (rev 1.4)
    dc_offset_4_corr_q_i   : in std_logic_vector (11 downto 0);-- NEW (rev 1.4)
    autocorr_enable_i      : in std_logic; -- from AGC, enable autocorr calc when high
    -- *** CALCULATION PARAMETERS *** 
    -- autocorrelation threshold (from register)
    autothr0_i             : in std_logic_vector (5 downto 0);
    autothr1_i             : in std_logic_vector (5 downto 0);
    -- *** Interface with Mem (write port + control) ***
    mem_o                  : out std_logic_vector (2*(size_n_g-size_rem_corr_g+5-2)-1 downto 0);
    wr_ptr_o               : out std_logic_vector(6 downto 0);
    write_enable_o         : out std_logic;
    -- XB (from B-correlator)
    xb_re_o                : out std_logic_vector (size_n_g-size_rem_corr_g+5-1-2 downto 0);
    xb_im_o                : out std_logic_vector (size_n_g-size_rem_corr_g+5-1-2 downto 0);
    xb_data_valid_o        : out std_logic;
    -- XC1 (from CP1-correlator)
    xc1_re_o               : out std_logic_vector (size_n_g-size_rem_corr_g+5-1-2 downto 0);
    xc1_im_o               : out std_logic_vector (size_n_g-size_rem_corr_g+5-1-2 downto 0);
    -- AT threshold 
    at0_o                  : out std_logic_vector (13 downto 0);-- NEW (rev 1.4): was (12 downto 0)! 
    at1_o                  : out std_logic_vector (13 downto 0);-- NEW (rev 1.4): was (12 downto 0)!
    -- Y data (from CP1/CP2-correlator)
    yc1_o                  : out std_logic_vector (size_n_g-size_rem_corr_g+5-2-1 downto 0);
    yc2_o                  : out std_logic_vector (size_n_g-size_rem_corr_g+5-2-1 downto 0);
    -- Auto-correlation outputs
    a16_m_o                : out std_logic_vector (13 downto 0);-- NEW (rev 1.4): was (12 downto 0)!
    a16_data_valid_o       : out std_logic;
    -- Stat register
    ybnb_o                 : out std_logic_vector(6 downto 0)
    );
    
    
end preprocessing;
