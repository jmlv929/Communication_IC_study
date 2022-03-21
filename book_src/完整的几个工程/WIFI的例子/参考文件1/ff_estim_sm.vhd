
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: ff_estim_sm.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.7  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : State Machines of the fine frequency estimation block
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/fine_freq_estim/vhdl/rtl/ff_estim_sm.vhd,v  
--  Log: ff_estim_sm.vhd,v  
-- Revision 1.7  2003/10/15 08:52:12  Dr.C
-- Added ffest_state_o for debug.
--
-- Revision 1.6  2003/05/20 17:14:11  Dr.B
-- i_i/q_i unused removed.
--
-- Revision 1.5  2003/04/18 08:43:48  Dr.B
-- bug on rd_ptr corrected.
--
-- Revision 1.4  2003/04/14 14:48:57  Dr.B
-- changes or rd_ptr2 (now reach 80).
--
-- Revision 1.3  2003/04/04 16:31:30  Dr.B
-- NEW STATES MACHINES.
--
-- Revision 1.2  2003/04/01 11:50:07  Dr.B
-- rework state machine .
--
-- Revision 1.1  2003/03/27 17:45:34  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity ff_estim_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                           : in  std_logic;
    reset_n                       : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i                        : in  std_logic;
    -- Interface with T1T2_demux
    start_of_burst_i              : in  std_logic;
    start_of_symbol_i             : in  std_logic;
    data_valid_i                  : in  std_logic;
    data_ready_o                  : out std_logic;
    -- control Mem Write/Read 
    read_enable_o                 : out std_logic;
    wr_ptr_o                      : out std_logic_vector(6 downto 0);
    write_enable_o                : out std_logic;
    rd_ptr_o                      : out std_logic_vector(5 downto 0);
    rd_ptr2_o                     : out std_logic_vector(6 downto 0);
    -- start_of_symbol and start_of_burst for cf computation
    start_of_burst_cf_compute_o   : out std_logic;
    start_of_symbol_cf_compute_o  : out std_logic;
    -- valid data for cf/tcomb computation
    data_valid_for_cf_o           : out std_logic;
    last_data_o                   : out std_logic; -- accu is finished => calc cf
    -- cf inc valid & ready (for cf_inc computation)
    data_valid_freqcorr_i         : in  std_logic;
    -- data from Mem (port 2) will feed t1t2premux (storage of t1t2coarse)
    i_mem2_i                      : in  std_logic_vector(10 downto 0);
    q_mem2_i                      : in  std_logic_vector(10 downto 0);
    -- data from tcomb-compute will feed tcombpremux (tcomb from t1t2fine)
    i_tcomb_i                     : in  std_logic_vector(10 downto 0);
    q_tcomb_i                     : in  std_logic_vector(10 downto 0);
    -- interface with t1t2premux
    data_ready_t1t2premux_i       : in  std_logic;
    i_t1t2_o                      : out std_logic_vector(10 downto 0);
    q_t1t2_o                      : out std_logic_vector(10 downto 0);
    data_valid_t1t2premux_o       : out std_logic;
    start_of_symbol_t1t2premux_o  : out std_logic;
    -- interface with tcombpremux
    data_ready_tcombpremux_i      : in  std_logic;
    i_tcomb_o                     : out std_logic_vector(10 downto 0);
    q_tcomb_o                     : out std_logic_vector(10 downto 0);
    data_valid_tcombpremux_o      : out std_logic;
    start_of_burst_tcombpremux_o  : out std_logic;
    start_of_symbol_tcombpremux_o : out std_logic;
    -- Internal state for debug
    ffest_state_o                 : out std_logic_vector(2 downto 0)

    );

end ff_estim_sm;
