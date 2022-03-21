
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: three_correlators.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Instantiate the 3 correlators 
--             + Definition of the coefficients
--             + Shift Registers 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/preprocessing/vhdl/rtl/three_correlators.vhd,v  
--  Log: three_correlators.vhd,v  
-- Revision 1.2  2003/06/25 17:06:52  Dr.B
-- change notation inputs.
--
-- Revision 1.1  2003/03/27 16:36:57  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library preprocessing_rtl;
library work;
--use preprocessing_rtl.preprocessing_pkg.all;
use work.preprocessing_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity three_correlators is
  generic (
    size_in_g         : integer := 11;  -- size of the data inputs
    size_rem_corr_g   : integer := 4);  -- nb of bits removed for corr calc
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n : in std_logic;
    clk     : in std_logic;

    --------------------------------------
    -- Signals
    --------------------------------------
    shift_i       : in  std_logic;      -- shift the registers
    init_i        : in  std_logic;      -- init registers
    -- Input Data
    data_in_i_i   : in  std_logic_vector(size_in_g - 1 downto 0);
    data_in_q_i   : in  std_logic_vector(size_in_g - 1 downto 0);
    -- Registered input data
    data_i_ff15_o : out std_logic_vector(size_in_g - 1 downto 0);
    data_q_ff15_o : out std_logic_vector(size_in_g - 1 downto 0);
    data_i_ff0_o  : out std_logic_vector(size_in_g - 1 downto 0);
    data_q_ff0_o  : out std_logic_vector(size_in_g - 1 downto 0);  -- B-Correlator Output
    bb_out_i_o    : out std_logic_vector(size_in_g-size_rem_corr_g+5-1 downto 0);
    bb_out_q_o    : out std_logic_vector(size_in_g-size_rem_corr_g+5-1 downto 0);
    -- CP1-Correlator Output
    cp1_out_i_o   : out std_logic_vector(size_in_g-size_rem_corr_g+5-1 downto 0);
    cp1_out_q_o   : out std_logic_vector(size_in_g-size_rem_corr_g+5-1 downto 0);
    -- CP2-Correlator Output
    cp2_out_i_o   : out std_logic_vector(size_in_g-size_rem_corr_g+5-1 downto 0);
    cp2_out_q_o   : out std_logic_vector(size_in_g-size_rem_corr_g+5-1 downto 0)
  );

end three_correlators;
