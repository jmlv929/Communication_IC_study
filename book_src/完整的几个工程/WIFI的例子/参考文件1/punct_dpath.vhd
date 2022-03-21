
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: punct_dpath.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Datapath of the puncturer.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/puncturer/vhdl/rtl/punct_dpath.vhd,v  
--  Log: punct_dpath.vhd,v  
-- Revision 1.1  2003/03/13 15:06:51  Dr.A
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
entity punct_dpath is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk            : in  std_logic;
    reset_n        : in  std_logic;
    --------------------------------------
    -- Controls
    --------------------------------------
    data_valid_i   : in  std_logic; -- Enable for x_i and y_i.
    dpath_enable_i : in  std_logic; -- Enable from the control path.
    mux_sel_i      : in  std_logic_vector(1 downto 0); -- Data mux command.
    --------------------------------------
    -- Data
    --------------------------------------
    x_i            : in  std_logic; -- x data from encoder.
    y_i            : in  std_logic; -- y data from encoder.
    --
    x_o            : out std_logic; -- x punctured data.
    y_o            : out std_logic  -- y punctured data.
  );

end punct_dpath;
