
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Cordic
--    ,' GoodLuck ,'      RCSfile: shift_adder.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.3   
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
--  Source: ./git/COMMON/IPs/NLWARE/DSP/cordic/vhdl/rtl/shift_adder.vhd,v  
--  Log: shift_adder.vhd,v  
-- Revision 1.3  2002/11/08 13:45:14  Dr.J
-- Removed clk and reset in shift adder
--
-- Revision 1.2  2002/09/16 16:08:26  Dr.J
-- Added Constants for Synopsys
--
-- Revision 1.1  2002/05/21 15:39:30  Dr.J
-- Initial revision
--
--
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_unsigned.all; 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity shift_adder is
  generic (                                                           
    data_length_g : integer := 16;
    stage_g       : integer := 0
  );                                                                  
  port (                                                              
        z_sign   : in  std_logic; -- 1 : neg ; 0 : pos
        x_in     : in  std_logic_vector(data_length_g downto 0);  
        y_in     : in  std_logic_vector(data_length_g downto 0);
         
        x_out    : out std_logic_vector(data_length_g downto 0);
        y_out    : out std_logic_vector(data_length_g downto 0)
  );                                                                  
end shift_adder;
