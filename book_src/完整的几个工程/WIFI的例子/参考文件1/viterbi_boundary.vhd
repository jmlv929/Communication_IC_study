
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: viterbi_boundary.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.20   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Boundary block around the viterbi to use it in the Modem 
--               802.11a.
--
--               Contains the state machines to control the Viterbi.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/viterbi/vhdl/rtl/viterbi_boundary.vhd,v  
--  Log: viterbi_boundary.vhd,v  
-- Revision 1.20  2003/11/18 15:19:44  Dr.C
-- Changed input datas for the viterbi during flush_mode and flush mode active comb.
--
-- Revision 1.19  2003/11/12 10:41:24  Dr.C
-- Removed last change.
--
-- Revision 1.18  2003/11/07 09:59:30  Dr.C
-- Debugged.
--
-- Revision 1.17  2003/11/07 09:52:38  Dr.C
-- Changed the generation of the input data for the viterbi and debugged sensitivity list.
--
-- Revision 1.16  2003/10/28 15:40:09  Dr.C
-- Changed value of soft_input_X/Y_i to 15 during flush mode.
--
-- Revision 1.15  2003/10/28 13:12:13  Dr.C
-- Debugged syntax.
--
-- Revision 1.14  2003/10/28 11:24:18  ahemani
-- Flush control logic changed.
-- Logic to change signed to unsigned made compatible with Matlab
--
-- Revision 1.13  2003/10/03 15:43:02  Dr.C
-- Changed reg_length_g from 48 to 56.
--
-- Revision 1.12  2003/07/17 13:18:51  Dr.C
-- Debugged data valid state machine for sync reset value.
--
-- Revision 1.11  2003/07/17 13:10:24  Dr.C
-- Debugged data state machine for sync reset value.
--
-- Revision 1.10  2003/06/10 11:15:58  Dr.J
-- Debugged th flush mode
--
-- Revision 1.9  2003/06/10 08:08:44  Dr.J
-- Updated the flush mode
--
-- Revision 1.8  2003/05/27 14:47:26  Dr.J
-- Removed unused signals
--
-- Revision 1.7  2003/05/16 16:43:57  Dr.J
-- Removed the ;
-- /
--
-- Revision 1.6  2003/05/16 16:35:19  Dr.J
-- Changed the type of field_length_i
--
-- Revision 1.5  2003/05/15 15:59:45  Dr.J
-- Removed the bug created when I removed the latch
--
-- Revision 1.4  2003/05/15 08:56:36  Dr.J
-- removed latch on data_o
--
-- Revision 1.3  2003/05/05 17:30:34  Dr.J
-- Added field_length)i in the sensitive list
--
-- Revision 1.2  2003/05/02 14:05:11  Dr.J
-- Changed timing due to the flipflop on the datat out
--
-- /
--
-- Revision 1.1  2003/05/02 12:34:09  Dr.J
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
  use IEEE.STD_LOGIC_1164.ALL; 
  use IEEE.STD_LOGIC_ARITH.ALL; 
  use IEEE.STD_LOGIC_UNSIGNED.ALL; 
 

--library viterbi_rtl; 
library work;
--  use viterbi_rtl.viterbi_pkg.ALL; 
use work.viterbi_pkg.ALL; 
--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity viterbi_boundary is
  generic (
    code_0_g     : integer := 91;    -- Upper code vector in decimal
    code_1_g     : integer := 121;   -- Lower code vector in decimal
    algorithm_g  : integer  := 0;    -- 0 => Register exchange algorithm.
                                     -- 1 => Trace back algorithm.
    reg_length_g : integer  := 56;   -- Number of bits for error recovery.
    short_reg_length_g : integer  := 18;   -- Number of bits for error recovery.
    datamax_g    : integer  := 5;    -- Number of soft decision input bits.
    path_length_g: integer := 9;     -- No of bits to code the path   metrics.
    error_check_g: integer := 0      -- 0 => no error check. 1 => error check
  );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n         : in  std_logic;  -- Async Reset
    clk             : in  std_logic;  -- 200 Clock
    sync_reset_n    : in  std_logic;  -- Software reset

    --------------------------------------
    -- Symbol Strobe
    --------------------------------------
    enable_i        : in  std_logic;  -- Enable signal
    data_valid_i    : in  std_logic;  -- Data Valid signal for input
    data_valid_o    : out std_logic;  -- Data Valid signal for output
    start_field_i   : in  std_logic;  -- Initilization signal
    end_field_o     : out std_logic;  -- marks the position of last decoded bit
    --------------------------------------
    -- Data Interface
    --------------------------------------
    v0_in           : in  std_logic_vector(datamax_g-1 downto 0);
    v1_in           : in  std_logic_vector(datamax_g-1 downto 0);
    hard_output_o   : out std_logic;
    
    --------------------------------------
    -- Field Information Interface
    --------------------------------------
    field_length_i  : in  std_logic_vector(15 downto 0)  -- Give the length of the current field.
  );

end viterbi_boundary;
