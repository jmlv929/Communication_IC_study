
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: iq_calibration_gen.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Signal generator for the IQ/DC calibration.
--              Generates a complex-valued sinusoid
--              with programmable gain and frequency.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/iq_calibration_gen/vhdl/rtl/iq_calibration_gen.vhd,v  
--  Log: iq_calibration_gen.vhd,v  
-- Revision 1.2  2003/04/07 13:24:17  Dr.A
-- Reduced data size.
--
-- Revision 1.1  2003/03/27 13:03:00  Dr.A
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
 
--library sine_table_rom_rtl;
library work;
--use sine_table_rom_rtl.sine_table_rom_pkg.all;
use work.sine_table_rom_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity iq_calibration_gen is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------

    clk          : in  std_logic; -- Module clock.
    reset_n      : in  std_logic; -- Asynchronous reset.
    --------------------------------------
    -- Controls
    --------------------------------------
    calfrq0_i    : in  std_logic_vector(22 downto 0); -- Phase increment.
    calgain_i    : in  std_logic_vector( 2 downto 0); -- Gain parameter.
    data_ready_i : in  std_logic; -- Next block is ready to accept data.
    --------------------------------------
    -- Data
    --------------------------------------
    sig_im_o     : out std_logic_vector(7 downto 0);
    sig_re_o     : out std_logic_vector(7 downto 0) 
  );

end iq_calibration_gen;
