
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: err_phasor.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.7  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Error Phasor Accumulation
--  Accumulate result of multiplication of each data of T1 Coarse and T2 Coarse
-- (for frequency offset calculation)
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/fine_freq_estim/vhdl/rtl/err_phasor.vhd,v  
--  Log: err_phasor.vhd,v  
-- Revision 1.7  2005/02/01 16:24:46  Dr.C
-- #BugId:1001#
-- Added saturation on output data.
--
-- Revision 1.6  2004/04/06 12:47:03  Dr.C
-- Removed the addition of 1 for max_mod calculation.
--
-- Revision 1.5  2003/04/18 08:42:29  Dr.B
-- truncation mult changed.
--
-- Revision 1.4  2003/04/11 08:58:48  Dr.B
-- last scale to the nearest.
--
-- Revision 1.3  2003/04/04 16:31:55  Dr.B
-- NEW ERR_PHASOR.
--
-- Revision 1.2  2003/04/01 11:50:45  Dr.B
-- counter from sm.
--
-- Revision 1.1  2003/03/27 17:44:49  Dr.B
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
 
--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity err_phasor is
  generic(dsize_g            : integer); 
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                 : in  std_logic;
    reset_n             : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i              : in  std_logic;
    -- Control Signals
    data_valid_i        : in  std_logic;
    start_of_symbol_i   : in  std_logic;
    shift_param_i       : in  std_logic_vector(2 downto 0);
    -- T2 COARSE INPUT
    t2coarse_re_i       : in  std_logic_vector(dsize_g-1 downto 0); 
    t2coarse_im_i       : in  std_logic_vector(dsize_g-1 downto 0);
    -- T1 COARSE INPUT
    t1coarse_re_i       : in  std_logic_vector(dsize_g-1 downto 0);
    t1coarse_im_i       : in  std_logic_vector(dsize_g-1 downto 0);
    -- Result of err phasor_acc
    re_err_phasor_acc_o : out std_logic_vector(10 downto 0);
    im_err_phasor_acc_o : out std_logic_vector(10 downto 0)
  );

end err_phasor;
