
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Divider
--    ,' GoodLuck ,'      RCSfile: srt_div.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Divider.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/divider/vhdl/rtl/srt_div.vhd,v  
--  Log: srt_div.vhd,v  
-- Revision 1.4  2003/06/10 13:56:36  Dr.F
-- code cleaning.
--
-- Revision 1.3  2003/05/20 08:17:35  Dr.F
-- removed "others" on partial_quotien assignment due to synopsys limitation.
--
-- Revision 1.2  2003/05/14 09:30:03  rrich
-- Fixed spurious value_ready after asynch reset
--
-- Revision 1.1  2003/03/27 07:38:11  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


--------------------------------------------
-- Entity
--------------------------------------------
entity srt_div is

  generic (nbit_input_g    : integer := 10;
           nbit_quotient_g : integer := 10);

  port(clk         : in  std_logic;
       reset_n     : in  std_logic;
       start       : in  std_logic;  -- start division on pulse
       dividend    : in  std_logic_vector(nbit_input_g-1 downto 0);
       divisor     : in  std_logic_vector(nbit_input_g-1 downto 0);
       quotient    : out std_logic_vector(nbit_quotient_g-1 downto 0);
       value_ready : out std_logic); -- quotient is available on pulse

end srt_div;
