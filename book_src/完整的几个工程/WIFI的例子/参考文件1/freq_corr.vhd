
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: freq_corr.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.7  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Frequency correction
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/freq_corr/vhdl/rtl/freq_corr.vhd,v  
--  Log: freq_corr.vhd,v  
-- Revision 1.7  2004/12/20 08:54:21  Dr.C
-- #BugId:910#
-- Reduce freq_off_est to 20-bit.
--
-- Revision 1.6  2004/12/14 16:54:53  Dr.C
-- #BugId:810#
-- Added freq_corr_sum output for debug (link to register).
--
-- Revision 1.5  2003/09/05 08:19:58  Dr.B
-- empty the shift registers on sync_reset_n = '0'.
--
-- Revision 1.4  2003/08/07 16:19:15  Dr.C
-- Replaced LUT with a cordic
--
-- Revision 1.3  2003/04/11 08:56:44  Dr.C
-- Removed sample_cnt and replaced it with start_of_symbol
-- Debugged phase generation
--
-- Revision 1.2  2003/04/04 16:43:48  Dr.C
-- Removed fine_freq_data_ready_o and added fine_freq_update
--
-- Revision 1.1  2003/03/27 14:45:06  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--library cordic_rtl;
library work;

--library freq_corr_rtl;
library work;
--use freq_corr_rtl.freq_corr_pkg.all;
use work.freq_corr_pkg.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity freq_corr is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk          : in std_logic;
    reset_n      : in std_logic;
    sync_reset_n : in std_logic;

    --------------------------------------
    -- I & Q
    --------------------------------------
    i_i : in  std_logic_vector(10 downto 0);
    q_i : in  std_logic_vector(10 downto 0);
    i_o : out std_logic_vector(10 downto 0);
    q_o : out std_logic_vector(10 downto 0);

    --------------------------------------
    -- Data control
    --------------------------------------
    data_valid_i            : in  std_logic;  -- Input data is valid
    data_ready_i            : in  std_logic;
    start_of_burst_i        : in  std_logic;  -- New burst starts 
    start_of_symbol_i       : in  std_logic;  -- Next data belongs to next symb.
    t1t2premux_data_ready_o : out std_logic;  -- Indicates to T1T2premux whether
                                         -- to fetch data from sample FIFO or not
    data_valid_o            : out std_logic;  -- Output data is valid
    start_of_burst_o        : out std_logic;  -- Start of burst for T1T2 demux
    start_of_symbol_o       : out std_logic;  -- Start of symbol for T1T2 demux

    --------------------------------------
    -- Frequency
    --------------------------------------
    coarsefreq_i        : in std_logic_vector(23 downto 0);  -- Coarse
                                                          -- frequency estimate
    coarsefreq_valid_i  : in std_logic;
    finefreq_i          : in std_logic_vector(23 downto 0);  -- Fine frequency
                                                             --  estimate
    finefreq_valid_i    : in std_logic;  -- Fine frequency input valid
 
    --------------------------------------
    -- Debug
    --------------------------------------
    freq_off_est        : out std_logic_vector(19 downto 0) -- coarse + fine
    );

end freq_corr;
