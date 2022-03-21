
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: cordic_vect.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.14   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Cordic algoritm for cartesian to polar conversion,
--               used to get the angle from a complex value.
--               Input must be between (-pi/2,pi/2)
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/cordic_vect/vhdl/rtl/cordic_vect.vhd,v  
--  Log: cordic_vect.vhd,v  
-- Revision 1.14  2004/08/24 15:48:47  arisse
-- Added globals for test purpose.
--
-- Revision 1.13  2003/06/30 15:43:08  Dr.C
-- Modified to be synopsys compliant
--
-- Revision 1.12  2003/06/27 14:26:00  Dr.B
-- saturate output on scaled mode.
--
-- Revision 1.11  2003/06/24 13:42:58  Dr.B
-- xn : signed => unsigned for getting 1 bit of precision and avoiding overflo
--
-- Revision 1.10  2003/04/17 14:35:19  Dr.B
-- index continue counting until data_ready (included).
--
-- Revision 1.9  2003/04/03 13:43:03  Dr.B
-- add scaling_g generic.
--
-- Revision 1.8  2003/03/19 08:39:27  Dr.B
-- when datasize + 1 < errorsize, datasize + 1 iterations.
--
-- Revision 1.7  2003/03/11 15:31:14  Dr.B
-- angle_out = 0 only when x_in/y_in=0 and load=1 (memo).
--
-- Revision 1.6  2002/12/13 18:33:01  Dr.J
-- Changed index to be checked by the formal verification tool
--
-- Revision 1.5  2002/10/28 10:01:58  Dr.C
-- Changed library name
--
-- Revision 1.4  2002/07/11 12:24:05  Dr.J
-- Changed the data size
--
-- Revision 1.3  2002/06/10 13:13:43  Dr.J
-- Updated the angle size
--
-- Revision 1.2  2002/05/02 07:37:28  Dr.A
-- Added work around for Synopsys synthesis.
--
-- Revision 1.1  2002/03/28 12:42:00  Dr.A
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
--use cordic_vect_rtl.cordic_vect_pkg.all;
use work.cordic_vect_pkg.all;
 
--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity cordic_vect is
  generic (
    datasize_g    : integer := 10; -- Data size. Max value is 30.
    errorsize_g   : integer := 10; -- Data size. Max value is 30.
    scaling_g     : integer := 0   -- 1:Use all the amplitude of angle_out
                                        --  pi/2 =^=  2^errosize_g =~ 01111... 
  );                                    -- -pi/2 =^= -2^errosize_g =  100000.. 
  port (
    -- clock and reset.
    clk          : in  std_logic;                   
    reset_n      : in  std_logic;    
    --
    load         : in  std_logic; -- Load input values.
    x_in         : in  std_logic_vector(datasize_g-1 downto 0); -- Real part in.
    y_in         : in  std_logic_vector(datasize_g-1 downto 0); -- Imaginary part.
    --
    angle_out    : out std_logic_vector(errorsize_g-1 downto 0); -- Angle out.
    cordic_ready : out std_logic                             -- Angle ready.
  );

end cordic_vect;
