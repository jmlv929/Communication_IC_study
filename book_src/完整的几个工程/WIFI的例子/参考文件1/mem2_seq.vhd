
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLDBuP2
--    ,' GoodLuck ,'      RCSfile: mem2_seq.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.9  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Memory sequencer
--               Its tasks are 
--                  * to provide the byte for transmission to the
--                      serializer for the intern memory.
--                  * to store the received byte in the memory
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/mem2_seq/vhdl/rtl/mem2_seq.vhd,v  
--  Log: mem2_seq.vhd,v  
-- Revision 1.9  2005/10/04 12:13:09  Dr.A
-- #BugId:1288#
-- removed unused signal
--
-- Revision 1.8  2005/05/31 15:51:20  Dr.A
-- #BugId:938#
-- Removed unused signals
--
-- Revision 1.7  2005/03/01 10:06:57  Dr.A
-- #BugId:1087#
-- Chnaged last_word generation.
--
-- Revision 1.6  2005/02/09 17:54:03  Dr.A
-- #BugId:974#
-- Reset_bufempty sent on RX write access
--
-- Revision 1.5  2004/04/14 16:06:07  Dr.A
-- Removed unused signal last_word_size.
--
-- Revision 1.4  2004/02/04 08:09:15  Dr.F
-- code cleaning.
--
-- Revision 1.3  2004/01/29 14:30:57  Dr.F
-- Because of Ambit internal error, I have reduced the offset length and added EXT function for additions with offset.
--
-- Revision 1.2  2004/01/26 08:50:17  Dr.F
-- added ready_load.
--
-- Revision 1.1  2003/11/19 16:27:33  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Taken from revision 1.11 of mem_seq :
--
-- Revision 1.11  2002/12/17 12:45:03  Dr.C
-- Debugged reception of less than 4 bytes
--
-- Revision 1.10  2002/12/09 09:53:41  Dr.C
-- Added reinitialization at load_ptr
--
-- Revision 1.9  2002/11/29 13:12:06  Dr.C
-- Corrected ready generation and bus request.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;



--library ahb_config_pkg;
library work;
--use ahb_config_pkg.ahb_config_pkg.all;
use work.ahb_config_pkg.all;

 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity mem2_seq is
  port (
    --------------------------------------------
    -- Clock & reset
    --------------------------------------------
    hclk          : in  std_logic;                      -- AHB clock 
    hreset_n      : in  std_logic;                      -- AHB reset
    
    --------------------------------------------
    -- Bup registers
    --------------------------------------------
    buprxptr      : in  std_logic_vector(31 downto 0);  -- receive buffer addr
    buptxptr      : in  std_logic_vector(31 downto 0);  -- trans buffer addr
    load_ptr      : in  std_logic;                      -- pulse to load new ptr 
    
    --------------------------------------------
    -- Bup state machine
    --------------------------------------------
    req           : in  std_logic;                      -- request for new byte
    ind           : in  std_logic;                      -- new byte is ready
    data_rec      : in  std_logic_vector(7 downto 0);   -- byte received
    last_word     : in  std_logic;                      -- last bytes
    tx            : in  std_logic;                      -- transmission 
    rx            : in  std_logic;                      -- reception
    ready         : out std_logic;                      -- data is valid
    trans_data    : out std_logic_vector(7 downto 0);   -- data to transmit
    ready_load    : out std_logic;                      -- ready 4 new load_ptr
    reset_bufempty: out std_logic;                      -- reset bufempty when RX buffer written
        
    --------------------------------------------
    -- AHB master interface
    --------------------------------------------
    inc_addr      : in  std_logic;                      -- increment address 
    decr_addr     : in  std_logic;                      -- decrement address
    valid_data    : in  std_logic;                      -- data is valid
    end_add       : in  std_logic;                      -- last address
    end_data      : in  std_logic;                      -- last data
    free          : in  std_logic;                      -- master busy          
    busreq        : out std_logic;                      -- bus request
    unspeclength  : out std_logic;                      -- stop incr. burst

    
    --------------------------------------------
    -- AHB bus
    --------------------------------------------
    hrdata        : in std_logic_vector (31 downto 0);  -- AHB read data
    hlock         : out std_logic;                      -- bus lock
    hwrite        : out std_logic;                      -- write transaction
    hsize         : out std_logic_vector (2 downto 0);  -- transfer size
    hburst        : out std_logic_vector (2 downto 0);  -- burst type
    hprot         : out std_logic_vector (3 downto 0);  -- protection
    haddr         : out std_logic_vector (31 downto 0); -- AHB address
    hwdata        : out std_logic_vector (31 downto 0)  -- AHB write data
  );

end mem2_seq;
