
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: interl_mem.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : The first permutation is done by writing the data in memory in
--               a specific order, and reading it back in another order. This
--               block implements the memory in registers.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/interleaver/vhdl/rtl/interl_mem.vhd,v  
--  Log: interl_mem.vhd,v  
-- Revision 1.2  2004/12/14 10:48:49  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.1  2003/03/13 14:50:53  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity interl_mem is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk        : in  std_logic; -- Module clock.
    reset_n    : in  std_logic; -- Asynchronous reset.
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i   : in  std_logic; -- TX path enable.
    addr_i     : in  std_logic_vector( 4 downto 0); -- Memory address.
    mask_wr_i  : in  std_logic_vector( 5 downto 0); -- memory write mask.
    rd_wrn_i   : in  std_logic; -- '1' means read, '0' means write.
    msb_lsbn_i : in  std_logic; -- '1' to read the MSB, '0' to read the LSB.
    --------------------------------------
    -- Data
    --------------------------------------
    x_i        : in  std_logic; -- x data from puncturer.
    y_i        : in  std_logic; -- y data from puncturer.
    --
    data_p1_o  : out std_logic_vector( 5 downto 0) -- Permutated data.
    
  );

end interl_mem;
