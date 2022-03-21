
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: wie_mem.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Wiener coeffs table.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/wie_mem/vhdl/rtl/wie_mem.vhd,v  
--  Log: wie_mem.vhd,v  
-- Revision 1.6  2005/03/09 12:10:57  Dr.C
-- #BugId:1123#
-- Reset control signals.
--
-- Revision 1.5  2003/05/12 13:47:21  Dr.F
-- delayed data_valid_o.
--
-- Revision 1.4  2003/04/04 07:46:48  Dr.F
-- use pilot_ready to compute data_valid_o.
--
-- Revision 1.3  2003/03/31 06:37:49  Dr.F
-- pilot_ready appears only once per burst.
--
-- Revision 1.2  2003/03/28 15:43:49  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/25 13:02:12  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity wie_mem is

  port (
    clk                : in  std_logic;  -- ofdm clock (80 MHz)
    reset_n            : in  std_logic;  -- asynchronous negative reset
    sync_reset_n       : in  std_logic;  -- synchronous negative reset
    i_i                : in  std_logic_vector(FFT_WIDTH_CT-1 downto 0);  -- I input data
    q_i                : in  std_logic_vector(FFT_WIDTH_CT-1 downto 0);  -- Q input data
    data_valid_i       : in  std_logic;  -- '1': input data valid
    data_ready_i       : in  std_logic;  -- '0': do not output more data
    start_of_burst_i   : in  std_logic;  -- '1': the next valid data input 
                                         -- belongs to the next burst
    start_of_symbol_i  : in  std_logic;  -- '1': the next valid data input 
                                         -- belongs to the next symbol
    --
    i_o                : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);  -- I output data
    q_o                : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);  -- Q output data
    data_ready_o       : out std_logic;  -- '0': do not input more data
    data_valid_o       : out std_logic;  -- '1': output data valid
    start_of_burst_o   : out std_logic;  -- '1': the next valid data output 
                                         -- belongs to the next burst 
    start_of_symbol_o  : out std_logic;  -- '1': the next valid data output 
                                         -- belongs to the next symbol
    -- pilots coeffs
    pilot_ready_o      : out std_logic;
    eq_p21_i_o         : out std_logic_vector(11 downto 0);
    eq_p21_q_o         : out std_logic_vector(11 downto 0);
    eq_p7_i_o          : out std_logic_vector(11 downto 0);
    eq_p7_q_o          : out std_logic_vector(11 downto 0);
    eq_m21_i_o         : out std_logic_vector(11 downto 0);
    eq_m21_q_o         : out std_logic_vector(11 downto 0);
    eq_m7_i_o          : out std_logic_vector(11 downto 0);
    eq_m7_q_o          : out std_logic_vector(11 downto 0)
  );

end wie_mem;
