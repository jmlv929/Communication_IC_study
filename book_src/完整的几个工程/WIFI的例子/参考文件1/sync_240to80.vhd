
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : HiSS
--    ,' GoodLuck ,'      RCSfile: sync_240to80.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description :  Synchronization from 240 to 80 MHz
-- of control signals and data signals. 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/sync_240to80.vhd,v  
--  Log: sync_240to80.vhd,v  
-- Revision 1.4  2004/07/16 07:36:34  Dr.B
-- add cca_add_info feature
--
-- Revision 1.3  2004/03/29 13:02:05  Dr.B
-- sample on falling_edge clk data when clk44_possible_g = 1
--
-- Revision 1.2  2003/11/26 14:00:33  Dr.B
-- clk_switch_req is added.
--
-- Revision 1.1  2003/11/20 11:20:19  Dr.B
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
entity sync_240to80 is
  generic (
    clk44_possible_g : integer := 0); -- when 1 - the radioctrl can work with a
                                      -- 44 MHz clock instead of the normal 80 MHz.
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    pclk                      : in  std_logic;  -- 240 MHz clock
    reset_n                   : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    -- Registers from deserializer : CCA / RDATA or RX data
    memo_i_reg_on240_i         : in  std_logic_vector(11 downto 0);
    memo_q_reg_on240_i         : in  std_logic_vector(11 downto 0);
    cca_tog_on240_i            : in  std_logic;
    acc_end_tog_on240_i        : in  std_logic;
    rx_val_tog_on240_i         : in  std_logic;
    -- Controls Signals
    next_data_req_tog_on240_i  : in  std_logic;
    switch_ant_tog_on240_i     : in  std_logic;
    clk_switch_req_tog_on240_i : in  std_logic;
    clk_switched_tog_on240_i   : in  std_logic;
    parity_err_tog_on240_i     : in  std_logic;
    parity_err_cca_tog_on240_i : in  std_logic;
    prot_err_on240_i           : in  std_logic; -- long pulse (gamma cycles)
    -- *** Outputs ****
    -- Data out
    rx_i_on80_o                : out std_logic_vector(11 downto 0);
    rx_q_on80_o                : out std_logic_vector(11 downto 0);
    rx_val_tog_on80_o          : out std_logic;
    -- CCA info
    cca_info_on80_o            : out std_logic_vector( 5 downto 0);
    cca_add_info_on80_o        : out std_logic_vector(15 downto 0);
    cca_on80_o                 : out std_logic;
    -- RDDATA
    prdata_on80_o              : out std_logic_vector(15 downto 0);
    acc_end_on80_o             : out std_logic;
    -- Controls Signals
    next_data_req_tog_on80_o   : out std_logic;
    switch_ant_tog_on80_o      : out std_logic;
    clk_switch_req_on80_o      : out std_logic;
    clk_switched_on80_o        : out std_logic;  -- pulse when clk switched
    parity_err_tog_on80_o      : out std_logic;
    parity_err_cca_tog_on80_o  : out std_logic;
    prot_err_on80_o            : out std_logic  -- pulse
      
  );

end sync_240to80;
