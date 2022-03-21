
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: diff_decoder.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block decodes the input stream. current_phi (decod_in)
--               is the current input. last_phi is the previous input. delta_phi
--               is the output corresponding to the following equation :
--                 current_phi = last_phi . delta_hpi
--               where (.) is the angle addition operator.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/diff_decoder/vhdl/rtl/diff_decoder.vhd,v  
--  Log: diff_decoder.vhd,v  
-- Revision 1.4  2002/09/17 07:28:28  Dr.B
-- pi addition in cck mode.
--
-- Revision 1.3  2002/07/03 13:22:36  Dr.B
-- output is delayed ( 1 period).
--
-- Revision 1.2  2002/06/11 13:31:24  Dr.F
-- some ports names changed.
--
-- Revision 1.1  2002/03/14 07:59:53  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

--library mapping_rtl;
library work;
--use mapping_rtl.functions_pkg.all;
use work.functions_pkg.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity diff_decoder is
  port (
    -- clock and reset
    clk     : in std_logic;
    reset_n : in std_logic;

    -- inputs
    diff_decod_activate  : in std_logic;  -- activate the diff_decoder block
    diff_decod_first_val : in std_logic;  -- initialize the diff_decoder block when
    -- the first symbol is received
    -- (diff_decod_activate should be set).
    diff_cck_mode        : in std_logic; -- indicate a CCK mode (pi to add)
    diff_decod_in        : in std_logic_vector (1 downto 0);  -- input
    shift_diff_decod     : in std_logic;  -- shift diff_decoder

    -- outputs
    delta_phi : out std_logic_vector (1 downto 0)  -- delta_phi output


    );

end diff_decoder;
