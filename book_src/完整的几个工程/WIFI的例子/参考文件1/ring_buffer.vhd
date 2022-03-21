
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: ring_buffer.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.4  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Ring Buffer - Manage Wr and Rd Pointer according to
-- data_valid_i (new data to write) and data_read_i (new data to read).
-- When start_rd = '1', move rd pointer on the T1 data (back to rd_wr_diff from
-- the wr_ptr) => the read has started
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/sample_fifo/vhdl/rtl/ring_buffer.vhd,v  
--  Log: ring_buffer.vhd,v  
-- Revision 1.4  2004/03/03 13:52:23  Dr.B
-- change for formal verif.
--
-- Revision 1.3  2004/02/20 14:06:56  Dr.B
-- change rd_wr_diff range.
--
-- Revision 1.2  2003/04/11 09:04:02  Dr.B
-- changed data_valid gen.
--
-- Revision 1.1  2003/03/27 17:14:53  Dr.B
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
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity ring_buffer is
  generic (
    fifo_width_g : integer;
    fifo_depth_g : integer
    );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk          : in  std_logic;       -- Module clock
    reset_n      : in  std_logic;       -- asynchronous reset
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i       : in  std_logic;       -- synchronous reset
    data_valid_i : in  std_logic;       -- new data to write
    data_ready_i : in  std_logic;       -- new data to read
    start_rd_i   : in  std_logic;       -- signal to start to read the memory
    rd_wr_diff   : in  std_logic_vector(2 downto 0);  -- difference between read pointer
                   -- and the write pointer valid at the start read
    data_i       : in  std_logic_vector(fifo_width_g - 1 downto 0);  -- data to wr
    --
    data_valid_o : out std_logic;       -- read data is available
    data_o       : out std_logic_vector(fifo_width_g - 1 downto 0)  -- read data 
    );

end ring_buffer;
