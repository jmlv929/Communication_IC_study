
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem802.11b
--    ,' GoodLuck ,'      RCSfile: complex_4mult.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Perform 4 complex multiplications
--               one different for each value of div_counter
--               Does not perform the additions
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/equalizer/vhdl/rtl/complex_4mult.vhd,v  
--  Log: complex_4mult.vhd,v  
-- Revision 1.1  2002/06/27 16:11:25  Dr.B
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

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity complex_4mult is
  generic (
    dsize_g : integer := 8; -- data size
    csize_g : integer := 9  -- coeff size
  );
  port (
    -- Inputs :
    -- coefficients
    coeff0_i      : in  std_logic_vector(csize_g-1 downto 0); 
    coeff1_i      : in  std_logic_vector(csize_g-1 downto 0); 
    coeff2_i      : in  std_logic_vector(csize_g-1 downto 0); 
    coeff3_i      : in  std_logic_vector(csize_g-1 downto 0); 
    coeff0_q      : in  std_logic_vector(csize_g-1 downto 0); 
    coeff1_q      : in  std_logic_vector(csize_g-1 downto 0); 
    coeff2_q      : in  std_logic_vector(csize_g-1 downto 0); 
    coeff3_q      : in  std_logic_vector(csize_g-1 downto 0);
    -- data
    data0_i       : in  std_logic_vector(dsize_g-1 downto 0);
    data1_i       : in  std_logic_vector(dsize_g-1 downto 0); 
    data2_i       : in  std_logic_vector(dsize_g-1 downto 0); 
    data3_i       : in  std_logic_vector(dsize_g-1 downto 0);
    data0_q       : in  std_logic_vector(dsize_g-1 downto 0); 
    data1_q       : in  std_logic_vector(dsize_g-1 downto 0); 
    data2_q       : in  std_logic_vector(dsize_g-1 downto 0); 
    data3_q       : in  std_logic_vector(dsize_g-1 downto 0);
    div_counter   : in  std_logic_vector(1 downto 0);
    
    -- Output results. 
    data_i1_mult  : out std_logic_vector(dsize_g+csize_g-1 downto 0);  
    data_i2_mult  : out std_logic_vector(dsize_g+csize_g-1 downto 0);  
    data_q1_mult  : out std_logic_vector(dsize_g+csize_g-1 downto 0);
    data_q2_mult  : out std_logic_vector(dsize_g+csize_g-1 downto 0)
  );

end complex_4mult;
