--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: complex_mult.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Complex multiplier.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/complex_mult.vhd,v  
--  Log: complex_mult.vhd,v  
-- Revision 1.2  2003/06/25 16:11:13  Dr.F
-- code cleaning.
--
-- Revision 1.1  2003/03/27 07:48:42  Dr.F
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
entity complex_mult is

  generic (NBit_input1_g : integer := 10;
           NBit_input2_g : integer := 10);

  port (clk      : in  std_logic;
        reset_n  : in  std_logic;
        real_1_i : in  std_logic_vector(NBit_input1_g-1 downto 0);
        imag_1_i : in  std_logic_vector(NBit_input1_g-1 downto 0);
        real_2_i : in  std_logic_vector(NBit_input2_g-1 downto 0);
        imag_2_i : in  std_logic_vector(NBit_input2_g-1 downto 0);
        real_o   : out std_logic_vector(NBit_input1_g+NBit_input2_g downto 0);
        imag_o   : out std_logic_vector(NBit_input1_g+NBit_input2_g downto 0)
        );


end complex_mult;
