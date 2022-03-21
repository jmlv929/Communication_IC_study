
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: deintpun.vhd,v  
--   '-----------'     Only for Study  
--
--  Revision: 1.3  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Deinterleaver & depuncturer block.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/deintpun/vhdl/rtl/deintpun.vhd,v  
--  Log: deintpun.vhd,v  
-- Revision 1.3  2003/05/16 16:34:01  Dr.J
-- Changed the type of field_length_i
--
-- Revision 1.2  2003/03/28 15:32:57  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/18 14:29:03  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library deintpun_rtl;
library work;
--use deintpun_rtl.deintpun_pkg.all; 
use work.deintpun_pkg.all; 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity deintpun is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n        : in  std_logic;  -- Async Reset
    clk            : in  std_logic;  -- Clock
    sync_reset_n   : in  std_logic;  -- Software reset

    --------------------------------------
    -- Symbol Strobe
    --------------------------------------
    enable_i       : in  std_logic;   -- Enable signal
    data_valid_i   : in  std_logic;   -- Data Valid signal for input
    start_field_i  : in  std_logic;    -- start signal or data field
    --
    data_valid_o   : out std_logic;   -- Data Valid signal for following block
    data_ready_o   : out std_logic;   -- ready to take values from input
    
    --------------------------------------
    -- Datapath interface
    --------------------------------------
    field_length_i : in std_logic_vector (15 downto 0);
    qam_mode_i     : in std_logic_vector (1 downto 0);
    pun_mode_i     : in std_logic_vector (1 downto 0);
    soft_x0_i      : in std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_x1_i      : in std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_x2_i      : in std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y0_i      : in std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y1_i      : in std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y2_i      : in std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
                                       -- Softbits from equalizer_softbit
    --
    soft_x_o       : out std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y_o       : out std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0)
                                           -- Softbits to Viterbi
    );

end deintpun;
