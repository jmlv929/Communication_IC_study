
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: output_modes.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Output Modes Block. Register the output + generate the control
-- signals according to the received symbols (T1/ T2/ or  symbol)
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/sample_fifo/vhdl/rtl/output_modes.vhd,v  
--  Log: output_modes.vhd,v  
-- Revision 1.2  2003/04/11 09:01:32  Dr.B
-- big changes on sm + control signals gen.
--
-- Revision 1.1  2003/03/27 17:14:58  Dr.B
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
entity output_modes is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk               : in  std_logic;  -- Clock input
    reset_n           : in  std_logic;  -- Asynchronous negative reset
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i            : in  std_logic;  -- 0: The control state of the module will be reset
    i_i               : in  std_logic_vector(10 downto 0);  -- I input data
    q_i               : in  std_logic_vector(10 downto 0);  -- Q input data
    data_valid_i      : in  std_logic;  -- 1: Input data is valid
    data_ready_i      : in  std_logic;  -- 0: Do not output more data
    --
    i_o               : out std_logic_vector(10 downto 0);  -- I output data
    q_o               : out std_logic_vector(10 downto 0);  -- Q output data
    data_ready_o      : out std_logic;
    data_valid_o      : out std_logic;  -- 1: Output data is valid
    start_of_burst_o  : out std_logic;  -- 1: The next valid data output belongs to the next burst
    start_of_symbol_o : out std_logic  -- 1: The next valid data output belongs to the next symbol    
  );

end output_modes;
