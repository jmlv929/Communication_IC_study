
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: phase_slope_comput.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.4  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : MMSE Phase Slope Computation
--
-- The Calculation is performed in 2 periods when M = 4:
-- 1) The xd_buffers are multiplied by constants. The results are added
-- together and registered into su_pipe.
-- 2) The multiplication by the fraction (1/10) is performed
--
-- The result is direct for M = 2 or M = 3
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/postprocessing/vhdl/rtl/phase_slope_comput.vhd,v  
--  Log: phase_slope_comput.vhd,v  
-- Revision 1.4  2003/08/01 14:53:34  Dr.B
-- remove case m_factor = 2.
--
-- Revision 1.3  2003/06/27 16:41:20  Dr.B
-- change su size.
--
-- Revision 1.2  2003/06/25 17:11:59  Dr.B
-- strong simplification.
--
-- Revision 1.1  2003/03/27 16:49:05  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 

use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity phase_slope_comput is
  generic (
    xd_size_g : integer := 13);         -- xp size  
  port (
    --------------------------------------
    -- Clocks & Reset; 
    --------------------------------------
    clk                 : in  std_logic;
    reset_n             : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    m_factor_i          : in  std_logic; -- (3 or 4)
    enable_slope_comp_i : in  std_logic;
    xd_buffer0_i        : in  std_logic_vector(xd_size_g-1 downto 0);
    xd_buffer1_i        : in  std_logic_vector(xd_size_g-1 downto 0);
    --
    su_o                : out std_logic_vector(xd_size_g-2 downto 0)
  );

end phase_slope_comput;
