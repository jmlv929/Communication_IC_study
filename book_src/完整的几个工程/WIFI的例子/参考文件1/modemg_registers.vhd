
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: modemg_registers.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.21   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Registers for the 802.11g Wild Modem.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11g/modemg_registers/vhdl/rtl/modemg_registers.vhd,v  
--  Log: modemg_registers.vhd,v  
-- Revision 1.21  2005/12/14 13:18:01  pbressy
-- #BugId:1481#
-- corrected sensitivity list
--
-- Revision 1.20  2005/04/11 16:11:29  Dr.J
-- #BugId:983#
-- Updated the version
--
-- Revision 1.19  2005/03/25 15:18:37  Dr.J
-- #BugId:720#
-- Updated the version according to the specification number.
--
-- Revision 1.18  2005/03/24 10:19:18  Dr.J
-- #BugId:720#
-- Updated the register's values
--
-- Revision 1.17  2005/03/23 08:30:05  Dr.J
-- #BugId:720#
-- Added Energy Detect register
--
-- Revision 1.16  2005/01/20 15:30:14  Dr.J
-- #BugId:727#
-- Updated the default values of the registers
--
-- Revision 1.15  2005/01/17 18:54:45  Dr.J
-- #BugId:837#
-- Added the missing parenthesis.
--
-- Revision 1.14  2005/01/17 09:10:31  Dr.J
-- #BugId:837#
-- Set the default value of int_addestimdura and int_addestimdurb
--
-- Revision 1.13  2005/01/12 14:35:46  Dr.J
-- #BugId:727#
-- Updated the sensitivity list
--
-- Revision 1.12  2004/12/20 13:35:49  Dr.J
-- #BugId:606#
-- Set the rampdown value to 2 by default
--
-- Revision 1.11  2004/12/14 15:56:50  Dr.J
-- #BugId:727,837#
-- Added MDMg11H & MDMgADDESTIMDUR registers
--
-- Revision 1.10  2004/09/01 10:08:40  sbizet
-- Changed initialization value of signal and cs
-- waiting time
--
-- Revision 1.9  2004/06/04 13:15:25  Dr.C
-- Added iq swap for tx and rx.
--
-- Revision 1.8  2004/04/26 08:19:07  Dr.C
-- Added register on prdata busses.
--
-- Revision 1.7  2004/01/12 13:52:30  Dr.J
-- Added ,
--
-- Revision 1.6  2004/01/12 13:43:32  Dr.J
-- Debugged the uncomplete sensitive list
--
-- Revision 1.5  2003/12/23 14:48:22  Dr.C
-- Changed deldc2 init value to 19.
--
-- Revision 1.4  2003/12/19 13:45:10  Dr.B
-- by default, agc is disabled.
--
-- Revision 1.3  2003/11/20 16:33:38  Dr.J
-- Updated for the agc_hissbb
--
-- Revision 1.2  2003/11/14 15:51:06  Dr.C
-- Updated according to spec 0.07.
--
-- Revision 1.1  2003/05/12 15:32:39  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library modemg_registers_rtl; 
library work;
--use modemg_registers_rtl.modemg_registers_pkg.all;
use work.modemg_registers_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity modemg_registers is
  port (
    --------------------------------------------
    -- clock and reset
    --------------------------------------------
    reset_n         : in  std_logic; -- Reset.
    pclk            : in  std_logic; -- APB clock.

    --------------------------------------------
    -- APB slave
    --------------------------------------------
    psel            : in  std_logic; -- Device select.
    penable         : in  std_logic; -- Defines the enable cycle.
    paddr           : in  std_logic_vector( 5 downto 0); -- Address.
    pwrite          : in  std_logic; -- Write signal.
    pwdata          : in  std_logic_vector(31 downto 0); -- Write data.
    --
    prdata          : out std_logic_vector(31 downto 0); -- Read data.
  
    --------------------------------------------
    -- Modem Registers Inputs
    --------------------------------------------
    -- MDMg11hCNTL register.
    ofdmcoex         : in  std_logic_vector(7 downto 0); -- Current value of the 
                                                         -- OFDM Preamble Existence counter   
    -- MDMgAGCCCA register.
    edtransmode_reset : in std_logic; -- Reset the edtransmode register     
    --------------------------------------------
    -- Modem Registers Outputs
    --------------------------------------------
    reg_modeabg      : out std_logic_vector(1 downto 0);  -- Operating mode.
    reg_tx_iqswap    : out std_logic;                     -- Swap I/Q in Tx.
    reg_rx_iqswap    : out std_logic;                     -- Swap I/Q in Rx.
    -- MDMgAGCCCA register.
    reg_deldc2       : out std_logic_vector(4 downto 0);   -- DC waiting period.
    reg_longslot     : out std_logic;
    reg_cs_max       : out std_logic_vector(3 downto 0);
    reg_sig_max      : out std_logic_vector(3 downto 0);
    reg_agc_disb     : out std_logic;
    reg_modeant      : out std_logic;
    reg_edtransmode  : out std_logic; -- Energy Detect Transitional Mode
    reg_edmode       : out std_logic; -- Energy Detect Mode
    -- MDMgADDESTMDUR register.
    reg_addestimdura : out std_logic_vector(3 downto 0); -- additional time duration 11a
    reg_addestimdurb : out std_logic_vector(3 downto 0); -- additional time duration 11b
    reg_rampdown     : out std_logic_vector(2 downto 0); -- ramp-down time duration
    -- MDMg11hCNTL register.
    reg_rstoecnt     : out std_logic                     -- Reset OFDM Preamble Existence cnounter

    );

end modemg_registers;
