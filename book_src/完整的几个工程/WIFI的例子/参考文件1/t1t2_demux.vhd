
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: t1t2_demux.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.8  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : T1T2 Demultiplexer
--               This block directs the long preamble (T1 and T2) symbols to the
--               fine frequency estimation block, to calculate the frequency
--               correction required, and to TCombine_preamble_mux for further
--               processing.
--               data_ready, which has a long path, is registered. A data
--               buffer is needed to take into account the delay inserted.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/t1t2_demux/vhdl/rtl/t1t2_demux.vhd,v  
--  Log: t1t2_demux.vhd,v  
-- Revision 1.8  2004/01/12 15:31:24  Dr.B
-- complete sensitivity list.
--
-- Revision 1.7  2003/04/11 14:33:42  Dr.B
-- add symbol_i_memo on sm transition long_preamble -> rest_of_data.
--
-- Revision 1.6  2003/04/11 13:04:02  Dr.B
-- added memorization of start_of_symbol_i when data_ready 1 ->0.
--
-- Revision 1.5  2003/04/11 09:06:08  Dr.B
-- changes for start_of_symbol gen.
--
-- Revision 1.4  2003/04/03 15:16:17  Dr.B
-- register input data only when data_valid_i = '1'.
--
-- Revision 1.3  2003/04/01 13:54:52  Dr.B
-- memorize data when data_ready => '0'.
--
-- Revision 1.2  2003/03/28 12:53:21  Dr.B
-- bug on data_valid generation corrected.
--
-- Revision 1.1  2003/03/27 17:18:05  Dr.B
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
entity t1t2_demux is
  generic (
    data_size_g : integer := 11);       -- size of data (i_i/q_i/i_o/q_i)
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                        : in  std_logic;  -- clock (80 MHz)
    reset_n                    : in  std_logic;  -- asynchronous negative reset
    sync_reset_n               : in  std_logic;  -- synchronous negative reset
    --------------------------------------
    -- Controls
    --------------------------------------
    i_i                        : in  std_logic_vector(data_size_g-1 downto 0);
    q_i                        : in  std_logic_vector(data_size_g-1 downto 0);
    data_valid_i               : in  std_logic;  -- input data valid
    start_of_burst_i           : in  std_logic;  -- next valid data input belongs to the next burst
    start_of_symbol_i          : in  std_logic;  -- next valid data input belongs to the next symbol
    ffe_data_ready_i           : in  std_logic;  -- 0 do not output more data (from ffe)  
    tcombmux_data_ready_i      : in  std_logic;  -- 0 do not output more data (from tcombmux)
    --
    data_ready_o               : out std_logic;  -- do not input more data    
    ffe_start_of_burst_o       : out std_logic;  -- next valid data output belongs to the next burst (for ffe)   
    ffe_start_of_symbol_o      : out std_logic;  -- next valid data output belongs to the next symbol (for ffe)   
    ffe_data_valid_o           : out std_logic;  -- output data valid for the ffe   
    tcombmux_data_valid_o      : out std_logic;  -- output data valid for the tcombmux   
    tcombmux_start_of_symbol_o : out std_logic;  -- next valid data output belongs to the next symbol (for tcomb mux)
    i_o                        : out std_logic_vector(data_size_g-1 downto 0);
    q_o                        : out std_logic_vector(data_size_g-1 downto 0)


  );

end t1t2_demux;
