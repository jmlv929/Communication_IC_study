
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: shift_param_gen.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Shift Parameter generation - For Fine Freq Estimation Scaling
-- Memorize the maximum absolute value of i_i and q_i. And find how many shift
-- will be performed inside the err_phasor of the fine_freq_estim.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/init_sync/vhdl/rtl/shift_param_gen.vhd,v  
--  Log: shift_param_gen.vhd,v  
-- Revision 1.1  2003/04/04 16:29:46  Dr.B
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
entity shift_param_gen is
  generic (
    data_size_g : integer := 11);
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                 : in std_logic;
    reset_n             : in std_logic;

    --------------------------------------
    -- Signals
    --------------------------------------
    init_i              : in std_logic;
    cp2_detected_i      : in std_logic;
    -- Data Input
    i_i                 : in std_logic_vector (10 downto 0);
    q_i                 : in std_logic_vector (10 downto 0);
    data_valid_i        : in std_logic;
    -- Shift Parameter : nb of LSB to remove
    shift_param_o       : out std_logic_vector(2 downto 0)
    
    
  );

end shift_param_gen;
