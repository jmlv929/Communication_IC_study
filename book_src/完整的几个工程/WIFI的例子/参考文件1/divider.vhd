
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Divider
--    ,' GoodLuck ,'      RCSfile: divider.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Divider.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/divider/vhdl/rtl/divider.vhd,v  
--  Log: divider.vhd,v  
-- Revision 1.2  2003/06/10 13:55:43  Dr.F
-- cleaned and debugged rounding problems.
--
-- Revision 1.1  2003/03/27 07:38:08  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--library divider_rtl;
library work;
--use divider_rtl.divider_pkg.all;
use work.divider_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity divider is

  generic (nbit_input_g       : integer := 25;
           nbit_quotient_g    : integer := 12;
           nintbit_quotient_g : integer := 1);

  port(clk         : in  std_logic;
       reset_n     : in  std_logic;
       start       : in  std_logic;  -- start division on pulse
       dividend    : in  std_logic_vector(nbit_input_g-1 downto 0);
       divisor     : in  std_logic_vector(nbit_input_g-1 downto 0);
       quotient    : out std_logic_vector(nbit_quotient_g-1 downto 0);
       value_ready : out std_logic); -- quotient is available on pulse




end divider;
