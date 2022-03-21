
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: correlator.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Correlator for preprocessing (Init Sync)
--
-- RE_Result = Sum (coeff_re_i * Reg_re_i + coeff_im_i * Reg_im_i)
-- IM_Result = Sum (coeff_re_i * Reg_im_i - coeff_im_i * Reg_re_i)
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/preprocessing/vhdl/rtl/correlator.vhd,v  
--  Log: correlator.vhd,v  
-- Revision 1.2  2003/11/18 08:02:20  Dr.B
-- debug i addition.
--
-- Revision 1.1  2003/03/27 16:36:45  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use IEEE.STD_LOGIC_1164.ALL;
use ieee.STD_LOGIC_ARITH.all;

--library preprocessing_rtl;
library work;
--use preprocessing_rtl.preprocessing_pkg.all;
use work.preprocessing_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity correlator is
  generic (
    size_in_g     : integer := 11);      -- size of the data inputs
  port (
    -- Input Data
    -- Real Part
    data_reg0_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg1_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg2_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg3_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg4_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg5_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg6_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg7_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg8_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg9_i  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg10_i : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg11_i : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg12_i : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg13_i : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg14_i : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg15_i : in std_logic_vector(size_in_g - 1 downto 0);
    -- Imaginary Part
    data_reg0_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg1_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg2_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg3_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg4_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg5_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg6_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg7_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg8_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg9_q  : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg10_q : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg11_q : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg12_q : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg13_q : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg14_q : in std_logic_vector(size_in_g - 1 downto 0);
    data_reg15_q : in std_logic_vector(size_in_g - 1 downto 0);
    -- Real Coefficients
    coeff0_i   : in std_logic_vector(1 downto 0);
    coeff1_i   : in std_logic_vector(1 downto 0);
    coeff2_i   : in std_logic_vector(1 downto 0);
    coeff3_i   : in std_logic_vector(1 downto 0);
    coeff4_i   : in std_logic_vector(1 downto 0);
    coeff5_i   : in std_logic_vector(1 downto 0);
    coeff6_i   : in std_logic_vector(1 downto 0);
    coeff7_i   : in std_logic_vector(1 downto 0);
    coeff8_i   : in std_logic_vector(1 downto 0);
    coeff9_i   : in std_logic_vector(1 downto 0);
    coeff10_i  : in std_logic_vector(1 downto 0);
    coeff11_i  : in std_logic_vector(1 downto 0);
    coeff12_i  : in std_logic_vector(1 downto 0);
    coeff13_i  : in std_logic_vector(1 downto 0);
    coeff14_i  : in std_logic_vector(1 downto 0);
    coeff15_i  : in std_logic_vector(1 downto 0);
    -- Imaginary Part                 
    coeff0_q   : in std_logic_vector(1 downto 0);
    coeff1_q   : in std_logic_vector(1 downto 0);
    coeff2_q   : in std_logic_vector(1 downto 0);
    coeff3_q   : in std_logic_vector(1 downto 0);
    coeff4_q   : in std_logic_vector(1 downto 0);
    coeff5_q   : in std_logic_vector(1 downto 0);
    coeff6_q   : in std_logic_vector(1 downto 0);
    coeff7_q   : in std_logic_vector(1 downto 0);
    coeff8_q   : in std_logic_vector(1 downto 0);
    coeff9_q   : in std_logic_vector(1 downto 0);
    coeff10_q  : in std_logic_vector(1 downto 0);
    coeff11_q  : in std_logic_vector(1 downto 0);
    coeff12_q  : in std_logic_vector(1 downto 0);
    coeff13_q  : in std_logic_vector(1 downto 0);
    coeff14_q  : in std_logic_vector(1 downto 0);
    coeff15_q  : in std_logic_vector(1 downto 0);

    -- Result of correlation
    data_out_i : out std_logic_vector(size_in_g + 5 - 1 downto 0);
    data_out_q : out std_logic_vector(size_in_g + 5 - 1 downto 0)    
    );

end correlator;
