

--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : CORDIC
--    ,' GoodLuck ,'      RCSfile: cordic_vectoring.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Vectoring CORDIC. This CORDIC computes the angle and the
--               magnitude of a complex input sample.
--               The computation is performed using rotations to align the
--               input sample to with the X axis.
--               This CORDIC is configurable in term of pipelines and
--               number of microratation per clock cycle.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/cordic_vectoring/vhdl/rtl/cordic_vectoring.vhd,v  
--  Log: cordic_vectoring.vhd,v  
-- Revision 1.4  2004/01/26 07:44:05  Dr.F
-- removed mag_o from process.
--
-- Revision 1.3  2004/01/14 13:54:56  Dr.F
-- removed piece of array in sensitivty list due to synopsys limitation.
--
-- Revision 1.2  2003/03/19 17:32:26  Dr.F
-- algorithm changed when the angle is not in [-PI/2;PI/2].
--
-- Revision 1.1  2003/03/17 07:49:59  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------


library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_unsigned.all; 

--library cordic_vectoring_rtl;
library work;
--use cordic_vectoring_rtl.cordic_vectoring_pkg.all;
use work.cordic_vectoring_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity cordic_vectoring is
  generic (
    -- number of bits for the complex data :
    data_length_g   : integer := 12;
    -- number of bits for the output angle z_in :
    angle_length_g  : integer := 12;
    -- number of microrotation stages in a combinational path :
    nbr_combstage_g : integer := 3; -- must be > 0
    -- number of pipes
    nbr_pipe_g      : integer := 4  -- must be > 0
    -- NOTE : the total number of microrotations is nbr_combstage_g * nbr_pipe_g
  );                                                                  
  port (                                                              
        clk      : in  std_logic;                                
        reset_n  : in  std_logic; 
        
        -- input vector to be rotated :
        x_i    : in  std_logic_vector(data_length_g-1 downto 0);  
        y_i    : in  std_logic_vector(data_length_g-1 downto 0);
         
        -- angle of the input vector :                          
        z_o    : out std_logic_vector(angle_length_g-1 downto 0);
        -- magnitude of the input vector
        mag_o  : out std_logic_vector(data_length_g downto 0)
  );                                                                  
end cordic_vectoring;
