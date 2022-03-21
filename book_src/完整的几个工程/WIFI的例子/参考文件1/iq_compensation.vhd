
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: iq_compensation.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.11  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : IQ compensation block.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/iq_compensation/vhdl/rtl/iq_compensation.vhd,v  
--  Log: iq_compensation.vhd,v  
-- Revision 1.11  2004/05/13 14:45:58  Dr.C
-- Added use_sync_reset_g generic.
--
-- Revision 1.10  2004/01/29 08:18:52  Dr.A
-- Updated comments.
--
-- Revision 1.9  2004/01/06 16:59:11  Dr.B
-- Added saturation (to prevent overflow) on q_phase2_nr & i_phase2_nr (process phase_comp2_p).
--
-- Revision 1.8  2003/12/03 18:18:33  Dr.A
-- Changed generic map of eucl_divider because of synthesis long paths. Changed q_out and data_valid_o according to the new delay.
--
-- Revision 1.7  2003/09/12 12:25:03  Dr.B
-- floor => round after 1st multiplications.
--
-- Revision 1.6  2003/08/29 16:05:35  Dr.B
-- New version "bit-true" with matlab.
--
-- Revision 1.5  2003/04/30 09:02:41  Dr.A
-- Added data_valid.
--
-- Revision 1.4  2003/04/24 15:47:59  Dr.A
-- Removed one delay on I data.
--
-- Revision 1.3  2003/04/24 14:29:36  Dr.A
-- Corrected constant size to use with smaller input data generics..
--
-- Revision 1.2  2003/04/24 12:00:16  Dr.A
-- New algorithm.
--
-- Revision 1.1  2003/03/27 14:09:26  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL; 
 
--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--library iq_compensation_rtl;
library work;
--use iq_compensation_rtl.iq_compensation_pkg.all;
use work.iq_compensation_pkg.all;

--library eucl_divider_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity iq_compensation is
  generic ( 
    iq_i_width_g     : integer := 9; -- IQ inputs width.
    iq_o_width_g     : integer := 9; -- IQ outputs width.
    phase_width_g    : integer := 6; -- Phase parameter width.
    ampl_width_g     : integer := 9; -- Amplitude parameter width.
    toggle_in_g      : integer := 0; -- when 1 the data_valid_i toggles
    toggle_out_g     : integer := 0; -- when 1 the data_valid_o toggles
    --
--    use_sync_reset_g : integer := 1  -- when 1 sync_reset_n input is used
    use_sync_reset_g : integer := 1  -- when 1 sync_reset_n input is used
  );                                 -- else the reset_n input must be separately
  port (                             -- controlled by the reset controller
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk          : in  std_logic; -- Module clock. 60 MHz
    reset_n      : in  std_logic; -- Asynchronous reset.
    sync_reset_n : in  std_logic; -- Block enable.
    --------------------------------------
    -- Controls
    --------------------------------------
    -- Phase compensation control.
    phase_i      : in  std_logic_vector(phase_width_g-1 downto 0);
    -- Amplitude compensation control.
    ampl_i       : in  std_logic_vector(ampl_width_g-1 downto 0);
    data_valid_i : in  std_logic; -- high when a new data is available
    --
    data_valid_o : out std_logic; -- high/toggle when a new data is available
    --------------------------------------
    -- Data
    --------------------------------------
    i_in         : in  std_logic_vector(iq_i_width_g-1 downto 0);
    q_in         : in  std_logic_vector(iq_i_width_g-1 downto 0);
    --
    i_out        : out std_logic_vector(iq_o_width_g-1 downto 0);
    q_out        : out std_logic_vector(iq_o_width_g-1 downto 0)
    
  );

end iq_compensation;
