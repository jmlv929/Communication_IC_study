
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: rc4_sboxinit.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block initialises the S-Box in the Internal SRAM with
--                the values 0 to 255.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/rc4_crc/vhdl/rtl/rc4_sboxinit.vhd,v  
--  Log: rc4_sboxinit.vhd,v  
-- Revision 1.1  2002/10/15 13:18:54  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL; 

entity rc4_sboxinit is
  generic (
    addrmax_g  : integer := 8           -- SRAM Address bus width.
  );
  port (
    -- Clocks and resets
    clk         : in  std_logic;        -- Clock.
    reset_n     : in  std_logic;        -- Reset. Inverted logic.
    -- Selector
    start_sbinit: in  std_logic;        -- Starts s-box initialisation.
    sbinit_done : out std_logic;        -- S-box initialisation done.
    -- SRAM:
    sr_wdata    : out std_logic_vector(7 downto 0);-- SRAM write data.
    sr_address  : out std_logic_vector(addrmax_g-1 downto 0);-- SRAM address.
    sr_wen      : out std_logic;        -- SRAM write enable. Inverted logic.
    sr_cen      : out std_logic         -- SRAM Chip Enable. Inverted logic.
  );
end rc4_sboxinit;
