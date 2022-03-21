
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: fine_freq_estim.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.5  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Fine Frequency Estimation Top Level - Include State Machines
-- and Computation
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/fine_freq_estim/vhdl/rtl/fine_freq_estim.vhd,v  
--  Log: fine_freq_estim.vhd,v  
-- Revision 1.5  2003/10/15 08:53:06  Dr.C
-- Added ffest_state_o.
--
-- Revision 1.4  2003/05/20 17:13:28  Dr.B
-- unused inputs of sm removed.
--
-- Revision 1.3  2003/04/04 16:32:37  Dr.B
-- changes due to new version.
--
-- Revision 1.2  2003/04/01 11:50:24  Dr.B
-- rework state machines.
--
-- Revision 1.1  2003/03/27 17:45:46  Dr.B
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

--library fine_freq_estim_rtl;
library work;
--use fine_freq_estim_rtl.fine_freq_estim_pkg.all;
use work.fine_freq_estim_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity fine_freq_estim is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                           : in  std_logic;
    reset_n                       : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    sync_res_n                    : in  std_logic;
    -- Markers/data associated with ffe-inputs (i/q)
    start_of_burst_i              : in  std_logic;
    start_of_symbol_i             : in  std_logic;
    data_valid_i                  : in  std_logic;
    i_i                           : in  std_logic_vector(10 downto 0);
    q_i                           : in  std_logic_vector(10 downto 0);
    data_ready_o                  : out std_logic;
    -- control Mem Write/Read 
    read_enable_o                 : out std_logic;
    wr_ptr_o                      : out std_logic_vector(6 downto 0);
    write_enable_o                : out std_logic;
    rd_ptr_o                      : out std_logic_vector(6 downto 0);
    rd_ptr2_o                     : out std_logic_vector(6 downto 0);
    -- data interface with Mem
    mem1_i                        : in  std_logic_vector (21 downto 0);
    mem2_i                        : in  std_logic_vector (21 downto 0);
    mem_o                         : out std_logic_vector (21 downto 0);
    -- interface with t1t2premux
    data_ready_t1t2premux_i       : in  std_logic;
    i_t1t2_o                      : out std_logic_vector(10 downto 0);
    q_t1t2_o                      : out std_logic_vector(10 downto 0);
    data_valid_t1t2premux_o       : out std_logic;
    start_of_symbol_t1t2premux_o  : out std_logic;
    -- Shift Parameter from Init_Sync
    shift_param_i                 : in  std_logic_vector(2 downto 0);
    -- interface with tcombpremux
    data_ready_tcombpremux_i      : in  std_logic;
    i_tcomb_o                     : out std_logic_vector(10 downto 0);
    q_tcomb_o                     : out std_logic_vector(10 downto 0);
    data_valid_tcombpremux_o      : out std_logic;
    start_of_burst_tcombpremux_o  : out std_logic;
    start_of_symbol_tcombpremux_o : out std_logic;
    cf_freqcorr_o                 : out std_logic_vector(23 downto 0);
    data_valid_freqcorr_o         : out std_logic;
    -- Internal state for debug
    ffest_state_o                 : out std_logic_vector(2 downto 0)

    );

end fine_freq_estim;
