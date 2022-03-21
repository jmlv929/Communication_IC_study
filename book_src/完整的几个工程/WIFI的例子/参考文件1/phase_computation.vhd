
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: phase_computation.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.8   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Phase Computation
--
-- From the position of the peak (0->F) determined by the peak search block :
-- * find the 3 previous B peaks and calculate angle 
-- * find the next peak CP1 and calculate angle
-- * Store the results inside xp_buffer .
-- When cp2_detected_i, then CP1 angle replace the last B calculated (if it has
-- already been calculated)
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/postprocessing/vhdl/rtl/phase_computation.vhd,v  
--  Log: phase_computation.vhd,v  
-- Revision 1.8  2004/01/14 14:57:46  Dr.B
-- remove call to conv_pkg.
--
-- Revision 1.7  2003/08/01 14:53:06  Dr.B
-- nb_to_take_into_account takes only 2 values.
--
-- Revision 1.6  2003/06/27 16:37:51  Dr.B
-- debug max_nb_reached_gen.
--
-- Revision 1.5  2003/06/25 17:11:22  Dr.B
-- memorize xc - bug on nb_b_count_max.
--
-- Revision 1.3  2003/04/11 08:53:43  Dr.B
-- remove unused last b angle register.
--
-- Revision 1.2  2003/04/04 16:24:05  Dr.B
-- removed unused place on xp_buffer
-- (no need to memorize last B)
--
-- Revision 1.1  2003/03/27 16:49:00  Dr.B
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
use ieee.std_logic_unsigned.all;

--library cordic_vect_rtl;
library work;

--library postprocessing_rtl;
library work;
--use postprocessing_rtl.postprocessing_pkg.all;
use work.postprocessing_pkg.all;
--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity phase_computation is
  generic (
    xb_size_g      : integer := 10);-- size of xb
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk              : in  std_logic;
    reset_n          : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i           : in  std_logic;   -- initialize registers
    -- Peak Position
    peak_position_i  : in  std_logic_vector (3 downto 0);  -- position of peak mod 16
    f_position_i     : in  std_logic;   -- start to get the prev peaks
    -- Memory Interface
    mem_wr_ptr_i     : in  std_logic_vector (6 downto 0);  -- wr_ptr of shared fifo
    mem_wr_enable_i  : in  std_logic;
    xb_from_mem_re_i : in  std_logic_vector (xb_size_g-1 downto 0);  -- xb stored in mem
    xb_from_mem_im_i : in  std_logic_vector (xb_size_g-1 downto 0);  -- xb stored in mem
    -- CP2 info
    cp2_detected_i   : in  std_logic; -- high (and remain high when cp2 is detected
    -- xc1 calculated
    xc1_data_valid_i : in  std_logic;
    xc1_re_i         : in  std_logic_vector (xb_size_g-1 downto 0);  -- xb dir calculated
    xc1_im_i         : in  std_logic_vector (xb_size_g-1 downto 0);  -- xb dir calculated
    --
    -- XP Buffer
    xp_valid_o       : out std_logic;
    xp_buf0_o        : out std_logic_vector (xb_size_g+2 downto 0);  
    xp_buf1_o        : out std_logic_vector (xb_size_g+2 downto 0);  
    xp_buf2_o        : out std_logic_vector (xb_size_g+2 downto 0);   
    xp_buf3_o        : out std_logic_vector (xb_size_g+2 downto 0);
    nb_xp_to_take_o  : out std_logic; -- '0' for 3 and '1' for 4
    -- Memory Rd Pointer
    read_enable_o    : out std_logic;
    mem_rd_ptr_o      : out std_logic_vector (6 downto 0)  -- rd_ptr of shared fifo
    
  );

end phase_computation;
