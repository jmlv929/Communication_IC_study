
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD MODEM802.11B
--    ,' GoodLuck ,'      RCSfile: iq_mismatch.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.13   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : IQ Mismatch Compensation block.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/iq_mismatch/vhdl/rtl/iq_mismatch.vhd,v  
--  Log: iq_mismatch.vhd,v  
-- Revision 1.13  2005/01/24 13:49:07  arisse
-- #BugId:624#
-- Added iq_gain_sat status signal for the registers.
--
-- Revision 1.12  2004/08/24 13:44:59  arisse
-- Added globals for testbench.
--
-- Revision 1.11  2004/07/15 13:15:36  arisse
-- Between the accumulation of the IQ estimation and the multiplication of the IQ compensation the data were not used at the same time.
--
-- Revision 1.10  2004/04/29 12:04:07  arisse
-- Added reset of rescaling between two packets.
--
-- Revision 1.9  2004/04/06 07:55:30  Dr.B
-- Changed OUTPUT generation: when enabled (iq_compensation_enable = '1'),
-- iq_gain OUTPUT switch from default value to new value but when new value is ready.
--
-- Revision 1.8  2004/03/03 09:02:52  Dr.B
-- Modification & debug during bitrufication, main chages:
-- - division is done just once/1 us.
-- - mulptiplication is replaced by combinational inference.
-- - overflow detection added on abs.
--
-- Revision 1.7  2003/11/25 09:34:29  arisse
-- Added test on acc_i_p0(17) for division  by 2 of accumulator.
--
-- Revision 1.6  2003/03/10 09:17:26  Dr.J
-- Removed the integer
--
-- Revision 1.5  2002/11/13 13:33:46  Dr.J
-- Debugged enable
--
-- Revision 1.4  2002/11/08 12:00:36  Dr.J
-- Reset dataout_q
--
-- Revision 1.3  2002/11/06 18:11:24  Dr.J
-- Debugged when iq_estimation_enable = '0'
--
-- Revision 1.2  2002/10/21 14:02:43  Dr.J
-- Added commentary
--
-- Revision 1.1  2002/10/18 14:26:17  Dr.J
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.std_logic_unsigned.ALL; 
use IEEE.std_logic_arith.ALL; 
 
--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--library iq_mismatch_rtl;
library work;
--use iq_mismatch_rtl.iq_mismatch_pkg.all;
use work.iq_mismatch_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity iq_mismatch is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                    : in  std_logic; -- clock
    reset_n                : in  std_logic; -- reset when low
    iq_estimation_enable   : in  std_logic; -- enable the estimation when high
    iq_compensation_enable : in  std_logic; -- enable the I/Q Mismatch when high
    --------------------------------------
    -- Datas signals
    --------------------------------------
    data_in_i              : in  std_logic_vector(7 downto 0); -- input data I
    data_in_q              : in  std_logic_vector(7 downto 0); -- input data Q
    iq_gain_sat_stat       : out std_logic_vector(6 downto 0);
    data_out_i             : out std_logic_vector(7 downto 0); -- output data I
    data_out_q             : out std_logic_vector(7 downto 0)  -- output data Q
    
  );

end iq_mismatch;
