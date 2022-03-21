
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: t1t2_preamble_mux.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.3  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : T1T2 Preamble Multiplexer.
--               The main target of the T1T2 Preamble Multiplexer is to let the
--               long preamble (T1T2) from the Sample FIFO through and then 
--               halts the data coming from the Sample FIFO.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/t1t2_preamble_mux/vhdl/rtl/t1t2_preamble_mux.vhd,v  
--  Log: t1t2_preamble_mux.vhd,v  
-- Revision 1.3  2003/12/12 17:10:34  Dr.B
-- reset counter when sync_reset_n
--
-- Revision 1.2  2003/04/14 14:59:49  Dr.B
-- new architecture.
--
-- Revision 1.1  2003/03/27 09:01:08  Dr.C
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


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity t1t2_preamble_mux is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                           : in  std_logic;
    reset_n                       : in  std_logic;
    sync_reset_n                  : in  std_logic;
    --------------------------------------
    -- Control signal
    --------------------------------------
    -- From sample fifo
    i_i                           : in  std_logic_vector(10 downto 0);
    q_i                           : in  std_logic_vector(10 downto 0);
    data_valid_i                  : in  std_logic;
    start_of_burst_i              : in  std_logic;  
    start_of_symbol_samplefifo_i  : in  std_logic;
    -- To sample fifo
    data_ready_o                  : out std_logic;
    -- From fine freq. estimator
    i_finefreqest_i               : in  std_logic_vector(10 downto 0);
    q_finefreqest_i               : in  std_logic_vector(10 downto 0);
    start_of_symbol_finefreqest_i : in  std_logic;  
    finefreqest_valid_i           : in  std_logic;
    -- To fine freq. estimator
    finefreqest_ready_o           : out std_logic;
    -- From or_freqcorr
    data_ready_i                  : in  std_logic;
    -- To or_freqcorr
    i_o                           : out std_logic_vector(10 downto 0);
    q_o                           : out std_logic_vector(10 downto 0);
    data_valid_o                  : out std_logic;
    start_of_burst_o              : out std_logic;
    start_of_symbol_o             : out std_logic
    
  );

end t1t2_preamble_mux;
