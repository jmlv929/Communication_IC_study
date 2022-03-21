
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : bit_ser_mult
--    ,' GoodLuck ,'      RCSfile: bit_ser_mult.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.4  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Configurable bit-serial multiplier
--
--               - One multiplicand is supplied in parallel the other is shifted
--                 in serially LSB first.
--               - The output product appears one bit at a time and should be
--                 shifted into an appropriately sized register.
--               - The multiplication of two N-bit numbers is completed in 2N
--                 clk cycles. N zeros should be shifted in after the N-bits of
--                 the serial multiplicand.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/bit_ser_mult/vhdl/rtl/bit_ser_mult.vhd,v  
--  Log: bit_ser_mult.vhd,v  
-- Revision 1.4  2003/05/16 08:40:25  rrich
-- Added extra comment
--
-- Revision 1.3  2003/05/13 07:55:58  rrich
-- Fixed synch. reset!
--
-- Revision 1.2  2003/05/13 07:37:44  rrich
-- Added synchronous reset
--
-- Revision 1.1  2003/04/22 08:58:55  rrich
-- Initial revision
--
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 

--library bit_ser_adder_rtl;
library work;
--use bit_ser_adder_rtl.bit_ser_adder_pkg.all;
use work.bit_ser_adder_pkg.all;

--library bit_ser_mult_rtl;
library work;
--use bit_ser_mult_rtl.bit_ser_mult_pkg.all;
use work.bit_ser_mult_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity bit_ser_mult is
  
  generic (
    data_size_g : integer := 8);  -- bits in multiplicand and multiplier

  port (
    clk        : in  std_logic;
    reset_n    : in  std_logic;
    sync_reset : in  std_logic;
    x_par_in   : in  std_logic_vector(data_size_g-1 downto 0);
    y_ser_in   : in  std_logic;
    p_ser_out  : out std_logic);

end bit_ser_mult;
