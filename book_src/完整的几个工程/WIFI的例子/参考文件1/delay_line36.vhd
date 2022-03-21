
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: delay_line36.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Delay line with 36 parallel outputs.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/equalizer/vhdl/rtl/delay_line36.vhd,v  
--  Log: delay_line36.vhd,v  
-- Revision 1.1  2002/05/07 17:00:14  Dr.A
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
entity delay_line36 is
  generic (
    dsize_g : integer := 6
  );
  port (
    -- Clock and reset
    reset_n       : in  std_logic;
    clk           : in  std_logic;
    -- 
    data_in       : in  std_logic_vector(dsize_g-1 downto 0); -- Data to delay.
    shift         : in  std_logic;                            -- Shift signal.
    -- Delayed data parallel outputs.
    data_ff0_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff1_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff2_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff3_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff4_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff5_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff6_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff7_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff8_dly  : out std_logic_vector(dsize_g-1 downto 0);
    data_ff9_dly  : out std_logic_vector(dsize_g-1 downto 0);
    
    data_ff10_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff11_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff12_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff13_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff14_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff15_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff16_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff17_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff18_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff19_dly : out std_logic_vector(dsize_g-1 downto 0);
    
    data_ff20_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff21_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff22_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff23_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff24_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff25_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff26_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff27_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff28_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff29_dly : out std_logic_vector(dsize_g-1 downto 0);
    
    data_ff30_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff31_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff32_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff33_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff34_dly : out std_logic_vector(dsize_g-1 downto 0);
    data_ff35_dly : out std_logic_vector(dsize_g-1 downto 0)
  );

end delay_line36;
