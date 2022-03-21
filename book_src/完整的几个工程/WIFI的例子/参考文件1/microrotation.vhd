
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : CORDIC
--    ,' GoodLuck ,'      RCSfile: microrotation.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This bloc computes the microrotation as defined in CORDIC
--               algorithm :
--                 x_out = x_in - (1-2*z_sign)*2^(-stage_g)*y_in
--                 y_out = y_in + (1-2*z_sign)*2^(-stage_g)*x_in
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/cordic_vectoring/vhdl/rtl/microrotation.vhd,v  
--  Log: microrotation.vhd,v  
-- Revision 1.4  2003/06/24 06:42:47  Dr.F
-- replaced SXT by EXT in shift_x due to saturation problem and knowing that x is always positive.
--
-- Revision 1.3  2003/06/11 16:07:34  Dr.F
-- removed clk and reset_n.
--
-- Revision 1.2  2003/05/20 08:10:22  Dr.F
-- used SXT for sign extention.
--
-- Revision 1.1  2003/03/17 07:50:03  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all; 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity microrotation is
  generic (                                                           
    data_length_g : integer := 16;
    stage_g       : integer := 0
  );                                                                  
  port (                                                              
    x_i      : in  std_logic_vector(data_length_g downto 0);  
    y_i      : in  std_logic_vector(data_length_g downto 0);
     
    x_o      : out std_logic_vector(data_length_g downto 0);
    y_o      : out std_logic_vector(data_length_g downto 0)
  );                                                                  
end microrotation;
