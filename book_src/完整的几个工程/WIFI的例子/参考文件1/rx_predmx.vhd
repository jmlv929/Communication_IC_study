
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: rx_predmx.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.10   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Preamble demultiplexer. It serialy sends the first symbol
-- to the Wiener filter (on start_of_burst_i pulse), then sends the following
-- data to the equalizer (on each start_of_symbol_i pulse).
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/rx_predmx/vhdl/rtl/rx_predmx.vhd,v  
--  Log: rx_predmx.vhd,v  
-- Revision 1.10  2005/03/11 10:11:12  Dr.C
-- #BugId:1130#
-- Added start of symbol pulse for pilot tracking during signal symbol to start earlier the estimation.
--
-- Revision 1.9  2003/05/12 13:44:42  Dr.F
-- changed dmx_equ_enable.
--
-- Revision 1.8  2003/04/29 13:52:37  Dr.F
-- changed sampling of output data.
--
-- Revision 1.7  2003/04/24 06:57:26  Dr.F
-- cleaned sensitivity list.
--
-- Revision 1.6  2003/04/24 06:14:13  Dr.F
-- added start_of_symbol for pilot tracking.
--
-- Revision 1.5  2003/04/04 07:49:13  Dr.F
-- debuged data_ready_o.
--
-- Revision 1.4  2003/03/28 15:40:56  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.3  2003/03/25 07:44:02  Dr.F
-- replaced test on data_valid_i by test on sample_count value.
--
-- Revision 1.2  2003/03/24 14:33:11  Dr.F
-- removed chfifo interface.
--
-- Revision 1.1  2003/03/17 15:30:20  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library rx_predmx_rtl;
library work;
--use rx_predmx_rtl.rx_predmx_pkg.all;
use work.rx_predmx_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity rx_predmx is

  port (
    clk                      : in  std_logic;  -- ofdm clock (80 MHz)
    reset_n                  : in  std_logic;  -- asynchronous negative reset
    sync_reset_n             : in  std_logic;  -- synchronous negative reset
    i_i                      : in  FFT_ARRAY_T;  -- I input data
    q_i                      : in  FFT_ARRAY_T;  -- Q input data
    data_valid_i             : in  std_logic;  -- '1': input data valid
    wie_data_ready_i         : in  std_logic;  -- '0': do not output more data (from Wiener filter)
    equ_data_ready_i         : in  std_logic;  -- '0': do not output more data (from equalizer)
    start_of_burst_i         : in  std_logic;  -- '1': the next valid data input belongs to
                                               -- the next burst
    start_of_symbol_i        : in  std_logic;  -- '1': the next valid data input belongs to
                                               -- the next symbol
    data_ready_o             : out std_logic;  -- '0': do not input more data
    i_o                      : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);  -- I output data
    q_o                      : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);  -- Q output data
    wie_data_valid_o         : out std_logic;  -- '1': output data valid for the Wiener filter
    equ_data_valid_o         : out std_logic;  -- '1': output data valid for the equalizer
    pilot_valid_o            : out std_logic;  -- '1': output pilot valid
    inv_matrix_done_i        : in  std_logic;  -- '1': pilot tracking matrix inverted
    wie_start_of_burst_o     : out std_logic;  -- '1': the next valid data output belongs to the next
                                               -- burst (for Wiener filter)
    wie_start_of_symbol_o    : out std_logic;  -- '1': the next valid data output belongs to the next
                                               -- symbol (for Wiener filter) 
    equ_start_of_burst_o     : out std_logic;  -- '1': the next valid data output belongs to the next
                                               -- burst (for equalizer and chfifo, it's the same signal)
    equ_start_of_symbol_o    : out std_logic;  -- '1': the next valid data output belongs to the next
                                               -- symbol (for equalizer)
    plt_track_start_of_symbol_o : out std_logic   -- '1': the next valid data output belongs to the next
                                               -- symbol (for pilot tracking)
    );

end rx_predmx;
