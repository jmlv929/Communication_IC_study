
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: deintpun_datapath.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.3  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Deinterleaver & depuncturer datapath block.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/deintpun/vhdl/rtl/deintpun_datapath.vhd,v  
--  Log: deintpun_datapath.vhd,v  
-- Revision 1.3  2004/07/22 13:31:33  Dr.C
-- Added FFs on outputs.
--
-- Revision 1.2  2003/03/28 15:33:41  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/18 14:29:10  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

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
entity deintpun_datapath is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n        : in  std_logic;  -- Async Reset
    clk            : in  std_logic;  -- Clock

    --------------------------------------
    -- Interface Synchronization
    --------------------------------------
    enable_write_i : in  std_logic;  -- Enable signal for write phase
    enable_read_i  : in  std_logic;  -- Enable signal for read phase

    --------------------------------------
    -- Datapath interface
    --------------------------------------
    soft_x0_i      : in  std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_x1_i      : in  std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_x2_i      : in  std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y0_i      : in  std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y1_i      : in  std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y2_i      : in  std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
                                       -- Softbits from equalizer_softbit

    soft_x_o       : out std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y_o       : out std_logic_vector (SOFTBIT_WIDTH_CT-1 downto 0);
                                       -- Softbits to Viterbi

    write_addr_i   : in  CARR_T;   

    read_carr_x_i  : in  CARR_T;
    read_carr_y_i  : in  CARR_T;
    read_soft_x_i  : in  SOFT_T;
    read_soft_y_i  : in  SOFT_T;
    read_punc_x_i  : in  PUNC_T;   -- give out dontcare on soft_x_o
    read_punc_y_i  : in  PUNC_T    -- give out dontcare on soft_y_o
  );

end deintpun_datapath;
