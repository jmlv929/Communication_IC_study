
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : All
--    ,' GoodLuck ,'      RCSfile: serial_parity_gen.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description :  Generate a parity bit from seria data input
-- a (+) b (+) c (+) .... (+) p = reset_val_g
--
-- Note that : a (+) b (+) p = 1  <=> a (+) b (+) 1 = p
-- This can also be used as parity checker = input  a (+) b (+) p (with
-- reset_val_g = 0) and verify that the result is 1.
-- 
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/serial_parity/vhdl/rtl/serial_parity_gen.vhd,v  
--  Log: serial_parity_gen.vhd,v  
-- Revision 1.3  2003/11/21 09:42:53  Dr.B
-- change order in the process.
--
-- Revision 1.2  2003/10/17 15:17:21  Dr.B
-- change on reset_val to not have warnings on synthesis.
--
-- Revision 1.1  2003/07/21 09:07:38  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity serial_parity_gen is
  generic (
    reset_val_g : integer := 1);
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk             : in  std_logic;
    reset_n         : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    data_i          : in  std_logic;    -- data input
    init_i          : in  std_logic;    -- reinit register
    data_valid_i    : in  std_logic;    -- high when 1 data is available
    --
    parity_bit_o    : out std_logic;  -- parity bit available when  the last data is entered
    parity_bit_ff_o : out std_logic  -- parity bit available after the last data entered
    
  );

end serial_parity_gen;
