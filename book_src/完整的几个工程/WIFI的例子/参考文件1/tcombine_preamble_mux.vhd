
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: tcombine_preamble_mux.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Tcombine Preamble Multiplexer
--               The Tcombine Preamble Multiplexer is used to combine the Tcomb
--               symbol ((T1+T2)/2) from the Fine Frequency Estimator with the
--               rest of the frame coming from the T1T2 Demultiplexer (Freq Corr).
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/tcombine_preamble_mux/vhdl/rtl/tcombine_preamble_mux.vhd,v  
--  Log: tcombine_preamble_mux.vhd,v  
-- Revision 1.2  2003/04/11 09:07:55  Dr.B
-- new tcomb architecture.
--
-- Revision 1.1  2003/03/27 09:04:45  Dr.C
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
entity tcombine_preamble_mux is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk               : in  std_logic;
    reset_n           : in  std_logic;
    sync_reset_n      : in  std_logic;
    --------------------------------------
    -- Controls
    --------------------------------------
    start_of_burst_i  : in  std_logic;
    start_of_symbol_i : in  std_logic;
    data_ready_i      : in  std_logic;
    -- Data from T1T2_Demux
    i_i               : in  std_logic_vector(10 downto 0);
    q_i               : in  std_logic_vector(10 downto 0);
    data_valid_i      : in  std_logic;
    -- Data from Fine Freq Estim
    i_tcomb_i         : in  std_logic_vector(10 downto 0);
    q_tcomb_i         : in  std_logic_vector(10 downto 0);
    tcomb_valid_i     : in  std_logic;
    --
    start_of_burst_o  : out std_logic;
    start_of_symbol_o : out std_logic;
    data_ready_o      : out std_logic;
    tcomb_ready_o     : out std_logic;
    i_o               : out std_logic_vector(10 downto 0);
    q_o               : out std_logic_vector(10 downto 0);
    data_valid_o      : out std_logic
  );

end tcombine_preamble_mux;
