
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: delay_line18.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Delay line with 18 parallel outputs.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/equalizer/vhdl/rtl/delay_line18.vhd,v  
--  Log: delay_line18.vhd,v  
-- Revision 1.1  2002/05/07 16:59:49  Dr.A
-- Initial revision
--
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
entity delay_line18 is
  generic (
    dsize_g : integer := 6 -- Data size
  );
  port (
    -- Clock and reset.
    reset_n       : in  std_logic;
    clk           : in  std_logic;
    -- 
    data_in       : in  std_logic_vector(dsize_g-1 downto 0); -- Data to delay.
    shift         : in  std_logic;                            -- Shift signal.
    -- Delayed data parallel outputs.
    data_ff0      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff1      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff2      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff3      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff4      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff5      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff6      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff7      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff8      : out std_logic_vector(dsize_g-1 downto 0);
    data_ff9      : out std_logic_vector(dsize_g-1 downto 0);
    
    data_ff10     : out std_logic_vector(dsize_g-1 downto 0);
    data_ff11     : out std_logic_vector(dsize_g-1 downto 0);
    data_ff12     : out std_logic_vector(dsize_g-1 downto 0);
    data_ff13     : out std_logic_vector(dsize_g-1 downto 0);
    data_ff14     : out std_logic_vector(dsize_g-1 downto 0);
    data_ff15     : out std_logic_vector(dsize_g-1 downto 0);
    data_ff16     : out std_logic_vector(dsize_g-1 downto 0);
    data_ff17     : out std_logic_vector(dsize_g-1 downto 0)
  );

end delay_line18;
