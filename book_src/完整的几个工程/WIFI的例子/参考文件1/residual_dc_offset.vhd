

--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: residual_dc_offset.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.3  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Residual DC offset estimation and compensation.
--               This block is used in the Base-Band part of the Rx .11a path.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/residual_dc_offset/vhdl/rtl/residual_dc_offset.vhd,v  
--  Log: residual_dc_offset.vhd,v  
-- Revision 1.3  2005/03/11 10:14:16  Dr.C
-- #BugId:1120#
-- Removed i/q_ff1 and cleaned procedure.
--
-- Revision 1.2  2005/01/26 09:23:09  Dr.C
-- #BugId:986#
-- Updated Kalman filter coeff and resynchronized m_i and m_q for synthesis.
--
-- Revision 1.1  2005/01/19 17:08:51  Dr.C
-- #BugId:737#
-- First revision.
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--library residual_dc_offset_rtl;
library work;
--use residual_dc_offset_rtl.residual_dc_offset_pkg.all;
use work.residual_dc_offset_pkg.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity residual_dc_offset is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk          : in  std_logic; -- Module clock. 80 MHz
    reset_n      : in  std_logic; -- Asynchronous reset
    sync_reset_n : in  std_logic; -- Synchronous reset.

    --------------------------------------
    -- I & Q
    --------------------------------------
    i_i          : in  std_logic_vector(10 downto 0);
    q_i          : in  std_logic_vector(10 downto 0);
    data_valid_i : in  std_logic; -- toggle when a new data is available
    --
    i_o          : out std_logic_vector(10 downto 0);
    q_o          : out std_logic_vector(10 downto 0);
    data_valid_o : out std_logic; -- toggle when a new data is available

    --------------------------------------
    -- Registers
    --------------------------------------
    dcoffset_disb : in  std_logic; -- Disable the dc offset correction
    
    --------------------------------------
    -- Synchronization
    --------------------------------------
    cp2_detected  : in  std_logic   -- Synchronisation found
    );

end residual_dc_offset;
