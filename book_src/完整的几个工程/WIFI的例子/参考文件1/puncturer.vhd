
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: puncturer.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/puncturer/vhdl/rtl/puncturer.vhd,v  
--  Log: puncturer.vhd,v  
-- Revision 1.1  2003/03/13 15:06:53  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 

--library puncturer_rtl;
library work;
--use puncturer_rtl.puncturer_pkg.all;
use work.puncturer_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity puncturer is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk           : in  std_logic;
    reset_n       : in  std_logic;
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i      : in  std_logic; -- TX global enable.
    data_valid_i  : in  std_logic; -- from previous module
    data_ready_i  : in  std_logic; -- from following module
    marker_i      : in  std_logic; -- marks start of burst & signal field
    coding_rate_i : in  std_logic_vector(1 downto 0);
    --
    data_valid_o  : out std_logic; -- to following module
    data_ready_o  : out std_logic; -- to previous module
    marker_o      : out std_logic; -- marks start of burst
    --------------------------------------
    -- Data
    --------------------------------------
    x_i           : in  std_logic;  -- x data from encoder. 
    y_i           : in  std_logic;  -- y data from encoder.
    --
    x_o           : out std_logic;  -- x punctured data.
    y_o           : out std_logic   -- y punctured data.

  );

end puncturer;
