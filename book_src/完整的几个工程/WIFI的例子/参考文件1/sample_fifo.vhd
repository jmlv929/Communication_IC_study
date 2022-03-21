
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: sample_fifo.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Sample Fifo Top Level - Instantiate sm, ring_buffer and 
-- output modes sm.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/sample_fifo/vhdl/rtl/sample_fifo.vhd,v  
--  Log: sample_fifo.vhd,v  
-- Revision 1.2  2003/05/15 13:09:17  Dr.B
-- adapt FIFO_DEPTH.
--
-- Revision 1.1  2003/03/27 17:14:49  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_arith.all;

--library sample_fifo_rtl;
library work;
--use sample_fifo_rtl.sample_fifo_pkg.all;
use work.sample_fifo_pkg.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity sample_fifo is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                 : in std_logic;  -- Clock input
    reset_n             : in std_logic;  -- Asynchronous negative reset
    --------------------------------------
    -- Signals
    --------------------------------------
    sync_res_n          : in std_logic;  -- 0: The control state of the module will be reset
    i_i                 : in std_logic_vector(10 downto 0);  -- I input data
    q_i                 : in std_logic_vector(10 downto 0);  -- Q input data
    data_valid_i        : in std_logic;  -- 1: Input data is valid
    timoffst_i          : in std_logic_vector(2 downto 0);
    frame_start_valid_i : in std_logic;  -- 1: The frame_start signal is valid.
    data_ready_i        : in std_logic;  -- 0: Do not output more data
    --
    i_o                 : out std_logic_vector(10 downto 0);  -- I output data
    q_o                 : out std_logic_vector(10 downto 0);  -- Q output data
    data_valid_o        : out std_logic;  -- 1: Output data is valid
    start_of_burst_o    : out std_logic;  -- 1: The next valid data output belongs to the next burst
    start_of_symbol_o   : out std_logic  -- 1: The next valid data output belongs to the next symbol
    );

end sample_fifo;
