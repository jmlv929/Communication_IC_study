
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: sample_fifo_sm.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Sample Fifo State Machines -
-- 1st, wait for the frame_start_valid_i that indicates that a T1 has been
-- detected by the init_sync.
-- From the position of the T1 (frame_start_i), the number of data already
-- passed is calculated. Then the instant of the guard_interval can be calculated
-- (128 after T1).This instant is waited and then 16 data are ignored
-- (guard interval).Then the symbol is sent until a new guard interval.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/sample_fifo/vhdl/rtl/sample_fifo_sm.vhd,v  
--  Log: sample_fifo_sm.vhd,v  
-- Revision 1.2  2003/04/11 09:05:02  Dr.B
-- removed INITSYNC_DELAY_CT.
--
-- Revision 1.1  2003/03/27 17:14:44  Dr.B
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
entity sample_fifo_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                 : in  std_logic;  -- Clock input
    reset_n             : in  std_logic;  -- Asynchronous negative reset
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i              : in  std_logic;  -- not sync_res_n
    data_valid_i        : in  std_logic;  -- 1: Input data is valid
    timoffst_i          : in std_logic_vector(2 downto 0);
    frame_start_valid_i : in  std_logic;  -- 1: The frame_start signal is valid.
    start_rd_o          : out std_logic;  -- signal to start to read the memory
                                          -- the write pointer valid at thestart read
    data_valid_o        : out std_logic
  );

end sample_fifo_sm;
