
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: interl_ctrl.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block has three functionnalities:
--              - Control of the memory used for the first data permutation,
--              - Second data permutation on the first permutated data,
--              - Carrier reordering.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/interleaver/vhdl/rtl/interl_ctrl.vhd,v  
--  Log: interl_ctrl.vhd,v  
-- Revision 1.4  2004/12/14 10:48:45  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.3  2003/05/19 09:11:51  Dr.A
-- Remove unused begin_read from sensitivity list.
--
-- Revision 1.2  2003/03/26 10:57:47  Dr.A
-- Modified marker outputs generation for FFT compliancy.
--
-- Revision 1.1  2003/03/13 14:50:51  Dr.A
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
entity interl_ctrl is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk               : in  std_logic; -- Module clock
    reset_n           : in  std_logic; -- Asynchronous reset.
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i          : in  std_logic; -- TX path enable.
    data_valid_i      : in  std_logic;
    data_ready_i      : in  std_logic;
    qam_mode_i        : in  std_logic_vector(1 downto 0);
    marker_i          : in  std_logic;
    --
    pilot_ready_o     : out std_logic;
    start_signal_o    : out std_logic; -- 'start of signal' marker.
    end_burst_o       : out std_logic; -- 'end of burst' marker.
    data_valid_o      : out std_logic;
    data_ready_o      : out std_logic;
    null_carrier_o    : out std_logic; -- '1' data for null carriers.
    qam_mode_o        : out std_logic_vector( 1 downto 0); -- coding rate.
    --------------------------------------
    -- Memory interface
    --------------------------------------
    data_p1_i         : in  std_logic_vector( 5 downto 0); -- data from memory.
    --
    addr_o            : out std_logic_vector( 4 downto 0); -- address.
    mask_wr_o         : out std_logic_vector( 5 downto 0); -- write mask.
    rd_wrn_o          : out std_logic; -- '1' to read, '0' to write.
    msb_lsbn_o        : out std_logic; -- '1' to read MSB, '0' to read LSB.
    --------------------------------------
    -- Data
    --------------------------------------
    pilot_scr_i       : in  std_logic; -- Data for the 4 pilot carriers.
    --
    data_o            : out std_logic_vector( 5 downto 0) -- Interleaved data.
    
  );

end interl_ctrl;
