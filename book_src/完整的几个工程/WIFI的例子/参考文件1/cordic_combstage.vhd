
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Cordic
--    ,' GoodLuck ,'      RCSfile: cordic_combstage.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block is composed of a microrotation stage . 
--               It produces (x_out,y_out) rotated outputs with the remaining 
--               angle z_out to be rotated.
--               The microrotation stages are performed in a combinational
--               way, without any flip-flop between stages.
-- WARNING : The following signals are multidimensional arraies :
--             z_i, x0_i, y0_i, arctan_array and arctan_array_ref.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/cordic/vhdl/rtl/cordic_combstage.vhd,v  
--  Log: cordic_combstage.vhd,v  
-- Revision 1.4  2003/05/07 13:34:17  Dr.J
-- Added enable
--
-- Revision 1.3  2002/11/08 13:44:45  Dr.J
-- Removed clk and reset in shift_adder
--
-- Revision 1.2  2002/06/10 12:58:12  Dr.J
-- Debugged the calculation of the angle
--
-- Revision 1.1  2002/05/21 15:39:03  Dr.J
-- Initial revision
--
--
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_unsigned.all; 

--library cordic_rtl;
library work;
--use cordic_rtl.cordic_pkg.all;
use work.cordic_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity cordic_combstage is
  generic (                                                           
    data_length_g  : integer := 16;
    angle_length_g : integer := 16;
    start_stage_g  : integer := 0;
    nbr_stage_g    : integer := 4;
    nbr_input_g    : integer := 1
  );                                                                  
  port (                                                              
        clk      : in  std_logic;                                
        reset_n  : in  std_logic; 
        enable   : in  std_logic;
        -- angle with which the inputs must be rotated :                          
        z_in     : in  std_logic_vector(angle_length_g-1 downto 0);
        
        -- inputs to be rotated :
        x0_in    : in  std_logic_vector(data_length_g downto 0);  
        y0_in    : in  std_logic_vector(data_length_g downto 0);
        x1_in    : in  std_logic_vector(data_length_g downto 0);  
        y1_in    : in  std_logic_vector(data_length_g downto 0);
        x2_in    : in  std_logic_vector(data_length_g downto 0);  
        y2_in    : in  std_logic_vector(data_length_g downto 0);
        x3_in    : in  std_logic_vector(data_length_g downto 0);  
        y3_in    : in  std_logic_vector(data_length_g downto 0);
         
        -- Arctangent reference table
        arctan_array_ref : in ArrayOfSLV32(nbr_stage_g-1 downto 0);
        
        -- remaining angle with which outputs have not been rotated : 
        z_out    : out std_logic_vector(angle_length_g-1 downto 0);
        
        -- rotated output. They have been rotated of (z_in-z_out) :
        x0_out   : out std_logic_vector(data_length_g downto 0);
        y0_out   : out std_logic_vector(data_length_g downto 0);
        x1_out   : out std_logic_vector(data_length_g downto 0);
        y1_out   : out std_logic_vector(data_length_g downto 0);
        x2_out   : out std_logic_vector(data_length_g downto 0);
        y2_out   : out std_logic_vector(data_length_g downto 0);
        x3_out   : out std_logic_vector(data_length_g downto 0);
        y3_out   : out std_logic_vector(data_length_g downto 0)
  );                                                                  
end cordic_combstage;
