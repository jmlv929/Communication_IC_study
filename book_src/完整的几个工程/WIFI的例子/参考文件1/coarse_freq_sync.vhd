
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: coarse_freq_sync.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.6  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Coarse Frequency Synchronization
--
-- Phase samples are stored in a buffer XP and reordered. Then Phase unwrapping
-- is performed -> XU, and finally phase sample substraction is executed -> XD.
-- From XD, the phase slope estimation (MMSE) yields the NOC update cf.
-- 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/postprocessing/vhdl/rtl/coarse_freq_sync.vhd,v  
--  Log: coarse_freq_sync.vhd,v  
-- Revision 1.6  2003/12/09 10:11:40  Dr.B
-- reset xu buffer when idle.
--
-- Revision 1.5  2003/08/01 14:51:51  Dr.B
-- remove case when 2 m_factors.
--
-- Revision 1.4  2003/06/27 16:13:47  Dr.B
-- reduce su size.
--
-- Revision 1.3  2003/06/25 17:08:15  Dr.B
-- change su_o size.
--
-- Revision 1.2  2003/04/04 16:22:44  Dr.B
-- change pi_ct (because of scaling).
--
-- Revision 1.1  2003/03/27 16:48:20  Dr.B
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

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity coarse_freq_sync is
  generic (
    xp_size_g : integer := 13);         -- xp size
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk     : in std_logic;
    reset_n : in std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i              : in std_logic;  -- when high reset registers
    -- XP Buffer
    xp_valid_i       : in  std_logic;
    xp_buf0_i        : in  std_logic_vector (xp_size_g-1 downto 0);  
    xp_buf1_i        : in  std_logic_vector (xp_size_g-1 downto 0);  
    xp_buf2_i        : in  std_logic_vector (xp_size_g-1 downto 0);   
    xp_buf3_i        : in  std_logic_vector (xp_size_g-1 downto 0);
    nb_xp_to_take_i  : in  std_logic; -- nb xp to take into account '0' for 3 and '1' for 4
    
    -- Coarse Frequency Correction Increment
    su_o             : out std_logic_vector (xp_size_g+3 downto 0);
    su_data_valid_o  : out std_logic
    );

end coarse_freq_sync;
