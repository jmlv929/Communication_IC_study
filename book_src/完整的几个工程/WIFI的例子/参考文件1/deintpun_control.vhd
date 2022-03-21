
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: deintpun_control.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.5  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Deinterleaver & depuncturer control block.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/deintpun/vhdl/rtl/deintpun_control.vhd,v  
--  Log: deintpun_control.vhd,v  
-- Revision 1.5  2005/02/21 13:04:25  Dr.C
-- #BugId:1083#
-- Defined range to bits_per_symbol signal.
--
-- Revision 1.4  2004/07/22 13:31:31  Dr.C
-- Added FFs on outputs.
--
-- Revision 1.3  2003/05/16 16:34:18  Dr.J
-- Changed the type of field_length_i
--
-- Revision 1.2  2003/03/28 15:33:37  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/18 14:29:07  Dr.C
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
use ieee.std_logic_unsigned.all;

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
entity deintpun_control is
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
    enable_i       : in  std_logic;  -- Enable signal
    data_valid_i   : in  std_logic;  -- Data Valid signal for input
    data_valid_o   : out std_logic;  -- Data Valid signal for following block

    data_ready_o   : out std_logic;  -- reading phase ready
    
    start_field_i  : in  std_logic;  -- start either signal or data field 
    field_length_i : in  std_logic_vector (15 downto 0);
    qam_mode_i     : in  std_logic_vector (1 downto 0);
    pun_mode_i     : in  std_logic_vector (1 downto 0);

    enable_read_o  : out std_logic;  -- enable softbit output
    enable_write_o : out std_logic;  -- write softbits to deint registers

    write_addr_o   : out CARR_T;
    read_carr_x_o  : out CARR_T;
    read_carr_y_o  : out CARR_T;
    read_soft_x_o  : out SOFT_T;
    read_soft_y_o  : out SOFT_T;
    read_punc_x_o  : out PUNC_T;     -- give out dontcare on soft_x_o
    read_punc_y_o  : out PUNC_T      -- give out dontcare on soft_y_o
  );

end deintpun_control;
