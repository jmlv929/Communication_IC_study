
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: complex_mult_autocorr.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Partial Part of the multiplication
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/preprocessing/vhdl/rtl/complex_mult_autocorr.vhd,v  
--  Log: complex_mult_autocorr.vhd,v  
-- Revision 1.1  2003/03/27 16:36:35  Dr.B
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

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity complex_mult_autocorr is
  generic (
    size_in_g     : integer := 11      -- size of the data inputs
          );    
  port (

    --------------------------------------
    -- Signals
    --------------------------------------
    -- Data in
    data_in_i : in std_logic_vector(size_in_g - 1 downto 0);
    data_in_q : in std_logic_vector(size_in_g - 1 downto 0);
    -- Coeff
    sign_i   : in std_logic;
    sign_q   : in std_logic;
    -- Results (1 bit more because of the max negative value
    -- that can not be "-" with the same nb of bits
    operand_a_i : out std_logic_vector(size_in_g downto 0);
    operand_a_q : out std_logic_vector(size_in_g downto 0);
    operand_b_i : out std_logic_vector(size_in_g downto 0);
    operand_b_q : out std_logic_vector(size_in_g downto 0)
   

    
  );

end complex_mult_autocorr;
