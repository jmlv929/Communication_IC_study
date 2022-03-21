
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: postprocessing.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.10   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Postprocessing Block. Detect Peak - Detect CP2 and calculate
-- an estimation of the frequency offset
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/postprocessing/vhdl/rtl/postprocessing.vhd,v  
--  Log: postprocessing.vhd,v  
-- Revision 1.10  2004/12/14 17:40:46  Dr.C
-- #BugId:810#
-- Added peak_position debug output.
--
-- Revision 1.9  2003/12/23 10:19:20  Dr.B
-- add generic yb_max_g.
--
-- Revision 1.8  2003/10/15 13:22:48  Dr.C
-- Changed saturation of yb_o.
--
-- Revision 1.7  2003/10/15 09:24:11  Dr.C
-- Added yb_o for debug.
--
-- Revision 1.6  2003/08/01 14:54:00  Dr.B
-- changes for new metrics calc.
--
-- Revision 1.5  2003/06/27 16:42:19  Dr.B
-- change su size.
--
-- Revision 1.4  2003/06/25 17:12:20  Dr.B
-- generation of filtered xc_data_valid.
--
-- Revision 1.3  2003/04/11 08:54:56  Dr.B
-- changed cf_inc trunc.
--
-- Revision 1.2  2003/04/02 13:08:52  Dr.B
-- mb_lpeak => mc1_lpeak.
--
-- Revision 1.1  2003/03/27 16:49:20  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
--library postprocessing_rtl;
library work;
--use postprocessing_rtl.postprocessing_pkg.all;
use work.postprocessing_pkg.all;

--library preprocessing_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity postprocessing is
  generic (
    xb_size_g : integer := 10);
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                 : in  std_logic;
    reset_n             : in  std_logic;
    init_i              : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    -- XB from B Correlator
    xb_data_valid_i     : in  std_logic;                      -- xb available
    xb_re_i             : in  std_logic_vector (xb_size_g-1 downto 0);  -- xb real part
    xb_im_i             : in  std_logic_vector (xb_size_g-1 downto 0);  -- xb im part
    -- XC1 from CP1 Correlator
    xc1_re_i            : in  std_logic_vector (xb_size_g-1 downto 0);
    xc1_im_i            : in  std_logic_vector (xb_size_g-1 downto 0);
    -- YC1 - YC2 - Mag from Correlator (yc_data_valid = xc_data_valid)
    yc1_i               : in  std_logic_vector (xb_size_g-1 downto 0);
    yc2_i               : in  std_logic_vector (xb_size_g-1 downto 0);
    -- Memory Interface
    xb_from_mem_re_i    : in  std_logic_vector (xb_size_g-1 downto 0);  -- xb stored in mem
    xb_from_mem_im_i    : in  std_logic_vector (xb_size_g-1 downto 0);  -- xb stored in mem
    wr_ptr_i            : in  std_logic_vector(6 downto 0);
    mem_wr_enable_i     : in  std_logic;
    --
    rd_ptr1_o           : out std_logic_vector (6 downto 0);
    read_enable_o       : out std_logic;
    --
    cf_inc_o            : out std_logic_vector (23 downto 0);
    cf_inc_data_valid_o : out std_logic;
    --
    cp2_detected_o      : out std_logic;
    preamb_detect_o     : out std_logic;
    -- Internal signal for debug
    yb_o                : out std_logic_vector(3 downto 0);
    peak_position_o     : out std_logic_vector(3 downto 0)
    );

end postprocessing;
