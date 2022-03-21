
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: core_filter.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.13   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Core front-end filter for tx_rx_filter block
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/tx_rx_filter/vhdl/rtl/core_filter.vhd,v  
--  Log: core_filter.vhd,v  
-- Revision 1.13  2005/01/18 13:13:21  Dr.C
-- #BugId:960#
-- Added dc_pre_estim_4_agc outputs and reduce dc_pre_estim to 11-bit.
--
-- Revision 1.12  2004/12/08 16:05:56  Dr.C
-- #BugId:888#
-- Change counter constant value for DC offset pre-estimation.
--
-- Revision 1.11  2004/10/27 14:15:37  Dr.C
-- #BugId:799#
-- Added dc pre-estimation calculation.
--
-- Revision 1.10  2004/05/13 14:48:06  Dr.C
-- Added use_sync_reset_g generic.
--
-- Revision 1.9  2004/04/07 13:43:32  Dr.C
-- Change architecture for reduce gate count.
--
-- Revision 1.8  2003/11/29 11:28:46  Dr.C
-- Changed architecture.
--
-- Revision 1.7  2003/08/29 16:13:00  Dr.C
-- Added clear_buffer input.
--
-- Revision 1.6  2003/07/02 13:30:35  Dr.C
-- Changed structure.
--
-- Revision 1.5  2003/06/11 09:26:36  Dr.C
-- Removed last version.
--
-- Revision 1.4  2003/06/04 15:04:04  Dr.C
-- Changed coefs & structure.
--
-- Revision 1.3  2003/04/02 08:18:16  Dr.C
-- Debugged saturation constants.
--
-- Revision 1.2  2003/04/01 14:40:09  Dr.C
-- Debugged buf_mul assignment.
--
-- Revision 1.1  2003/03/17 15:33:27  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all; 

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--library target_config_pkg;
library work;
--use target_config_pkg.target_config_pkg.all;
use work.target_config_pkg.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity core_filter is
  generic (
    size_in_g        : integer := 10; -- Size of Core filter input
    size_out_g       : integer := 15; -- Size of Core filter output
    --
--    use_sync_reset_g : integer := 1   -- when 1 clear_buffer input is used
    use_sync_reset_g : integer := 1   -- when 1 clear_buffer input is used
    );                                -- else the reset_n input must be separately
  port (                              -- controlled by the reset controller
    ------------------------------------------------
    -- Clock and reset
    ------------------------------------------------
    clk          : in std_logic;       -- 60 Mhz
    reset_n      : in std_logic;
        
    ------------------------------------------------
    -- Clear buffer during transition Tx/Rx or Rx/Tx
    ------------------------------------------------
    clear_buffer : in std_logic;
    
    ------------------------------------------------
    -- Filter buffer input
    ------------------------------------------------
    fil_buf_i    : in std_logic_vector(size_in_g-1 downto 0);

    ------------------------------------------------
    -- Addition stage output with saturation
    ------------------------------------------------
    add_stage_o  : out std_logic_vector(size_out_g-1 downto 0);
    
    ------------------------------------------------
    -- DC offset pre-estimation
    ------------------------------------------------
    sel_dc_mode        : in std_logic;
    dc_pre_estim_valid : in std_logic;
    tx_active          : in std_logic; -- stop dc pre-estimation when tx active
    --
    dc_pre_estim       : out std_logic_vector(10 downto 0);
    dc_pre_estim_4_agc : out std_logic_vector(10 downto 0)
    );

end core_filter;
