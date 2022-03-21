
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: buffer_for_seria.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.12   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Bufferize data arriving from tx_path
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/buffer_for_seria.vhd,v  
--  Log: buffer_for_seria.vhd,v  
-- Revision 1.12  2005/01/06 15:06:13  sbizet
-- #BugId:713#
-- Added txv_immstop enhancement to reset the FIFO
--
-- Revision 1.11  2003/12/03 17:25:49  Dr.B
-- remove last change because of the resynchro (no toggle when data is sent).
--
-- Revision 1.10  2003/12/01 10:01:44  Dr.B
-- change val when rd_ptr = 0.
--
-- Revision 1.9  2003/11/25 18:27:23  Dr.B
-- redebug rd_ptr incrementation.
--
-- Revision 1.8  2003/11/25 10:17:44  Dr.B
-- debug rd_ptr incrementation.
--
-- Revision 1.7  2003/11/21 17:51:47  Dr.B
-- add stream_enable_i.
--
-- Revision 1.6  2003/11/20 11:16:20  Dr.B
-- add buf_tog_o .
--
-- Revision 1.5  2003/11/17 14:31:32  Dr.B
-- add option to empty the fifo.
--
-- Revision 1.4  2003/10/09 08:20:02  Dr.B
-- debug toggle start.
--
-- Revision 1.3  2003/09/25 12:18:20  Dr.B
-- manage fifo content before starting.
--
-- Revision 1.2  2003/09/22 09:29:58  Dr.B
-- remove unused generics.
--
-- Revision 1.1  2003/07/21 09:53:08  Dr.B
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
entity buffer_for_seria is
  generic (
    buf_size_g      : integer := 2;    -- size of the buffer
    fifo_content_g  : integer := 2;    -- start seria only when fifo_content_g data in fifo
    empty_at_end_g  : integer := 0;    -- when 1, empty the fifo before ending
    in_size_g       : integer := 11);  -- size of data input of tx_filter B  
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    sampling_clk        : in  std_logic;
    reset_n             : in  std_logic;
    --------------------------------------
    -- Interface with muxed 60 MHz path
    --------------------------------------
    -- Data from Tx/Rx Filter
    data_i_i             : in  std_logic_vector(in_size_g-1 downto 0);
    data_q_i             : in  std_logic_vector(in_size_g-1 downto 0);
    data_val_tog_i       : in  std_logic;   -- high = data is valid
    --------------------------------------
    -- Control Signal
    --------------------------------------
    immstop_i           : in  std_logic;  -- Immediate stop request from BuP
    hiss_enable_n_i     : in  std_logic;  -- enable block
    path_enable_i       : in  std_logic;  --  when high data can be taken into account
    stream_enable_i     : in  std_logic;  --  when high, data stream is transfered.
    --------------------------------------
    -- Interface master_seria
    --------------------------------------
    next_d_req_tog_i    : in  std_logic; -- ask for a new data (last one is registered)
    --
    start_seria_o       : out std_logic;   -- high = data is valid
    buf_tog_o           : out std_logic;   -- toggle when buf change
    bufi_o              : out std_logic_vector(in_size_g-1 downto 0);
    bufq_o              : out std_logic_vector(in_size_g-1 downto 0)
  );

end buffer_for_seria;
